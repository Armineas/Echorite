class_name CombatManager
extends Node
## CombatManager (P1, tâche #11)
## Orchestre un combat au tour par tour.
## Instancié par la scène de combat d'Aldric. Pas un autoload.
##
## Flux d'un tour :
##   1. turn_started → l'UI affiche les options pour l'unité active
##   2. Le joueur (ou l'IA) appelle action_attack / action_defend / action_item / action_flee
##   3. L'action est résolue → hp_changed, unit_died si besoin
##   4. turn_ended → on passe à l'unité suivante dans la file
##   5. Quand combat terminé → combat_ended(result)


enum CombatResult { VICTORY, DEFEAT, FLED }
enum ActionType { ATTACK, DEFEND, ITEM, FLEE }


# ─────────────────────────────────────────────────────────────────────────────
# SIGNAUX
# ─────────────────────────────────────────────────────────────────────────────

signal combat_started(player_units: Array, enemy_units: Array)
signal turn_started(unit: CombatUnit)
signal action_resolved(attacker: CombatUnit, target: CombatUnit, damage: int)
signal unit_protected_aldric(protector: CombatUnit)
signal unit_died_in_combat(unit: CombatUnit)
signal combat_ended(result: CombatResult)
signal log_message(text: String)


# ─────────────────────────────────────────────────────────────────────────────
# ÉTAT INTERNE
# ─────────────────────────────────────────────────────────────────────────────

var _player_units: Array[CombatUnit] = []   # [aldric, slot1, slot2]
var _enemy_units:  Array[CombatUnit] = []
var _turn_queue:   Array[CombatUnit] = []   # File d'initiative (triée par speed)
var _current_unit_index: int = 0
var _is_running: bool = false
var _awaiting_player_input: bool = false


# ─────────────────────────────────────────────────────────────────────────────
# INITIALISATION
# ─────────────────────────────────────────────────────────────────────────────

## Lance un combat.
## player_units : [aldric_unit, companion1, companion2] (companions peuvent manquer)
## enemy_units  : tableau d'ennemis
func start_combat(player_units: Array[CombatUnit], enemy_units: Array[CombatUnit]) -> void:
	assert(player_units.size() >= 1, "CombatManager : au moins Aldric requis.")

	_player_units = player_units
	_enemy_units = enemy_units

	# Marquer Aldric
	_player_units[0].is_aldric = true

	# Connecter les signaux de mort
	for unit in _player_units + _enemy_units:
		unit.died.connect(_on_unit_died)

	_build_turn_queue()
	_is_running = true
	combat_started.emit(_player_units, _enemy_units)
	_start_next_turn()


# ─────────────────────────────────────────────────────────────────────────────
# ACTIONS DU JOUEUR
# ─────────────────────────────────────────────────────────────────────────────

## Attaque une cible.
func action_attack(target: CombatUnit) -> void:
	if not _awaiting_player_input:
		return
	_awaiting_player_input = false
	var attacker := _get_current_unit()
	_resolve_attack(attacker, target)
	_end_turn()


## Passe en posture défensive.
func action_defend() -> void:
	if not _awaiting_player_input:
		return
	_awaiting_player_input = false
	_get_current_unit().defend()
	_log("%s se défend." % _get_current_unit().display_name)
	_end_turn()


## Utilise un objet (à compléter selon le système d'inventaire).
func action_item(_item_id: String, _target: CombatUnit) -> void:
	if not _awaiting_player_input:
		return
	_awaiting_player_input = false
	# TODO : intégrer avec le système d'inventaire
	_end_turn()


## Tentative de fuite.
func action_flee() -> void:
	if not _awaiting_player_input:
		return
	_awaiting_player_input = false
	# 50% de chance de fuir en combat normal
	if randf() < 0.5:
		_log("Vous fuyez le combat.")
		_end_combat(CombatResult.FLED)
	else:
		_log("Impossible de fuir !")
		_end_turn()


# ─────────────────────────────────────────────────────────────────────────────
# RÉSOLUTION DES ACTIONS
# ─────────────────────────────────────────────────────────────────────────────

func _resolve_attack(attacker: CombatUnit, target: CombatUnit) -> void:
	var raw: int = attacker.calculate_attack_damage()
	var dealt: int = target.take_damage(raw)
	_log("%s attaque %s : %d dégâts." % [attacker.display_name, target.display_name, dealt])
	action_resolved.emit(attacker, target, dealt)


