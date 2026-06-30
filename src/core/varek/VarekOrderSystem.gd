extends Node
## VarekOrderSystem — Autoload (nom : "VOS")
## Gère les ordres signables du mode Varek.
##
## Chaque ordre est un document formel que Varek peut signer, refuser, ou différer.
## Certains ordres sont "lock narratif" : si Varek ne signe pas, Orveth signe à sa place.
## Le joueur influence COMMENT l'ordre est exécuté, pas S'IL l'est.

signal order_presented(order_id: String)
signal order_signed(order_id: String, signed_by: String)
signal order_refused(order_id: String)
signal lock_narrative_executed(order_id: String)


# ─────────────────────────────────────────────────────────────────────────────
# DÉFINITIONS DES ORDRES
# ─────────────────────────────────────────────────────────────────────────────

## Format :
## {
##   "id":           String — identifiant unique
##   "title":        {"fr": String}
##   "body":         {"fr": String} — texte du rapport/ordre
##   "visible_effects":  {"fr": String} — ce que Varek peut voir avant de signer
##   "hidden_effects":   {"fr": String} — ce que le joueur découvre après
##   "act":          int — acte où l'ordre est présenté
##   "lock_narrative":   bool — si true, Orveth exécute si Varek refuse
##   "sign_effects": Array[Dictionary] — flags posés si signé par Varek
##   "refuse_effects":   Array[Dictionary] — flags posés si refusé par Varek
##   "lock_effects":     Array[Dictionary] — flags posés si exécuté par Orveth
## }

const ORDERS: Array[Dictionary] = [
	{
		"id":              "protocole_amplification",
		"title":           {"fr": "Protocole d'Amplification — Directive 7"},
		"body":            {"fr": "Directive 7 autorise l'administration d'extrait de cristal d'Échorite aux unités de première ligne à titre de stabilisant de performance opérationnelle. Durée initiale : 60 jours. Révision obligatoire."},
		"visible_effects": {"fr": "Amélioration des indicateurs de performance au combat. Réduction des désertions."},
		"hidden_effects":  {"fr": "Exposition cumulative des soldats. Dépendance progressive. Altération de l'autonomie de jugement après 4 semaines."},
		"act":             1,
		"lock_narrative":  false,
		"sign_effects":    [{"type": "set_flag", "flag": 10, "value": true}, {"type": "expose_character", "character": "soldiers", "amount": 15}],
		"refuse_effects":  [{"type": "set_flag", "flag": 10, "value": false}],
		"lock_effects":    [],
	},
	{
		"id":              "velshan_neutralisation",
		"title":           {"fr": "Ordre de Neutralisation Sectorielle — Vel'Shan"},
		"body":            {"fr": "Ordonnance d'exécution sectorielle. Vel'Shan. Périmètre de résistance active. Population civile comprise dans le périmètre. Délai d'exécution : 48 heures."},
		"visible_effects": {"fr": "Élimination de la résistance organisée dans le secteur est. Sécurisation de la route minière."},
		"hidden_effects":  {"fr": "2400 victimes civiles. Génère CP3 si Aldric a refusé l'ordre de son côté. Crée la première vraie cassure dans la légitimité impériale."},
		"act":             2,
		"lock_narrative":  true,  # Orveth exécute si Varek refuse
		"sign_effects":    [{"type": "set_flag", "flag": 22, "value": true}, {"type": "set_flag", "flag": 23, "value": true}],
		"refuse_effects":  [{"type": "set_flag", "flag": 22, "value": false}, {"type": "set_flag", "flag": 23, "value": true}],
		"lock_effects":    [{"type": "set_flag", "flag": 22, "value": false}, {"type": "set_flag", "flag": 23, "value": true}],
	},
	{
		"id":              "protocole_extension_60j",
		"title":           {"fr": "Extension Protocole d'Amplification — J+60"},
		"body":            {"fr": "Rapport d'évaluation à 60 jours. Données : 7ème Régiment. 2 cas de dégradation sensorielle documentés sur 340 hommes. Recommandation du commandement : poursuite du protocole, révision à J+120."},
		"visible_effects": {"fr": "Maintien des indicateurs de performance. Stabilité des unités affectées."},
		"hidden_effects":  {"fr": "Les 2 cas documentés sont l'extrémité visible d'un problème systémique. Sehn a filtré 14 autres rapports."},
		"act":             2,
		"lock_narrative":  false,
		"sign_effects":    [{"type": "set_flag", "flag": 11, "value": true}, {"type": "expose_soldiers", "amount": 20}],
		"refuse_effects":  [{"type": "set_flag", "flag": 11, "value": false}],
		"lock_effects":    [],
	},
	{
		"id":              "7eme_elimination",
		"title":           {"fr": "Ordre d'Élimination — 7ème Régiment"},
		"body":            {"fr": "Le 7ème Régiment, affecté aux opérations minières depuis 10 mois, présente des 'non-conformités opérationnelles' irréversibles. Recommandation : élimination propre. Coût logistique minimal."},
		"visible_effects": {"fr": "Libération de 340 postes d'affectation. Élimination d'une unité à capacité de jugement compromise."},
		"hidden_effects":  {"fr": "Ce sont des soldats que Varek a envoyés là-bas. Certains pourraient récupérer avec suivi médical. Cette option n'est pas présentée dans le rapport."},
		"act":             3,
		"lock_narrative":  false,
		"sign_effects":    [{"type": "set_flag", "flag": 55, "value": false}],
		"refuse_effects":  [{"type": "set_flag", "flag": 55, "value": true}],
		"lock_effects":    [{"type": "set_flag", "flag": 55, "value": false}],
	},
	{
		"id":              "arret_extraction_mine",
		"title":           {"fr": "Arrêt d'Extraction — Secteur Minier Central"},
		"body":            {"fr": "Suspension immédiate de toutes les opérations d'extraction dans le secteur minier central. Évacuation du personnel. Scellement des accès."},
		"visible_effects": {"fr": "Perte de revenus miniers. Réduction de la production d'Échorite."},
		"hidden_effects":  {"fr": "Premier acte irréversible de Varek contre ses propres intérêts économiques. Possible seulement à l'Acte 3 après découverte des archives Sehn."},
		"act":             3,
		"lock_narrative":  false,
		"sign_effects":    [{"type": "set_flag", "flag": 51, "value": true}],
		"refuse_effects":  [],
		"lock_effects":    [],
	},
]

