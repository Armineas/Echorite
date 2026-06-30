extends Node
## DavenCoverSystem — Autoload (nom : "Cover")
## Gère les couvertures de Daven : identités, crédibilité, zones, PNJs suspects.
##
## Principe : plusieurs identités actives, une seule activable à la fois par zone.
## La crédibilité se dégrade si Daven passe trop de temps dans une zone,
## agit de façon incohérente avec l'identité, ou si un PNJ suspect le voit.

signal cover_activated(cover_id: String)
signal cover_deactivated(cover_id: String)
signal credibility_changed(cover_id: String, old_value: int, new_value: int)
signal cover_blown(cover_id: String)
signal alert_level_changed(new_level: int)


# ─────────────────────────────────────────────────────────────────────────────
# DÉFINITIONS DES COUVERTURES
# ─────────────────────────────────────────────────────────────────────────────

## Niveau d'alerte global : 0 = normal, 1 = suspicion, 2 = alerte, 3 = compromis
enum AlertLevel { NORMAL, SUSPICIOUS, ALERT, COMPROMISED }

const COVERS: Dictionary = {
	"fonctionnaire_transit": {
		"name":         {"fr": "Fonctionnaire de transit"},
		"description":  {"fr": "Agent administratif en mission de contrôle des flux migratoires."},
		"valid_zones":  ["zone_administrative", "postes_frontiere", "camps_refugies"],
		"suspicious_npcs": ["officier_vareth_senior", "agent_elindre"],
		"max_exposure_weeks": 8,   # Au-delà, risque de reconnaissance
		"act_available": 1,
		"act_blown":     2,        # Tombée à l'extraction de Kira
	},
	"marchand_itinerant": {
		"name":         {"fr": "Marchand itinérant"},
		"description":  {"fr": "Commerçant de province avec patente impériale de circulation."},
		"valid_zones":  ["routes_commerciales", "villes_frontieres", "marches"],
		"suspicious_npcs": ["douanier_connaisseur", "agent_elindre"],
		"max_exposure_weeks": 12,
		"act_available": 1,
		"act_blown":     0,        # Non compromise (si non utilisée en zone à risque)
	},
	"conseiller_juridique": {
		"name":         {"fr": "Conseiller juridique provisoire"},
		"description":  {"fr": "Mandaté par un cabinet impérial pour audit de conformité régionale."},
		"valid_zones":  ["administration_imperiale", "tribunaux", "bureaux_gouvernementaux"],
		"suspicious_npcs": ["juge_imperial_regional", "greffier_archive_centrale"],
		"max_exposure_weeks": 4,
		"act_available": 2,
		"act_blown":     0,
	},
	"daven_lui_meme": {
		"name":         {"fr": "Daven"},
		"description":  {"fr": "Son vrai nom. Utilisable seulement après la chute de toutes les couvertures."},
		"valid_zones":  ["resistance", "camp_seira", "mine"],
		"suspicious_npcs": [],
		"max_exposure_weeks": 999,
		"act_available": 3,        # Acte 3 uniquement
		"act_blown":     0,
	},
}

## Crédibilité par couverture (100 = intact, 0 = grillée).
var _credibility: Dictionary = {}
var _active_cover: String = ""
var _alert_level: int = AlertLevel.NORMAL
var _weeks_in_cover: Dictionary = {}


func _ready() -> void:
	_load_state()


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE — ACTIVATION
# ─────────────────────────────────────────────────────────────────────────────

## Active une couverture dans la zone courante.
func activate_cover(cover_id: String, zone: String) -> bool:
	if not can_use_cover(cover_id, zone):
		return false
	var old: String = _active_cover
	if old != "" and old != cover_id:
		cover_deactivated.emit(old)
	_active_cover = cover_id
	cover_activated.emit(cover_id)
	return true


func deactivate_cover() -> void:
	if _active_cover != "":
		cover_deactivated.emit(_active_cover)
		_active_cover = ""


func get_active_cover() -> String:
	return _active_cover


## Vérifie si une couverture est utilisable dans une zone.
func can_use_cover(cover_id: String, zone: String) -> bool:
	var cover: Dictionary = COVERS.get(cover_id, {})
	if cover.is_empty():
		return false
	if cover.get("act_blown", 0) != 0 and GSM.current_act() >= cover["act_blown"]:
		return false
	if zone not in cover.get("valid_zones", []):
		return false
	if get_credibility(cover_id) <= 0:
		return false
	return true


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE — CRÉDIBILITÉ
# ─────────────────────────────────────────────────────────────────────────────

func get_credibility(cover_id: String) -> int:
	return _credibility.get(cover_id, 100)


## Dégrade la crédibilité d'une couverture.
func degrade_credibility(cover_id: String, amount: int) -> void:
	var old_val: int = get_credibility(cover_id)
	var new_val: int = clampi(old_val - amount, 0, 100)
	_credibility[cover_id] = new_val
	credibility_changed.emit(cover_id, old_val, new_val)
	if new_val <= 0 and old_val > 0:
		cover_blown.emit(cover_id)
		GSM.set_flag(60, true)  # COVER_BLOWN
	_save_state()


## Appeler quand Daven passe du temps dans une zone (chaque scène = ~1 semaine).
func tick_cover_time(cover_id: String) -> void:
	_weeks_in_cover[cover_id] = _weeks_in_cover.get(cover_id, 0) + 1
	var cover: Dictionary = COVERS.get(cover_id, {})
	var max_weeks: int = cover.get("max_exposure_weeks", 12)
	var weeks: int = _weeks_in_cover[cover_id]
	if weeks > max_weeks:
		degrade_credibility(cover_id, (weeks - max_weeks) * 5)


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE — NIVEAU D'ALERTE
# ─────────────────────────────────────────────────────────────────────────────

func get_alert_level() -> int:
	return _alert_level


func raise_alert(amount: int = 1) -> void:
	var old: int = _alert_level
	_alert_level = clampi(_alert_level + amount, 0, AlertLevel.COMPROMISED)
	if _alert_level != old:
		alert_level_changed.emit(_alert_level)
		if _alert_level >= AlertLevel.COMPROMISED:
			_on_cover_compromised()


func lower_alert(amount: int = 1) -> void:
	var old: int = _alert_level
	_alert_level = clampi(_alert_level - amount, 0, AlertLevel.COMPROMISED)
	if _alert_level != old:
		alert_level_changed.emit(_alert_level)


func reset_alert() -> void:
	_alert_level = AlertLevel.NORMAL
	alert_level_changed.emit(_alert_level)


## Retourne true si le PNJ suspect est une menace pour la couverture active.
func is_suspicious_npc_threatening(npc_id: String) -> bool:
	if _active_cover.is_empty():
		return false
	var cover: Dictionary = COVERS.get(_active_cover, {})
	return npc_id in cover.get("suspicious_npcs", [])


# ─────────────────────────────────────────────────────────────────────────────
# LOGIQUE INTERNE
# ─────────────────────────────────────────────────────────────────────────────

func _on_cover_compromised() -> void:
	if _active_cover != "":
		degrade_credibility(_active_cover, 100)
	GSM.set_flag(60, true)  # COVER_BLOWN général


func _save_state() -> void:
	# Persistance simplifiée — les valeurs clés dans GSM
	pass


func _load_state() -> void:
	for cover_id in COVERS:
		_credibility[cover_id] = 100
		_weeks_in_cover[cover_id] = 0
	# Couverture fonctionnaire grillée en Acte 2
	if GSM.current_act() >= 2:
		_credibility["fonctionnaire_transit"] = 0
