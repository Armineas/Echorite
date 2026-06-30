extends Node
## DavenStealthSystem — Autoload (nom : "Stealth")
## Logique de furtivité du mode Daven. Cônes de détection, états d'alerte, bruit.
##
## Ce script gère la logique pure — les données de détection.
## Le rendu visuel (dessiner les cônes, la jauge d'alerte) est dans DavenStealth.tscn.
##
## Modèle de détection :
##   Chaque ennemi a un cône de vision (angle + distance).
##   Si Daven est dans le cône et pas en couverture → détection progressive.
##   Détection = 0..100. À 100 → alerte immédiate.
##   Le bruit (actions de Daven) peut aussi déclencher la détection.

signal detection_increased(enemy_id: String, old_value: float, new_value: float)
signal detected_by(enemy_id: String)
signal noise_generated(source: String, radius: float)


# ─────────────────────────────────────────────────────────────────────────────
# DONNÉES DE DÉTECTION
# ─────────────────────────────────────────────────────────────────────────────

## Types d'ennemis et leurs paramètres de détection.
## distance_max en unités tile, angle en degrés, detection_rate = points/seconde dans le cône.
const ENEMY_TYPES: Dictionary = {
	"guard_patrol": {
		"vision_angle":    90.0,
		"vision_distance": 6.0,
		"detection_rate":  15.0,   # points/s dans le cône
		"peripheral_rate": 5.0,    # points/s en périphérie (jusqu'à 140°)
		"noise_range":     3.0,    # entend les bruits dans ce rayon
		"forget_rate":     8.0,    # oubli/s si Daven sort du cône
	},
	"guard_stationary": {
		"vision_angle":    120.0,
		"vision_distance": 8.0,
		"detection_rate":  20.0,
		"peripheral_rate": 6.0,
		"noise_range":     4.0,
		"forget_rate":     5.0,
	},
	"agent_vareth": {
		"vision_angle":    60.0,
		"vision_distance": 10.0,
		"detection_rate":  30.0,   # agents formés = réagissent plus vite
		"peripheral_rate": 10.0,
		"noise_range":     5.0,
		"forget_rate":     3.0,
	},
	"civil_suspicious": {
		"vision_angle":    180.0,
		"vision_distance": 4.0,
		"detection_rate":  8.0,
		"peripheral_rate": 3.0,
		"noise_range":     2.0,
		"forget_rate":     15.0,  # oublie vite
	},
}

## Niveaux de bruit générés par les actions de Daven.
const NOISE_LEVELS: Dictionary = {
	"walk":          0.0,   # aucun bruit
	"run":           2.5,   # bruit audible nearby
	"crouch_walk":   0.5,   # presque silencieux
	"door_open":     1.5,
	"door_break":    4.0,
	"attack":        5.0,
	"fall":          3.5,
	"pick_lock":     0.8,
	"distraction":   4.0,   # Daven crée volontairement un bruit ailleurs
}

## État de détection par ennemi (id_ennemi → 0..100)
var _detection_values: Dictionary = {}

## Si true, Daven est en couverture physique (derrière un objet) — réduit detection_rate de 60%
var _in_physical_cover: bool = false

## Modificateur de détection global selon la lumière / conditions
var _environment_modifier: float = 1.0


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE — DÉTECTION
# ─────────────────────────────────────────────────────────────────────────────

## Appelé chaque frame par la scène Daven. delta = process delta.
## daven_pos, enemy_pos en Vector2 tile-space. enemy_facing = angle en radians.
func process_detection(
	enemy_id: String,
	enemy_type: String,
	daven_pos: Vector2,
	enemy_pos: Vector2,
	enemy_facing: float,
	delta: float
) -> void:
	var params: Dictionary = ENEMY_TYPES.get(enemy_type, ENEMY_TYPES["guard_patrol"])
	var current: float = _detection_values.get(enemy_id, 0.0)

	var dist: float = daven_pos.distance_to(enemy_pos)
	if dist > params["vision_distance"]:
		# Hors de portée → oubli progressif
		current = maxf(current - params["forget_rate"] * delta, 0.0)
	else:
		var angle_to_daven: float = (daven_pos - enemy_pos).angle()
		var angle_diff: float = absf(_angle_diff(angle_to_daven, enemy_facing))

		var half_fov: float = deg_to_rad(params["vision_angle"] / 2.0)
		var peripheral_fov: float = deg_to_rad(70.0)  # 140° total

		var rate: float = 0.0
		if angle_diff <= half_fov:
			rate = params["detection_rate"]
		elif angle_diff <= half_fov + peripheral_fov:
			rate = params["peripheral_rate"]
		else:
			rate = -params["forget_rate"]

		if _in_physical_cover:
			rate *= 0.4
		rate *= _environment_modifier

		current = clampf(current + rate * delta, 0.0, 100.0)

	var old: float = _detection_values.get(enemy_id, 0.0)
	_detection_values[enemy_id] = current

	if current != old:
		detection_increased.emit(enemy_id, old, current)
		if current >= 100.0 and old < 100.0:
			detected_by.emit(enemy_id)
			Cover.raise_alert(1)


## Enregistre un bruit généré par Daven. La scène appelle ça sur les actions bruyantes.
func generate_noise(action: String, daven_pos: Vector2) -> void:
	var radius: float = NOISE_LEVELS.get(action, 0.0)
	if radius > 0.0:
		noise_generated.emit(action, radius)


## Retourne le niveau de détection maximum parmi tous les ennemis actifs.
func get_max_detection() -> float:
	var max_val: float = 0.0
	for val in _detection_values.values():
		max_val = maxf(max_val, val)
	return max_val


## Retourne true si Daven est en alerte (détection ≥ 80 quelque part).
func is_under_alert() -> bool:
	return get_max_detection() >= 80.0


## Met à jour si Daven est en couverture physique.
func set_physical_cover(in_cover: bool) -> void:
	_in_physical_cover = in_cover


## Met à jour le modificateur d'environnement (nuit = 0.5, plein jour = 1.5).
func set_environment_modifier(modifier: float) -> void:
	_environment_modifier = clampf(modifier, 0.1, 3.0)


## Réinitialise la détection d'un ennemi (si Daven sort de la zone).
func reset_enemy(enemy_id: String) -> void:
	_detection_values.erase(enemy_id)


## Réinitialise tout (nouvelle zone / chargement).
func reset_all() -> void:
	_detection_values.clear()


# ─────────────────────────────────────────────────────────────────────────────
# LOGIQUE INTERNE
# ─────────────────────────────────────────────────────────────────────────────

## Différence angulaire normalisée entre -PI et PI.
func _angle_diff(a: float, b: float) -> float:
	var diff: float = fmod(a - b, TAU)
	if diff > PI:
		diff -= TAU
	elif diff < -PI:
		diff += TAU
	return diff
