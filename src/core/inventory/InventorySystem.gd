extends Node
## InventorySystem — Autoload (nom : "Inventory")
## Inventaire d'Aldric : armes, armures, consommables.
##
## Simplicité voulue pour V1 :
##   - 1 slot arme + 1 slot armure par personnage actif
##   - Consommables en quantité
##   - Stats de combat dérivées de l'équipement
##   - Persistance dans GSM via flags 91-99

signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)
signal item_equipped(slot: String, item_id: String)
signal item_unequipped(slot: String)


# ─────────────────────────────────────────────────────────────────────────────
# CATALOGUE D'OBJETS
# ─────────────────────────────────────────────────────────────────────────────

enum ItemType { WEAPON, ARMOR, CONSUMABLE }

const ITEMS: Dictionary = {
	# ── Armes ─────────────────────────────────────────────────────────────────
	"epee_standard": {
		"name":    {"fr": "Épée standard"},
		"type":    ItemType.WEAPON,
		"atk":     8,
		"description": {"fr": "Équipement impérial de base. Fiable."},
	},
	"epee_desertion": {
		"name":    {"fr": "Épée de fortune"},
		"type":    ItemType.WEAPON,
		"atk":     6,
		"description": {"fr": "Récupérée à la hâte. Moins efficace, mais à lui."},
	},
	"hache_brennan": {
		"name":    {"fr": "Hache de Brennan"},
		"type":    ItemType.WEAPON,
		"atk":     11,
		"description": {"fr": "L'arme de Brennan, si elle lui est confiée ou si il meurt."},
	},
	"couteau_contact": {
		"name":    {"fr": "Couteau de contact"},
		"type":    ItemType.WEAPON,
		"atk":     4,
		"description": {"fr": "Daven en a toujours un. Seïra lui en donne un à CP3."},
	},

	# ── Armures ───────────────────────────────────────────────────────────────
	"armure_imperiale": {
		"name":    {"fr": "Armure impériale"},
		"type":    ItemType.ARMOR,
		"def":     6,
		"description": {"fr": "Portée avant la désertion. Trop reconnaissable."},
	},
	"veste_resistance": {
		"name":    {"fr": "Veste de la résistance"},
		"type":    ItemType.ARMOR,
		"def":     4,
		"description": {"fr": "Moins protectrice. Personne ne la reconnaît comme ennemie."},
	},
	"manteau_cain": {
		"name":    {"fr": "Manteau de déserteur"},
		"type":    ItemType.ARMOR,
		"def":     3,
		"description": {"fr": "Caïn en donne un si Aldric le libère."},
	},

	# ── Consommables ──────────────────────────────────────────────────────────
	"potion_soin_petit": {
		"name":    {"fr": "Herbes de soin"},
		"type":    ItemType.CONSUMABLE,
		"heal":    20,
		"description": {"fr": "Soins de base. Lyria peut en donner si elle est dans l'équipe."},
	},
	"potion_soin_grand": {
		"name":    {"fr": "Baume de Lyria"},
		"type":    ItemType.CONSUMABLE,
		"heal":    50,
		"description": {"fr": "Préparation de Lyria. Disponible seulement si elle est recrutée."},
	},
	"antidote_echorite": {
		"name":    {"fr": "Antidote Échorite"},
		"type":    ItemType.CONSUMABLE,
		"effect":  "reduce_echorite",
		"amount":  15,
		"description": {"fr": "Réduit l'exposition au cristal. Lyria est la seule à pouvoir en fabriquer."},
	},
	"ration_combat": {
		"name":    {"fr": "Ration de campagne"},
		"type":    ItemType.CONSUMABLE,
		"heal":    10,
		"description": {"fr": "Nourriture de base. Restaure un peu de PV entre les combats."},
	},
}


# ─────────────────────────────────────────────────────────────────────────────
# ÉTAT
# ─────────────────────────────────────────────────────────────────────────────

## Stock { item_id: quantity }
var _stock: Dictionary = {}

