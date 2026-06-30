extends Node
## SeiraResourceManager — Autoload (nom : "SRM")
## Gère les 4 ressources du mode Seïra et les conditions de recrutement.
##
## Ressources : argent (gold), troupes (troops), renseignement (intel), moral (morale).
## Chaque décision consomme ou génère. Certains recrutements nécessitent plusieurs ressources.
## L'état persiste dans GSM via flags ressource (flags 70-73).

signal resources_changed(resource: String, old_value: int, new_value: int)
signal resource_depleted(resource: String)
signal recruitment_unlocked(companion_id: String)
signal recruitment_conditions_changed()


# ─────────────────────────────────────────────────────────────────────────────
# DONNÉES RESSOURCES
# ─────────────────────────────────────────────────────────────────────────────

## Plafonds par ressource. Ajustables selon l'acte.
const MAX_RESOURCES: Dictionary = {
	"gold":   200,
	"troops": 100,
	"intel":   80,
	"morale": 100,
}

## Valeurs de départ à chaque nouvelle partie.
const STARTING_RESOURCES: Dictionary = {
	"gold":   40,
	"troops": 15,
	"intel":   5,
	"morale": 60,
}

var _resources: Dictionary = {}

## Génération passive par acte (ajoutée au début de chaque acte).
const ACT_INCOME: Array[Dictionary] = [
	{},  # acte 0 (inutilisé)
	{"gold": 20, "troops":  5, "intel": 5, "morale": 0},  # acte 1
	{"gold": 35, "troops": 10, "intel": 8, "morale": 5},  # acte 2
	{"gold": 50, "troops": 15, "intel": 12, "morale": 5}, # acte 3
]


# ─────────────────────────────────────────────────────────────────────────────
# CONDITIONS DE RECRUTEMENT
# ─────────────────────────────────────────────────────────────────────────────

## Format : { companion_id: { "cost": {...}, "flags": [...], "description": "..." } }
## flags : conditions narratives (GSM flags) requises en plus du coût.
const RECRUITMENT_CONDITIONS: Dictionary = {
	"brennan": {
		"cost": {"gold": 10, "troops": 5},
		"flags": [],
		"description": {"fr": "Mercenaire expérimenté. Accessible dès l'Acte 1 si approché à la taverne."},
	},
	"lyria": {
		"cost": {"gold": 20, "intel": 10},
		"flags": [{"flag": 31, "value": true}],  # Daven l'a avertie
		"description": {"fr": "Médecin. Disponible seulement si Daven lui a transmis l'avertissement."},
	},
	"cain": {
		"cost": {"troops": 10, "morale": -10},
		"flags": [],
		"description": {"fr": "Déserteur. Coûte du moral — la coalition ne l'accueille pas facilement."},
	},
	"mira": {
		"cost": {"gold": 5, "intel": 5},
		"flags": [{"flag": 0, "value": true}],  # MIRA_PROTECTED par Daven
		"description": {"fr": "Réfugiée. Accessible uniquement si Daven l'a protégée à la frontière."},
	},
	"rael": {
		"cost": {"gold": 15},
		"flags": [],
		"description": {"fr": "Faussaire et imprimeur. Pas de conditions narratives."},
	},
	"thessa": {
		"cost": {"troops": 5, "morale": 10},
		"flags": [],
		"description": {"fr": "Ingénieure. Génère du moral à long terme."},
	},
	"orwen": {
		"cost": {"gold": 30, "intel": 15},
		"flags": [],
		"description": {"fr": "Diplomate. Coûteux mais ouvre des options politiques."},
	},
	"kira": {
		"cost": {"intel": 20},
		"flags": [{"flag": 32, "value": true}],  # Daven a extrait Kira
		"description": {"fr": "Archiviste. Disponible seulement si Daven l'a extraite de Vareth."},
	},
	"brand": {
		"cost": {"troops": 15, "gold": 10},
		"flags": [],
		"description": {"fr": "Combattant. Renforce directement les troupes d'Aldric."},
	},
}


# ─────────────────────────────────────────────────────────────────────────────
# INITILAISATION
# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_load_from_gsm()


func reset() -> void:
	_resources = STARTING_RESOURCES.duplicate(true)
	_save_to_gsm()


