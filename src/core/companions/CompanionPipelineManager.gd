extends Node
## CompanionPipelineManager — Autoload (nom : "CPM")
## Valide et orchestre le pipeline de disponibilité des compagnons.
##
## Pipeline complet pour qu'un compagnon rejoigne Aldric :
##   1. Daven protège ou signale la personne  (flag narratif)
##   2. Seïra investit les ressources (SRM.recruit)
##   3. Aldric rencontre le compagnon (scène déclenchée, GSM.complete_scene)
##
## Ce manager observe GSM et SRM pour détecter les changements d'état
## et signaler quand une nouvelle scène de rencontre devient disponible.

signal companion_encounter_ready(companion_id: String, scene_path: String, scene_id: String)
signal pipeline_state_changed(companion_id: String, stage: int)


# ─────────────────────────────────────────────────────────────────────────────
# DÉFINITIONS DU PIPELINE
# ─────────────────────────────────────────────────────────────────────────────
#
# Chaque compagnon a 3 étapes dans son pipeline.
# "daven_flag"  : flag GSM que Daven doit avoir posé (0 = pas de condition Daven)
# "seira_flag"  : flag posé par SRM.recruit() via GSM.recruit_companion()
# "aldric_scene": scène de rencontre dans le mode Aldric (déclenchée par SceneRouter)
#
const PIPELINES: Dictionary = {
	"brennan": {
		"daven_flag":   0,           # pas de condition Daven
		"aldric_scene": {"path": "acte1/aldric_a1.dialogue.json", "scene_id": "aldric_a1_s4_brennan"},
		"act":          1,
	},
	"lyria": {
		"daven_flag":   31,          # DAVEN_WARNED_LYRIA
		"aldric_scene": {"path": "companions/lyria_encounter.dialogue.json", "scene_id": "lyria_rencontre_aldric"},
		"act":          2,
	},
	"cain": {
		"daven_flag":   0,
		"aldric_scene": {"path": "acte2/aldric_a2.dialogue.json", "scene_id": "aldric_a2_s3_cain_rencontre"},
		"act":          2,
	},
	"mira": {
		"daven_flag":   0,           # MIRA_PROTECTED est le flag de Daven (flag 0), vérifié via SRM
		"aldric_scene": {"path": "companions/mira_encounter.dialogue.json", "scene_id": "mira_rencontre_aldric"},
		"act":          2,
	},
	"rael": {
		"daven_flag":   0,
		"aldric_scene": {"path": "companions/rael_encounter.dialogue.json", "scene_id": "rael_rencontre_aldric"},
		"act":          2,
	},
	"thessa": {
		"daven_flag":   0,
		"aldric_scene": {"path": "companions/thessa_encounter.dialogue.json", "scene_id": "thessa_rencontre_aldric"},
		"act":          2,
	},
	"orwen": {
		"daven_flag":   0,
		"aldric_scene": {"path": "companions/orwen_encounter.dialogue.json", "scene_id": "orwen_rencontre_aldric"},
		"act":          2,
	},
	"kira": {
		"daven_flag":   32,          # DAVEN_EXTRACTED_KIRA
		"aldric_scene": {"path": "companions/kira_encounter.dialogue.json", "scene_id": "kira_rencontre_aldric"},
		"act":          3,
	},
	"brand": {
		"daven_flag":   0,
		"aldric_scene": {"path": "companions/brand_encounter.dialogue.json", "scene_id": "brand_rencontre_aldric"},
		"act":          2,
	},
}


# ─────────────────────────────────────────────────────────────────────────────
# ÉTAT
# ─────────────────────────────────────────────────────────────────────────────

## Étapes : 0 = bloqué, 1 = Daven OK, 2 = Seïra OK (recruté), 3 = Aldric rencontré
var _pipeline_stages: Dictionary = {}


func _ready() -> void:
	_refresh_all()
	if GSM.has_signal("flag_changed"):
		GSM.flag_changed.connect(_on_flag_changed)
	if SRM.has_signal("recruitment_unlocked"):
		SRM.recruitment_unlocked.connect(_on_companion_recruited)


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE
# ─────────────────────────────────────────────────────────────────────────────

## Retourne l'étape courante du pipeline (0-3).
func get_stage(companion_id: String) -> int:
	return _pipeline_stages.get(companion_id, 0)


## Retourne true si le compagnon est prêt pour la rencontre avec Aldric.
func is_encounter_ready(companion_id: String) -> bool:
	return get_stage(companion_id) == 2


## Liste des compagnons prêts pour rencontrer Aldric dans l'acte courant.
func ready_encounters(act: int) -> Array[String]:
	var result: Array[String] = []
	for cid in PIPELINES:
		var pipeline: Dictionary = PIPELINES[cid]
		if pipeline.get("act", 1) <= act and is_encounter_ready(cid):
			result.append(cid)
	return result


## Appelé quand Aldric termine la scène de rencontre avec un compagnon.
func mark_encounter_done(companion_id: String) -> void:
	_pipeline_stages[companion_id] = 3
	pipeline_state_changed.emit(companion_id, 3)


# ─────────────────────────────────────────────────────────────────────────────
# LOGIQUE INTERNE
# ─────────────────────────────────────────────────────────────────────────────

func _refresh_all() -> void:
	for cid in PIPELINES:
		_update_stage(cid)


func _update_stage(companion_id: String) -> void:
	var pipeline: Dictionary = PIPELINES.get(companion_id, {})
	if pipeline.is_empty():
		return

	var old_stage: int = _pipeline_stages.get(companion_id, 0)
	var new_stage: int = _compute_stage(companion_id, pipeline)

	if new_stage != old_stage:
		_pipeline_stages[companion_id] = new_stage
		pipeline_state_changed.emit(companion_id, new_stage)
		if new_stage == 2:
			var scene_data: Dictionary = pipeline.get("aldric_scene", {})
			companion_encounter_ready.emit(companion_id, scene_data.get("path", ""), scene_data.get("scene_id", ""))


func _compute_stage(cid: String, pipeline: Dictionary) -> int:
	# Étape 3 : rencontre déjà faite
	if GSM.is_companion_recruited(cid) and GSM.is_scene_done("aldric", pipeline.get("act", 1), cid + "_met"):
		return 3

	# Étape 2 : Seïra a recruté → prêt pour rencontre Aldric
	if GSM.is_companion_recruited(cid):
		return 2

	# Étape 1 : Daven a rempli sa condition
	var daven_flag: int = pipeline.get("daven_flag", 0)
	if daven_flag == 0 or GSM.get_flag(daven_flag) == true:
		return 1

	return 0


func _on_flag_changed(_flag_index: int, _value: Variant) -> void:
	_refresh_all()


func _on_companion_recruited(companion_id: String) -> void:
	_update_stage(companion_id)