## Équipement actif par personnage { "aldric": {"weapon": id, "armor": id}, ... }
var _equipped: Dictionary = {
	"aldric": {"weapon": "epee_standard", "armor": "armure_imperiale"},
}


func _ready() -> void:
	_load_state()


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE — STOCK
# ─────────────────────────────────────────────────────────────────────────────

func get_quantity(item_id: String) -> int:
	return _stock.get(item_id, 0)


func has_item(item_id: String, quantity: int = 1) -> bool:
	return get_quantity(item_id) >= quantity


func add_item(item_id: String, quantity: int = 1) -> void:
	if not ITEMS.has(item_id):
		push_warning("InventorySystem: item inconnu — " + item_id)
		return
	_stock[item_id] = _stock.get(item_id, 0) + quantity
	item_added.emit(item_id, quantity)
	_save_state()


func remove_item(item_id: String, quantity: int = 1) -> bool:
	if not has_item(item_id, quantity):
		return false
	_stock[item_id] = _stock[item_id] - quantity
	if _stock[item_id] <= 0:
		_stock.erase(item_id)
	item_removed.emit(item_id, quantity)
	_save_state()
	return true


## Utilise un consommable (applique son effet sur la cible).
func use_consumable(item_id: String, target_character: String) -> bool:
	if not has_item(item_id):
		return false
	var item: Dictionary = ITEMS.get(item_id, {})
	if item.get("type") != ItemType.CONSUMABLE:
		return false

	if item.has("heal"):
		GSM.heal_character(target_character, item["heal"])
	if item.get("effect") == "reduce_echorite":
		Echorite.expose_amount(target_character, -item.get("amount", 0))

	remove_item(item_id, 1)
	return true


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE — ÉQUIPEMENT
# ─────────────────────────────────────────────────────────────────────────────

func equip(character: String, item_id: String) -> bool:
	var item: Dictionary = ITEMS.get(item_id, {})
	if item.is_empty():
		return false
	var slot: String = ""
	match item.get("type"):
		ItemType.WEAPON: slot = "weapon"
		ItemType.ARMOR:  slot = "armor"
		_: return false

	if not _equipped.has(character):
		_equipped[character] = {}
	_equipped[character][slot] = item_id
	item_equipped.emit(slot, item_id)
	_save_state()
	return true


func unequip(character: String, slot: String) -> void:
	if _equipped.has(character) and _equipped[character].has(slot):
		_equipped[character].erase(slot)
		item_unequipped.emit(slot)
		_save_state()


func get_equipped(character: String, slot: String) -> String:
	return _equipped.get(character, {}).get(slot, "")


## Retourne le bonus d'ATK de l'équipement actuel.
func get_atk_bonus(character: String) -> int:
	var weapon_id: String = get_equipped(character, "weapon")
	if weapon_id.is_empty():
		return 0
	return ITEMS.get(weapon_id, {}).get("atk", 0)


## Retourne le bonus de DEF de l'équipement actuel.
func get_def_bonus(character: String) -> int:
	var armor_id: String = get_equipped(character, "armor")
	if armor_id.is_empty():
		return 0
	return ITEMS.get(armor_id, {}).get("def", 0)


## Retourne tous les items d'un type.
func get_items_of_type(item_type: int) -> Array[String]:
	var result: Array[String] = []
	for item_id in _stock:
		if ITEMS.get(item_id, {}).get("type") == item_type:
			result.append(item_id)
	return result


# ─────────────────────────────────────────────────────────────────────────────
# PERSISTANCE (simplifiée — stock principal dans flags GSM)
# ─────────────────────────────────────────────────────────────────────────────

func _save_state() -> void:
	# Stockage minimal pour la V1 — sera enrichi avec SaveSystem
	pass


func _load_state() -> void:
	# Équipement de départ selon l'état narratif
	if GSM.current_act() >= 2 and GSM.get_flag(25):  # Aldric a déserté
		_equipped["aldric"] = {"weapon": "epee_desertion", "armor": "veste_resistance"}
	# Consommables de départ
	_stock = {"ration_combat": 3, "potion_soin_petit": 2}
