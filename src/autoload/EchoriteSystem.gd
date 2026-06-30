extends Node
## EchoriteSystem — Autoload (nom : "Echorite")
## Gère l'exposition à l'Échorite par personnage.
##
## Principe : compteur INVISIBLE. Le joueur ne voit jamais la barre.
## Il voit les conséquences comportementales sur les PNJ et les soldats.
##
## Seuils d'exposition :
##   0-20  : aucun effet notable
##   21-40 : légère réduction de la dissonance (ordres exécutés plus facilement)
##   41-60 : inhibitions altérées, comportements instinctifs amplifiés
##   61-80 : perte partielle d'autonomie de jugement (critère Lyria : -40%)
##   81+   : non-retour — reconnaissance des proches dégradée (seuil royal)
##
## L'exposition persiste dans GSM (flags 80-83).

signal threshold_crossed(character: String, level: int)
signal exposure_changed(character: String, old_value: int, new_value: int)


# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTES
# ─────────────────────────────────────────────────────────────────────────────

const CHARACTERS: Array[String] = ["aldric", "seira", "varek", "daven"]

## Flags GSM utilisés pour stocker l'exposition par personnage.
## 80 = aldric, 81 = seira, 82 = varek, 83 = daven
const GSM_FLAGS: Dictionary = {
	"aldric": 80,
	"seira":  81,
	"varek":  82,
	"daven":  83,
}

const THRESHOLDS: Array[int] = [20, 40, 60, 80]

## Durée d'exposition (en unités de scène) par type d'utilisation.
const EXPOSURE_PER_USE: Dictionary = {
	"brief_contact":   2,   # passage rapide dans la mine
	"extended_mine":   8,   # une scène entière dans les galeries
	"daily_use":      15,   # usage régulier (Varek s4_usage_prive)
	"combat_buff":     5,   # utilisation en combat
	"prolonged_duty": 20,   # affectation minière prolongée (soldats 7ème)
}

## Seuil à partir duquel le sevrage commence à avoir des effets visibles.
const WITHDRAWAL_THRESHOLD: int = 40

## Récupération par semaine sans exposition (en unités narratives).
const RECOVERY_PER_WEEK: int = 8


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE
# ─────────────────────────────────────────────────────────────────────────────

## Retourne l'exposition actuelle d'un personnage (0-100).
func get_exposure(character: String) -> int:
	return _clamp_exposure(GSM.get_flag(GSM_FLAGS.get(character, 80)))


## Ajoute de l'exposition. Retourne le nouveau niveau.
func expose(character: String, use_type: String) -> int:
	var amount: int = EXPOSURE_PER_USE.get(use_type, 5)
	return _add_exposure(character, amount)


## Ajoute directement une quantité d'exposition.
func expose_amount(character: String, amount: int) -> int:
	return _add_exposure(character, amount)


## Applique la récupération (appelé entre les actes ou lors d'un sevrage).
func recover(character: String, weeks: int = 1) -> int:
	return _add_exposure(character, -RECOVERY_PER_WEEK * weeks)


## Retourne le niveau de seuil actuel (0-4).
func get_threshold_level(character: String) -> int:
	var exp: int = get_exposure(character)
	for i in range(THRESHOLDS.size() - 1, -1, -1):
		if exp > THRESHOLDS[i]:
			return i + 1
	return 0


## Retourne true si le personnage est au-delà du seuil de non-retour.
func is_beyond_return(character: String) -> bool:
	return get_exposure(character) > THRESHOLDS[3]


## Retourne true si un personnage en sevrage souffre d'effets de manque.
func has_withdrawal_effects(character: String) -> bool:
	return get_exposure(character) >= WITHDRAWAL_THRESHOLD


## Retourne le pourcentage estimé de récupération cognitive possible.
## Correspond aux données de Lyria : 50% de récupération après 4 semaines si < 60.
func recovery_potential(character: String) -> float:
	var exp: int = get_exposure(character)
	if exp <= 20:
		return 1.0
	if exp <= 40:
		return 0.85
	if exp <= 60:
		return 0.5   # seuil Lyria : -40% de dissonance mais récupération possible
	if exp <= 80:
		return 0.1
	return 0.0       # non-retour


## Texte décrivant l'état comportemental observable (pour les PNJ, jamais pour le joueur direct).
func get_observable_description(character: String) -> String:
	match get_threshold_level(character):
		0: return "Comportement normal."
		1: return "Légèrement plus décisif que d'habitude. Peu d'hésitation dans les ordres reçus."
		2: return "Exécution des ordres sans questionnement notable. Instincts amplifiés."
		3: return "Autonomie de jugement réduite. Difficultés à remettre en question les instructions."
		4: return "Ne reconnaît plus ses proches facilement. Réponses aux ordres automatiques."
	return ""


# ─────────────────────────────────────────────────────────────────────────────
# LOGIQUE INTERNE
# ─────────────────────────────────────────────────────────────────────────────

func _add_exposure(character: String, delta: int) -> int:
	var flag_idx: int = GSM_FLAGS.get(character, 80)
	var old_val: int = _clamp_exposure(GSM.get_flag(flag_idx))
	var new_val: int = _clamp_exposure(old_val + delta)
	GSM.set_flag(flag_idx, new_val)
	if old_val != new_val:
		exposure_changed.emit(character, old_val, new_val)
		_check_threshold(character, old_val, new_val)
	return new_val


func _check_threshold(character: String, old_val: int, new_val: int) -> void:
	for t in THRESHOLDS:
		var crossed_up: bool   = old_val <= t and new_val > t
		var crossed_down: bool = old_val > t  and new_val <= t
		if crossed_up or crossed_down:
			threshold_crossed.emit(character, t)


func _clamp_exposure(val: Variant) -> int:
	if val == null or val == false:
		return 0
	return clampi(int(val), 0, 100)
