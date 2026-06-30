extends Node
## CourtManager — Autoload (nom : "Court")
## Gère la cour impériale de Varek : loyauté des conseillers, filtrage de l'information.
##
## 4 conseillers : Orveth, Sehn, Lireth, Veyra.
## Chacun a un niveau de loyauté (0-100) et des comportements propres.
## Sehn filtre les rapports défavorables — mécanisme de base du Lock narratif.
##
## La cour est persistée via flags GSM 86-89.

signal loyalty_changed(advisor: String, old_value: int, new_value: int)
signal sehn_filter_triggered(suppressed_report_id: String)
signal advisor_defects(advisor: String)


# ─────────────────────────────────────────────────────────────────────────────
# DONNÉES DES CONSEILLERS
# ─────────────────────────────────────────────────────────────────────────────

const ADVISORS: Dictionary = {
	"orveth": {
		"name":    {"fr": "Orveth"},
		"role":    {"fr": "Général de campagne"},
		"gsm_flag": 86,
		"default_loyalty": 75,
		"behavior": "executor",  # exécute sans questionner, même si Varek refuse
		"description": {"fr": "Fidèle à l'empire avant d'être fidèle à Varek. Exécute les ordres lock narratif si Varek refuse."},
	},
	"sehn": {
		"name":    {"fr": "Sehn"},
		"role":    {"fr": "Conseiller stratégique"},
		"gsm_flag": 87,
		"default_loyalty": 80,
		"behavior": "filter",    # filtre les informations défavorables
		"description": {"fr": "Protège Varek des informations qui le dérangeraient. Filtre les rapports négatifs sur l'Échorite."},
		"filter_threshold": 50,  # filtre si loyauté > 50 et rapport négatif
	},
	"lireth": {
		"name":    {"fr": "Lireth"},
		"role":    {"fr": "Agent de renseignement"},
		"gsm_flag": 88,
		"default_loyalty": 60,
		"behavior": "informer",  # transmet fidèlement, peut trahir si loyauté < 30
		"description": {"fr": "Travaille pour Varek depuis 16 ans. Sa loyauté est réelle mais conditionnelle."},
	},
	"veyra": {
		"name":    {"fr": "Veyra"},
		"role":    {"fr": "Chercheuse de terrain"},
		"gsm_flag": 89,
		"default_loyalty": 55,
		"behavior": "truth",     # dit la vérité même si inconfortable
		"description": {"fr": "Ne filtre pas. C'est elle qui montre les dessins anatomiques à Varek."},
	},
}

## Rapports filtrés par Sehn (que Varek ne reçoit jamais tant que Sehn est loyal et actif).
const FILTERED_REPORTS: Array[Dictionary] = [
	{
		"id": "rapport_degradation_sensorielle_2",
		"content": {"fr": "Cas 2-16 : dégradation sensorielle, perte de reconnaissance des proches. Unités du 7ème Régiment, secteur minier. Durée d'exposition : 9-11 semaines."},
		"act": 2,
		"would_trigger_flag": 33,
	},
	{
		"id": "rapport_desertions_miniere",
		"content": {"fr": "Taux de désertion secteur minier : 340% supérieur aux autres secteurs. Corrélation documentée avec la durée d'affectation."},
		"act": 2,
		"would_trigger_flag": 34,
	},
	{
		"id": "rapport_effets_cognitifs_officiers",
		"content": {"fr": "Officiers supérieurs affectés plus de 6 mois présentent une réduction de 40% des contestations d'ordres. Interprétation : amélioration ou altération ?"},
		"act": 2,
		"would_trigger_flag": 35,
	},
]


# ─────────────────────────────────────────────────────────────────────────────
# ÉTAT
# ─────────────────────────────────────────────────────────────────────────────

var _suppressed_reports: Array[String] = []


func _ready() -> void:
	_load_loyalty()


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE — LOYAUTÉ
# ─────────────────────────────────────────────────────────────────────────────

func get_loyalty(advisor: String) -> int:
	var data: Dictionary = ADVISORS.get(advisor, {})
	if data.is_empty():
		return 0
	var flag_val = GSM.get_flag(data["gsm_flag"])
	if flag_val == false or flag_val == null:
		return data.get("default_loyalty", 50)
	return int(flag_val)


## Change la loyauté d'un conseiller (delta peut être négatif).
func change_loyalty(advisor: String, delta: int) -> void:
	var data: Dictionary = ADVISORS.get(advisor, {})
	if data.is_empty():
		return
	var old_val: int = get_loyalty(advisor)
	var new_val: int = clampi(old_val + delta, 0, 100)
	GSM.set_flag(data["gsm_flag"], new_val)
	loyalty_changed.emit(advisor, old_val, new_val)
	if new_val <= 10 and old_val > 10:
		advisor_defects.emit(advisor)


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE — FILTRAGE DE SEHN
# ─────────────────────────────────────────────────────────────────────────────

## Vérifie si un rapport passe le filtre de Sehn.
## Retourne true si le rapport atteint Varek, false si filtré.
func passes_sehn_filter(report_id: String, act: int) -> bool:
	if _is_sehn_filtering_discovered():
		return true   # Acte 3 : Varek a vu les archives, le filtre est levé
	var sehn_loyalty: int = get_loyalty("sehn")
	var threshold: int = ADVISORS["sehn"].get("filter_threshold", 50)
	if sehn_loyalty > threshold:
		# Sehn filtre ce rapport et note qu'il l'a fait
		if report_id not in _suppressed_reports:
			_suppressed_reports.append(report_id)
			sehn_filter_triggered.emit(report_id)
		return false
	return true


## Retourne les rapports supprimés (découverts quand Varek lit les archives A3).
func get_suppressed_reports(max_act: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for report in FILTERED_REPORTS:
		if report["id"] in _suppressed_reports and report.get("act", 1) <= max_act:
			result.append(report)
	return result


## Retourne true si Varek a découvert le mécanisme de filtrage (scène A2/A3).
func _is_sehn_filtering_discovered() -> bool:
	return GSM.get_flag(36) == true  # flag 36 : SEHN_FILTERING_DISCOVERED


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE — COMPORTEMENTS
# ─────────────────────────────────────────────────────────────────────────────

## Orveth exécute un ordre que Varek a refusé (lock narratif).
func orveth_execute_order(order_id: String) -> void:
	if get_loyalty("orveth") < 20:
		return  # Orveth défecté — ne peut plus exécuter
	# L'exécution est gérée par VarekOrderSystem

## Retourne true si Lireth peut encore transmettre des informations à la résistance.
func lireth_can_defect() -> bool:
	return get_loyalty("lireth") < 30


# ─────────────────────────────────────────────────────────────────────────────
# PERSISTANCE
# ─────────────────────────────────────────────────────────────────────────────

func _load_loyalty() -> void:
	# Les valeurs par défaut sont dans ADVISORS — GSM override s'il y a une sauvegarde
	pass
