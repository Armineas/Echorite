extends Node
## SceneRouter — Autoload singleton (nom : "SceneRouter")
## Charge la bonne scène de jeu selon la prochaine entrée du SceneSequencer.
## Le joueur ne choisit plus le personnage — advance_scene() avance la timeline.
##
## Flux d'une transition :
##   1. La scène active signale sa fin (dialogue terminé, combat terminé…)
##   2. Elle appelle SceneRouter.advance_scene()
##   3. SceneRouter demande la prochaine entrée à SceneSequencer
##   4. Si le personnage change → change_scene vers la nouvelle scène de jeu
##   5. La nouvelle scène reçoit les infos dialogue via _receive_scene_entry()


## Scènes de jeu par mode (une par personnage + écrans communs).
const SCENE_PATHS: Dictionary = {
	"main_menu":   "res://src/ui/MainMenu.tscn",
	"timeline":    "res://src/ui/TimelineView.tscn",   # Remplace char_select
	"aldric":      "res://src/modes/aldric/AldricWorld.tscn",
	"seira":       "res://src/modes/seira/SeiraCommand.tscn",
	"varek":       "res://src/modes/varek/VarekEmpire.tscn",
	"daven":       "res://src/modes/daven/DavenStealth.tscn",
	"shared":      "res://src/modes/shared/CrossingPoint.tscn",
}

var _current_character: String = ""
var _transition_in_progress: bool = false


signal scene_changed(character: String, scene_path: String)
signal transition_started()
signal transition_ended()


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE — NAVIGATION PRINCIPALE
# ─────────────────────────────────────────────────────────────────────────────

## Point d'entrée principal. Appelé quand une scène se termine.
## Demande la prochaine entrée au SceneSequencer et charge la scène appropriée.
func advance_scene() -> void:
	if _transition_in_progress:
		return

	var entry: Dictionary = SceneSequencer.get_next()

	if entry.is_empty():
		# Plus de scènes dans l'acte courant — transition d'acte ou fin de jeu
		_handle_act_end()
		return

	var character: String = entry.get("character", "")

	if character != _current_character:
		# Changement de personnage → charger une nouvelle scène de jeu
		_current_character = character
		var path: String = SCENE_PATHS.get(character, "")
		_change_scene(path, entry)
	else:
		# Même personnage → rester dans la scène, juste changer le dialogue
		var root := get_tree().current_scene
		if root != null and root.has_method("_receive_scene_entry"):
			root._receive_scene_entry(entry)


## Démarre une nouvelle partie depuis le menu principal.
func start_new_game() -> void:
	GSM.reset()
	advance_scene()


## Charge le menu principal.
func go_to_main_menu() -> void:
	_current_character = ""
	_change_scene(SCENE_PATHS["main_menu"])


## Charge la vue de progression (timeline lisible, lecture seule).
func go_to_timeline_view() -> void:
	_change_scene(SCENE_PATHS["timeline"])


# ─────────────────────────────────────────────────────────────────────────────
# GESTION DE FIN D'ACTE
# ─────────────────────────────────────────────────────────────────────────────

func _handle_act_end() -> void:
	var act := SceneSequencer.current_act()
	if SceneSequencer.is_act_complete(act):
		if act < 3:
			# Transition vers l'acte suivant — écran interstitiel puis reprise
			_change_scene(SCENE_PATHS["timeline"], {
				"act_transition": true,
				"from_act": act,
				"to_act": act + 1
			})
		else:
			# Fin du jeu
			go_to_main_menu()


# ─────────────────────────────────────────────────────────────────────────────
# NAVIGATION INTERNE
# ─────────────────────────────────────────────────────────────────────────────

func get_current_character() -> String:
	return _current_character


## Change la scène avec fondu.
## entry : données transmises à la nouvelle scène via _receive_scene_entry()
func _change_scene(path: String, entry: Dictionary = {}) -> void:
	if path == "":
		push_error("SceneRouter : chemin de scène vide.")
		return

	_transition_in_progress = true
	transition_started.emit()

	await get_tree().process_frame

	var err: Error = get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneRouter : erreur chargement — " + path + " (code " + str(err) + ")")
		_transition_in_progress = false
		return

	if not entry.is_empty():
		await get_tree().process_frame
		var root := get_tree().current_scene
		if root != null and root.has_method("_receive_scene_entry"):
			root._receive_scene_entry(entry)

	_transition_in_progress = false
	transition_ended.emit()
	scene_changed.emit(_current_character, path)