## Applique le revenu passif au début d'un acte.
func apply_act_income(act: int) -> void:
	if act < 1 or act > 3:
		return
	var income: Dictionary = ACT_INCOME[act]
	for res in income:
		add(res, income[res])


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE — RESSOURCES
# ─────────────────────────────────────────────────────────────────────────────

func get_resource(resource: String) -> int:
	return _resources.get(resource, 0)


## Ajoute une quantité (peut être négative). Retourne la valeur finale.
func add(resource: String, amount: int) -> int:
	var old: int = _resources.get(resource, 0)
	var capped: int = clampi(old + amount, 0, MAX_RESOURCES.get(resource, 999))
	_resources[resource] = capped
	_save_to_gsm()
	resources_changed.emit(resource, old, capped)
	if capped == 0 and old > 0:
		resource_depleted.emit(resource)
	return capped


## Consomme les ressources d'un coût. Retourne true si succès, false si insuffisant.
func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for res in cost:
		add(res, -cost[res])
	return true


## Vérifie si le coût est affordable.
func can_afford(cost: Dictionary) -> bool:
	for res in cost:
		if _resources.get(res, 0) < cost.get(res, 0):
			return false
	return true


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE — RECRUTEMENT
# ─────────────────────────────────────────────────────────────────────────────

## Vérifie si un compagnon est recrutrable (coût + flags narratifs).
func can_recruit(companion_id: String) -> bool:
	var cond: Dictionary = RECRUITMENT_CONDITIONS.get(companion_id, {})
	if cond.is_empty():
		return false
	if GSM.is_companion_recruited(companion_id) or GSM.is_companion_dead(companion_id):
		return false
	if not can_afford(cond.get("cost", {})):
		return false
	for flag_cond in cond.get("flags", []):
		if GSM.get_flag(flag_cond["flag"]) != flag_cond.get("value", true):
			return false
	return true


## Retourne les raisons pour lesquelles un recrutement est bloqué.
func get_block_reasons(companion_id: String) -> Array[String]:
	var reasons: Array[String] = []
	var cond: Dictionary = RECRUITMENT_CONDITIONS.get(companion_id, {})
	if cond.is_empty():
		reasons.append("Compagnon inconnu.")
		return reasons
	if GSM.is_companion_recruited(companion_id):
		reasons.append("Déjà recruté.")
		return reasons
	if GSM.is_companion_dead(companion_id):
		reasons.append("Mort.")
		return reasons
	var cost: Dictionary = cond.get("cost", {})
	for res in cost:
		if _resources.get(res, 0) < cost[res]:
			reasons.append("Ressource insuffisante : " + res)
	for flag_cond in cond.get("flags", []):
		if GSM.get_flag(flag_cond["flag"]) != flag_cond.get("value", true):
			reasons.append("Condition narrative non remplie.")
	return reasons


## Recrute un compagnon (déduit les ressources + notifie GSM + pipeline).
func recruit(companion_id: String) -> bool:
	if not can_recruit(companion_id):
		return false
	var cost: Dictionary = RECRUITMENT_CONDITIONS[companion_id].get("cost", {})
	if not spend(cost):
		return false
	GSM.recruit_companion(companion_id)
	recruitment_unlocked.emit(companion_id)
	recruitment_conditions_changed.emit()
	return true


## Liste des compagnons disponibles au recrutement dans cet acte.
func available_companions(act: int) -> Array[String]:
	var result: Array[String] = []
	for cid in RECRUITMENT_CONDITIONS:
		if can_recruit(cid):
			result.append(cid)
	return result


# ─────────────────────────────────────────────────────────────────────────────
# PERSISTANCE (flags GSM 70-73 = snapshot entier)
# ─────────────────────────────────────────────────────────────────────────────

## On stocke les ressources dans GSM via des flags numériques (70-73).
## Flag 70 = gold, 71 = troops, 72 = intel, 73 = morale.
func _save_to_gsm() -> void:
	GSM.set_flag(70, _resources.get("gold",   0))
	GSM.set_flag(71, _resources.get("troops", 0))
	GSM.set_flag(72, _resources.get("intel",  0))
	GSM.set_flag(73, _resources.get("morale", 0))


func _load_from_gsm() -> void:
	var gold: int = GSM.get_flag(70)
	if gold == false or gold == 0:
		reset()
		return
	_resources = {
		"gold":   GSM.get_flag(70),
		"troops": GSM.get_flag(71),
		"intel":  GSM.get_flag(72),
		"morale": GSM.get_flag(73),
	}