var _signed_orders: Array[String] = []
var _refused_orders: Array[String] = []
var _pending_orders: Array[String] = []


func _ready() -> void:
	_load_state()


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE
# ─────────────────────────────────────────────────────────────────────────────

## Retourne les ordres disponibles pour l'acte courant, non encore traités.
func get_pending_orders(act: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for order in ORDERS:
		if order["act"] == act and order["id"] not in _signed_orders and order["id"] not in _refused_orders:
			result.append(order)
	return result


## Varek signe l'ordre.
func sign_order(order_id: String) -> void:
	var order: Dictionary = _find_order(order_id)
	if order.is_empty():
		return
	_signed_orders.append(order_id)
	_apply_effects(order.get("sign_effects", []))
	order_signed.emit(order_id, "varek")
	_save_state()


## Varek refuse l'ordre.
func refuse_order(order_id: String) -> void:
	var order: Dictionary = _find_order(order_id)
	if order.is_empty():
		return
	_refused_orders.append(order_id)
	_apply_effects(order.get("refuse_effects", []))
	order_refused.emit(order_id)
	if order.get("lock_narrative", false):
		_execute_lock_narrative(order)
	_save_state()


func is_signed(order_id: String) -> bool:
	return order_id in _signed_orders


func is_refused(order_id: String) -> bool:
	return order_id in _refused_orders


# ─────────────────────────────────────────────────────────────────────────────
# LOGIQUE INTERNE
# ─────────────────────────────────────────────────────────────────────────────

func _find_order(order_id: String) -> Dictionary:
	for order in ORDERS:
		if order["id"] == order_id:
			return order
	return {}


func _execute_lock_narrative(order: Dictionary) -> void:
	_apply_effects(order.get("lock_effects", []))
	lock_narrative_executed.emit(order["id"])


func _apply_effects(effects: Array) -> void:
	for effect in effects:
		match effect.get("type", ""):
			"set_flag":
				GSM.set_flag(effect["flag"], effect["value"])
			"expose_character":
				if Echorite != null:
					Echorite.expose_amount(effect.get("character", ""), effect.get("amount", 0))
			"expose_soldiers":
				# Exposition des soldats affectés — pas un personnage jouable
				GSM.set_flag(90, GSM.get_flag(90) + effect.get("amount", 0))


func _save_state() -> void:
	GSM.set_flag(85, _signed_orders.size())


func _load_state() -> void:
	_signed_orders = []
	_refused_orders = []
