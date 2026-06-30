extends Node
## CompanionRegistry — Autoload singleton (nom : "CompanionRegistry")
## Point d'accès central aux CompanionData de chaque compagnon.
## Charge les ressources depuis res://design/companions/ au démarrage.


const COMPANION_RESOURCE_PATHS: Dictionary = {
	"brennan": "res://design/companions/brennan.tres",
	"lyria":   "res://design/companions/lyria.tres",
	"cain":    "res://design/companions/cain.tres",
	"mira":    "res://design/companions/mira.tres",
	"rael":    "res://design/companions/rael.tres",
	"thessa":  "res://design/companions/thessa.tres",
	"orwen":   "res://design/companions/orwen.tres",
	"kira":    "res://design/companions/kira.tres",
	"brand":   "res://design/companions/brand.tres",
}

var _cache: Dictionary = {}


func _ready() -> void:
	for id in COMPANION_RESOURCE_PATHS:
		var path: String = COMPANION_RESOURCE_PATHS[id]
		if ResourceLoader.exists(path):
			_cache[id] = load(path)
		else:
			push_warning("CompanionRegistry : ressource manquante — " + path)


## Retourne le CompanionData d'un compagnon ou null si inconnu.
func get_data(companion_id: String) -> CompanionData:
	return _cache.get(companion_id, null)


## Crée un CombatUnit prêt à l'emploi pour l'acte courant.
func create_unit(companion_id: String) -> CombatUnit:
	var data := get_data(companion_id)
	if data == null:
		push_error("CompanionRegistry : compagnon inconnu — " + companion_id)
		return null
	return data.create_combat_unit(GSM.current_act)


## Retourne tous les CompanionData des compagnons actuellement recrutés.
func get_recruited() -> Array[CompanionData]:
	var result: Array[CompanionData] = []
	for cid in _cache:
		if GSM.get_companion(cid).status == GSM.CompanionStatus.RECRUITED:
			result.append(_cache[cid])
	return result
