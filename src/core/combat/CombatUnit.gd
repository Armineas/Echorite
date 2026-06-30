class_name CombatUnit
extends RefCounted
## CombatUnit — Données et logique d'une unité de combat (Aldric, compagnon, ennemi).
## Pas une scène — une classe de données instanciée par le CombatManager.


# ─────────────────────────────────────────────────────────────────────────────
# STATS DE BASE
# ─────────────────────────────────────────────────────────────────────────────

var unit_id: String = ""      # "aldric", "brennan", "enemy_soldier_01"…
var display_name: String = ""
var is_player: bool = true    # false = ennemi (IA)
var is_aldric: bool = false   # comportement spécial à 0 PV

## Stats actuelles
var hp: int = 0
var max_hp: int = 0
var atq: int = 0      # Attaque physique
var def: int = 0      # Défense physique
var speed: int = 0    # Détermine l'ordre dans la file d'initiative

## Archétype (pour les compagnons)
var archetype: int = -1  # CompanionArchetype enum, -1 si ennemi

## Statuts actifs
var is_defending: bool = false  # A utilisé "Défense" ce tour
var is_dead: bool = false


signal died(unit: CombatUnit)
signal hp_changed(unit: CombatUnit, old_hp: int, new_hp: int)


# ─────────────────────────────────────────────────────────────────────────────
# INITIALISATION
# ─────────────────────────────────────────────────────────────────────────────

func setup(p_id: String, p_name: String, p_max_hp: int, p_atq: int,
		p_def: int, p_speed: int, p_is_player: bool = true) -> void:
	unit_id = p_id
	display_name = p_name
	max_hp = p_max_hp
	hp = p_max_hp
	atq = p_atq
	def = p_def
	speed = p_speed
	is_player = p_is_player


# ─────────────────────────────────────────────────────────────────────────────
# COMBAT
# ─────────────────────────────────────────────────────────────────────────────

## Applique des dégâts. Retourne les dégâts réellement subis.
func take_damage(raw_damage: int) -> int:
	var mitigation: int = def / 2 if is_defending else def / 4
	var effective: int = max(1, raw_damage - mitigation)
	var old_hp := hp
	hp = max(0, hp - effective)
	hp_changed.emit(self, old_hp, hp)
	if hp <= 0 and not is_dead:
		_on_hp_zero()
	return effective


## Soigne l'unité. Retourne les PV réellement restaurés.
func heal(amount: int) -> int:
	if is_dead:
		return 0
	var old_hp := hp
	hp = min(max_hp, hp + amount)
	hp_changed.emit(self, old_hp, hp)
	return hp - old_hp


## Calcule les dégâts infligés à une cible.
## Retourne la valeur AVANT mitigation de la cible.
func calculate_attack_damage() -> int:
	# Formule de base : ATQ + variation aléatoire ±15%
	var variance: float = randf_range(0.85, 1.15)
	return int(atq * variance)


## Active la posture de défense pour ce tour.
func defend() -> void:
	is_defending = true


## Réinitialise les états de fin de tour.
func end_turn() -> void:
	is_defending = false


## Gère le passage à 0 PV.
func _on_hp_zero() -> void:
	if is_aldric:
		# Aldric ne meurt pas — le CombatManager gère la protection par compagnon.
		return
	is_dead = true
	died.emit(self)


# ─────────────────────────────────────────────────────────────────────────────
# SÉRIALISATION (pour sauvegarde en cours de combat si besoin)
# ─────────────────────────────────────────────────────────────────────────────

func to_dict() -> Dictionary:
	return {
		"unit_id": unit_id,
		"hp": hp,
		"max_hp": max_hp,
		"is_dead": is_dead,
	}
