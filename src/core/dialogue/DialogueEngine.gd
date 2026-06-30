extends Node
## DialogueEngine — Autoload singleton (P0, tâche #5)
## Moteur de dialogue : affichage, choix, conditions sur flags GSM.
## Ajouter dans Project > Project Settings > Autoload avec le nom "DialogueEngine".
##
## Format des fichiers de dialogue :  design/dialogues/**/*.dialogue.json
## Voir DialogueResource.gd pour le format complet.


signal dialogue_started(dialogue_id: String)
signal line_displayed(speaker: String, text: String, is_internal: bool)
signal description_displayed(text: String)   # intertitle sans locuteur
signal choice_presented(choices: Array)
signal dialogue_ended(dialogue_id: String)
signal flag_triggered(flag: int)  # NarrativeFlag int


# ─────────────────────────────────────────────────────────────────────────────
# ÉTAT INTERNE
# ─────────────────────────────────────────────────────────────────────────────

var current_language: String = "fr"   # langue active — changer via set_language()

var _current_dialogue: Dictionary = {}
var _current_node_id: String = ""
var _is_running: bool = false
var _dialogue_cache: Dictionary = {}  # path → Dictionary chargé


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE
# ─────────────────────────────────────────────────────────────────────────────

## Démarre un dialogue depuis un fichier JSON.
## dialogue_path : chemin relatif depuis res://design/dialogues/
## scene_id      : si le fichier contient plusieurs scènes sous "scenes", spécifier laquelle
## entry_node    : nœud de départ dans la scène (défaut "start")
func start(dialogue_path: String, scene_id: String = "", entry_node: String = "start") -> void:
	assert(not _is_running, "DialogueEngine : un dialogue est déjà en cours.")

	var data := _load_dialogue(dialogue_path)
	if data.is_empty():
		push_error("DialogueEngine : impossible de charger " + dialogue_path)
		return

	# Support du format multi-scènes { "scenes": { "scene_id": { "nodes": {...} } } }
	if scene_id != "" and data.has("scenes"):
		var scene_data: Dictionary = data["scenes"].get(scene_id, {})
		if scene_data.is_empty():
			push_error("DialogueEngine : scène introuvable — " + scene_id + " dans " + dialogue_path)
			return
		_current_dialogue = scene_data
	else:
		_current_dialogue = data

	_is_running = true
	dialogue_started.emit(_current_dialogue.get("id", scene_id if scene_id != "" else dialogue_path))
	_go_to_node(entry_node)


## Avance après une ligne de dialogue (appelé par l'UI quand le joueur confirme).
func advance() -> void:
	if not _is_running:
		return
	var node: Dictionary = _get_current_node()
	if node.is_empty():
		_end_dialogue()
		return

	var node_type: String = node.get("type", "line")
	if node_type == "line":
		var next: String = node.get("next", "")
		if next == "" or next == "end":
			_end_dialogue()
		else:
			_go_to_node(next)


## Sélectionne un choix (index dans le tableau choices du nœud courant).
func select_choice(index: int) -> void:
	if not _is_running:
		return
	var node: Dictionary = _get_current_node()
	var choices: Array = node.get("choices", [])
	assert(index >= 0 and index < choices.size(), "Indice de choix invalide.")

	var choice: Dictionary = choices[index]
	_apply_node_effects(choice)

	var next: String = choice.get("next", "end")
	if next == "end":
		_end_dialogue()
	else:
		_go_to_node(next)


func is_running() -> bool:
	return _is_running


## Change la langue active. Les dialogues déjà en cache se mettront à jour au prochain affichage.
func set_language(lang: String) -> void:
	current_language = lang


# ─────────────────────────────────────────────────────────────────────────────
# NAVIGATION INTERNE
# ─────────────────────────────────────────────────────────────────────────────

func _go_to_node(node_id: String) -> void:
	_current_node_id = node_id
	var node: Dictionary = _get_current_node()

	if node.is_empty():
		push_error("DialogueEngine : nœud introuvable — " + node_id)
		_end_dialogue()
		return

	# Vérifier la condition d'accès au nœud
	if not _check_condition(node.get("condition", {})):
		var fallback: String = node.get("condition_fail_next", "end")
		if fallback == "end":
			_end_dialogue()
		else:
			_go_to_node(fallback)
		return

	# Appliquer les effets du nœud (set_flag, etc.)
	_apply_node_effects(node)

	var node_type: String = node.get("type", "line")
	match node_type:
		"line":
			_display_line(node)
		"description":
			_display_description(node)
		"choice":
			_present_choices(node)
		"auto":
			var next: String = node.get("next", "end")
			if next == "end":
				_end_dialogue()
			else:
				_go_to_node(next)
		_:
			push_warning("DialogueEngine : type de nœud inconnu — " + node_type)
			_end_dialogue()


func _display_line(node: Dictionary) -> void:
	var speaker: String = node.get("speaker", "")
	var text: String = _resolve_text(node.get("text", ""))
	var is_internal: bool = node.get("internal", false)
	line_displayed.emit(speaker, text, is_internal)