## IA ennemie : attaque le personnage du joueur avec le moins de PV.
func _run_enemy_turn(enemy: CombatUnit) -> void:
	var targets := _get_living_player_units()
	if targets.is_empty():
		return
	targets.sort_custom(func(a, b): return a.hp < b.hp)
	var target: CombatUnit = targets[0]
	_resolve_attack(enemy, target)


# ─────────────────────────────────────────────────────────────────────────────
# FILE D'INITIATIVE
# ─────────────────────────────────────────────────────────────────────────────

func _build_turn_queue() -> void:
	_turn_queue.clear()
	for u in _player_units + _enemy_units:
		if not u.is_dead:
			_turn_queue.append(u)
	_turn_queue.sort_custom(func(a, b): return a.speed > b.speed)
	_current_unit_index = 0


func _get_current_unit() -> CombatUnit:
	return _turn_queue[_current_unit_index]


func _start_next_turn() -> void:
	# Avancer dans la file en sautant les morts
	while _current_unit_index < _turn_queue.size() and _turn_queue[_current_unit_index].is_dead:
		_current_unit_index += 1

	# Fin du cycle → reconstruire la file pour le prochain cycle
	if _current_unit_index >= _turn_queue.size():
		_build_turn_queue()

	if not _is_running:
		return

	var unit := _get_current_unit()
	turn_started.emit(unit)

	if unit.is_player:
		_awaiting_player_input = true
	else:
		# Tour ennemi : résolution automatique
		_awaiting_player_input = false
		_run_enemy_turn(unit)
		_end_turn()


func _end_turn() -> void:
	if not _is_running:
		return
	_get_current_unit().end_turn()
	_current_unit_index += 1

	if _check_combat_end():
		return

	_start_next_turn()


# ─────────────────────────────────────────────────────────────────────────────
# CONDITIONS DE FIN
# ─────────────────────────────────────────────────────────────────────────────

func _check_combat_end() -> bool:
	if _get_living_enemy_units().is_empty():
		_end_combat(CombatResult.VICTORY)
		return true

	if _get_living_player_units().is_empty():
		_end_combat(CombatResult.DEFEAT)
		return true

	return false


func _end_combat(result: CombatResult) -> void:
	_is_running = false
	combat_ended.emit(result)


# ─────────────────────────────────────────────────────────────────────────────
# MÉCANIQUE ALDRIC À 0 PV
# ─────────────────────────────────────────────────────────────────────────────

func _on_unit_died(unit: CombatUnit) -> void:
	unit_died_in_combat.emit(unit)

	# Si c'est Aldric qui tombe à 0, un compagnon doit le protéger.
	if unit.is_aldric:
		_try_protect_aldric()
		return

	# Si c'est un compagnon, le tuer définitivement dans le GameStateManager.
	if unit.is_player and not unit.is_aldric:
		_log("%s est tombé définitivement." % unit.display_name)
		GSM.kill_companion(unit.unit_id, "combat", GSM.current_act)

	_check_combat_end()


## Cherche un compagnon vivant pour protéger Aldric.
## Le premier compagnon vivant par ordre de priorité (Protecteur > autre) sacrifie son prochain tour.
func _try_protect_aldric() -> void:
	var living := _get_living_player_units()
	# Retirer Aldric de la liste
	living = living.filter(func(u): return not u.is_aldric)

	if living.is_empty():
		# Plus personne — Game Over
		_log("Tous les compagnons sont tombés. Game Over.")
		_end_combat(CombatResult.DEFEAT)
		return

	# Prioriser les Protecteurs
	var protectors := living.filter(
		func(u): return u.archetype == GSM.CompanionArchetype.PROTECTOR)
	var protector: CombatUnit = protectors[0] if not protectors.is_empty() else living[0]

	# Aldric est "inconscient" — le protecteur continue seul.
	_player_units[0].hp = 1  # Maintenu à 1 PV, pas vraiment mort
	_log("%s protège Aldric et continue seul !" % protector.display_name)
	unit_protected_aldric.emit(protector)


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

func _get_living_player_units() -> Array[CombatUnit]:
	return _player_units.filter(func(u): return not u.is_dead) as Array[CombatUnit]


func _get_living_enemy_units() -> Array[CombatUnit]:
	return _enemy_units.filter(func(u): return not u.is_dead) as Array[CombatUnit]


func get_living_enemies() -> Array[CombatUnit]:
	return _get_living_enemy_units()


func get_living_players() -> Array[CombatUnit]:
	return _get_living_player_units()


func _log(msg: String) -> void:
	log_message.emit(msg)
