class_name CompanionData
extends Resource
## CompanionData — Ressource statique d'un compagnon.
## Chaque compagnon a son propre fichier .tres dans res://design/companions/.
## Le CombatManager lit ces données pour construire les CombatUnit.


@export var companion_id: String = ""
@export var display_name: String = ""
@export var archetype: GameStateManager.CompanionArchetype = \
	GameStateManager.CompanionArchetype.SUPPORT

## Stats de combat de base (niveau de recrutement)
@export var base_hp: int = 0
@export var base_atq: int = 0
@export var base_def: int = 0
@export var base_speed: int = 0

## Croissance par acte (appliquée au moment où l'acte démarre)
@export var hp_per_act: int = 0
@export var atq_per_act: int = 0
@export var def_per_act: int = 0

## Description narrative courte (affichée dans l'UI de recrutement)
@export_multiline var description: String = ""

## Acte minimum de recrutement (1, 2 ou 3)
@export var recruit_act: int = 1


## Retourne les stats adaptées à l'acte courant.
func get_stats_for_act(act: int) -> Dictionary:
	var bonus: int = max(0, act - recruit_act)
	return {
		"hp":    base_hp    + hp_per_act    * bonus,
		"atq":   base_atq   + atq_per_act   * bonus,
		"def":   base_def   + def_per_act   * bonus,
		"speed": base_speed,
	}


## Crée un CombatUnit à partir de ces données pour l'acte donné.
func create_combat_unit(act: int) -> CombatUnit:
	var stats := get_stats_for_act(act)
	var unit := CombatUnit.new()
	unit.setup(
		companion_id,
		display_name,
		stats["hp"],
		stats["atq"],
		stats["def"],
		stats["speed"],
		true
	)
	unit.archetype = archetype
	return unit