## Intertitle sans locuteur — action visible, ambiance, établissement de scène.
func _display_description(node: Dictionary) -> void:
	var text: String = _resolve_text(node.get("text", ""))
	description_displayed.emit(text)


func _present_choices(node: Dictionary) -> void:
	var raw_choices: Array = node.get("choices", [])
	var visible_choices: Array = []

	for choice in raw_choices:
		if _check_condition(choice.get("condition", {})):
			visible_choices.append({
				"text": _resolve_text(choice.get("text", "")),
				"index": raw_choices.find(choice),
			})

	# Toujours au moins un choix visible
	assert(visible_choices.size() > 0, "DialogueEngine : aucun choix visible — vérifier les conditions.")
	choice_presented.emit(visible_choices)


func _end_dialogue() -> void:
	var did: String = _current_dialogue.get("id", "")
	_is_running = false
	_current_dialogue = {}
	_current_node_id = ""
	dialogue_ended.emit(did)


func _get_current_node() -> Dictionary:
	var nodes: Dictionary = _current_dialogue.get("nodes", {})
	return nodes.get(_current_node_id, {})


# ─────────────────────────────────────────────────────────────────────────────
# CONDITIONS ET EFFETS
# ─────────────────────────────────────────────────────────────────────────────

## Évalue une condition. Retourne true si la condition est vide (pas de condition).
## Format : { "flag": <int NarrativeFlag>, "value": true/false }
##       ou { "all": [...], "any": [...] }
func _check_condition(cond: Dictionary) -> bool:
	if cond.is_empty():
		return true

	if cond.has("flag"):
		var expected: bool = cond.get("value", true)
		return GSM.get_flag(cond["flag"]) == expected

	if cond.has("companion_status"):
		var cid: String = cond["companion_status"]
		var expected_status = cond.get("status", GSM.CompanionStatus.RECRUITED)
		return GSM.get_companion_status(cid) == expected_status

	if cond.has("all"):
		for sub in cond["all"]:
			if not _check_condition(sub):
				return false
		return true

	if cond.has("any"):
		for sub in cond["any"]:
			if _check_condition(sub):
				return true
		return false

	push_warning("DialogueEngine : condition de format inconnu : " + str(cond))
	return true


## Applique les effets d'un nœud (set_flag, complete_scene…).
func _apply_node_effects(node: Dictionary) -> void:
	var effects: Array = node.get("effects", [])
	for effect in effects:
		_apply_effect(effect)


func _apply_effect(effect: Dictionary) -> void:
	match effect.get("type", ""):
		"set_flag":
			var flag: int = effect.get("flag", -1)
			var value: bool = effect.get("value", true)
			if flag >= 0:
				GSM.set_flag(flag, value)
				flag_triggered.emit(flag)
		"complete_scene":
			GSM.complete_scene(
				effect.get("character", ""),
				effect.get("act", 1),
				effect.get("scene_id", "")
			)
		"kill_companion":
			GSM.kill_companion(
				effect.get("companion_id", ""),
				effect.get("scene_id", ""),
				effect.get("act", -1)
			)
		"recruit_companion":
			GSM.aldric_recruits(
				effect.get("companion_id", ""),
				effect.get("act", 1)
			)
		"seira_prepares_companion":
			GSM.seira_prepares_companion(effect.get("companion_id", ""))
		_:
			push_warning("DialogueEngine : effet inconnu — " + str(effect))


# ─────────────────────────────────────────────────────────────────────────────
# RÉSOLUTION DE TEXTE (variables inline)
# ─────────────────────────────────────────────────────────────────────────────

## Résout le texte : supporte les strings simples ET les dicts multilingues.
## Format dict : { "fr": "...", "en": "..." }
## Fallback : "fr" si la langue active n'existe pas, "" si aucune clé valide.
func _resolve_text(raw) -> String:
	var text: String
	if raw is Dictionary:
		text = raw.get(current_language, raw.get("fr", ""))
	else:
		text = str(raw)
	# Réservé pour variables dynamiques {NOM} si besoin futur.
	return text


# ─────────────────────────────────────────────────────────────────────────────
# CHARGEMENT DES FICHIERS
# ─────────────────────────────────────────────────────────────────────────────

func _load_dialogue(path: String) -> Dictionary:
	if path in _dialogue_cache:
		return _dialogue_cache[path]

	var full_path: String = "res://design/dialogues/" + path
	if not FileAccess.file_exists(full_path):
		push_error("DialogueEngine : fichier introuvable — " + full_path)
		return {}

	var file := FileAccess.open(full_path, FileAccess.READ)
	if file == null:
		return {}

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("DialogueEngine : JSON invalide — " + full_path)
		file.close()
		return {}

	file.close()
	var data: Dictionary = json.get_data()
	_dialogue_cache[path] = data
	return data


## Vide le cache (utile en dev pour recharger les dialogues sans redémarrer).
func clear_cache() -> void:
	_dialogue_cache.clear()
