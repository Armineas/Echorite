extends Node
## MusicManager — Autoload (nom : "Music")
## Gère toute la musique du jeu.
##
## Principes :
##   - 2 bus AudioStreamPlayer pour le crossfade (A et B)
##   - La track courante joue sur le bus actif ; la prochaine s'enchaîne sur l'autre
##   - Crossfade paramétrable (durée en secondes)
##   - Les tracks "event" (non-loopables) jouent sur un 3ème player dédié
##   - L'ambiance Échorite joue en couche sur un 4ème player (volume indépendant)
##   - Toutes les constantes de chemin sont centralisées ici

signal music_changed(track_id: String)
signal track_finished(track_id: String)


# ─────────────────────────────────────────────────────────────────────────────
# CATALOGUE DES TRACKS
# ─────────────────────────────────────────────────────────────────────────────

## Toutes les tracks du jeu. Ajouter ici quand un fichier .ogg est prêt.
## Les fichiers manquants sont ignorés silencieusement (pas d'erreur bloquante).
const TRACKS: Dictionary = {

	# ── Aldric ────────────────────────────────────────────────────────────────
	"aldric_a1_exploration": "res://audio/music/aldric/aldric_a1_exploration.ogg",
	"aldric_a1_combat":      "res://audio/music/aldric/aldric_a1_combat.ogg",
	"aldric_a2_tension":     "res://audio/music/aldric/aldric_a2_tension.ogg",
	"aldric_a3_deserter":    "res://audio/music/aldric/aldric_a3_deserter.ogg",
	"aldric_a3_combat":      "res://audio/music/aldric/aldric_a3_combat.ogg",

	# ── Seïra ─────────────────────────────────────────────────────────────────
	"seira_a1_planning":     "res://audio/music/seira/seira_a1_planning.ogg",
	"seira_a2_resistance":   "res://audio/music/seira/seira_a2_resistance.ogg",
	"seira_a3_coalition":    "res://audio/music/seira/seira_a3_coalition.ogg",

	# ── Varek ─────────────────────────────────────────────────────────────────
	"varek_a1_power":        "res://audio/music/varek/varek_a1_power.ogg",
	"varek_a2_doubt":        "res://audio/music/varek/varek_a2_doubt.ogg",
	"varek_a3_isolation":    "res://audio/music/varek/varek_a3_isolation.ogg",

	# ── Daven ─────────────────────────────────────────────────────────────────
	"daven_a1_cover":        "res://audio/music/daven/daven_a1_cover.ogg",
	"daven_a2_pressure":     "res://audio/music/daven/daven_a2_pressure.ogg",
	"daven_a3_unmasked":     "res://audio/music/daven/daven_a3_unmasked.ogg",

	# ── Points de Croisement ──────────────────────────────────────────────────
	"cp1_delegation":        "res://audio/music/crossing_points/cp1_delegation.ogg",
	"cp2_velshan":           "res://audio/music/crossing_points/cp2_velshan.ogg",
	"cp3_desertion":         "res://audio/music/crossing_points/cp3_desertion.ogg",
	"cp4_mine":              "res://audio/music/crossing_points/cp4_mine.ogg",

	# ── Ambiances ─────────────────────────────────────────────────────────────
	"ambient_mine_echorite":       "res://audio/music/ambient/ambient_mine_echorite.ogg",
	"ambient_camp_resistance":     "res://audio/music/ambient/ambient_camp_resistance.ogg",
	"ambient_imperial_court":      "res://audio/music/ambient/ambient_imperial_court.ogg",
	"ambient_overworld":           "res://audio/music/ambient/ambient_overworld.ogg",
	"ambient_night":               "res://audio/music/ambient/ambient_night.ogg",
	"ambient_velardane_occupe":    "res://audio/music/ambient/ambient_velardane_occupe.ogg",

	# ── Événements (non-loopables) ────────────────────────────────────────────
	"event_companion_death":  "res://audio/music/events/event_companion_death.ogg",
	"event_victory_minor":    "res://audio/music/events/event_victory_minor.ogg",
	"event_revelation":       "res://audio/music/events/event_revelation.ogg",
	"event_tension_sting":    "res://audio/music/events/event_tension_sting.ogg",
	"event_companion_joins":  "res://audio/music/events/event_companion_joins.ogg",

	# ── Menu & Transitions ────────────────────────────────────────────────────
	"menu_main":              "res://audio/music/menu/menu_main.ogg",
	"menu_act_transition":    "res://audio/music/menu/menu_act_transition.ogg",
	"menu_game_over":         "res://audio/music/menu/menu_game_over.ogg",
}

## Tracks qui ne doivent pas boucler (jouées une seule fois).
const NON_LOOP_TRACKS: Array[String] = [
	"event_companion_death",
	"event_victory_minor",
	"event_revelation",
	"event_tension_sting",
	"event_companion_joins",
	"menu_act_transition",
	"menu_game_over",
]

## Thème principal par personnage et par acte.
## Utilisé par play_character_theme() — appel automatique du SceneSequencer.
const CHARACTER_THEMES: Dictionary = {
	"aldric": {1: "aldric_a1_exploration", 2: "aldric_a2_tension", 3: "aldric_a3_deserter"},
	"seira":  {1: "seira_a1_planning",     2: "seira_a2_resistance", 3: "seira_a3_coalition"},
	"varek":  {1: "varek_a1_power",        2: "varek_a2_doubt",      3: "varek_a3_isolation"},
	"daven":  {1: "daven_a1_cover",        2: "daven_a2_pressure",   3: "daven_a3_unmasked"},
}

## Thème de combat par personnage et par acte.
const COMBAT_THEMES: Dictionary = {
	"aldric": {1: "aldric_a1_combat", 2: "aldric_a1_combat", 3: "aldric_a3_combat"},
}


# ─────────────────────────────────────────────────────────────────────────────
# ÉTAT
# ─────────────────────────────────────────────────────────────────────────────

## Durée du crossfade en secondes.
var crossfade_duration: float = 1.5

var _current_track_id: String = ""
var _active_bus: int = 0          # 0 = player_a actif, 1 = player_b actif
var _crossfade_tween: Tween = null
var _echorite_volume: float = 0.0  # 0.0 = silencieux, 1.0 = volume max ambiance

## Players Godot (créés dans _ready).
var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _player_event: AudioStreamPlayer   # events non-loopables
var _player_echorite: AudioStreamPlayer  # couche ambiance Échorite


func _ready() -> void:
	_setup_players()
	Settings.settings_changed.connect(_on_settings_changed)


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE — LECTURE
# ─────────────────────────────────────────────────────────────────────────────

## Joue une track avec crossfade. Ignorée si c'est déjà la track courante.
func play(track_id: String, fade_duration: float = crossfade_duration) -> void:
	if track_id == _current_track_id:
		return
	var path: String = TRACKS.get(track_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("MusicManager: track introuvable — %s" % track_id)
		return

	var stream: AudioStream = load(path)
	if stream == null:
		return

	var is_looping: bool = track_id not in NON_LOOP_TRACKS
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = is_looping

	_crossfade_to(stream, fade_duration)
	_current_track_id = track_id
	music_changed.emit(track_id)


## Joue immédiatement le thème du personnage actif pour l'acte courant.
func play_character_theme(character: String) -> void:
	var act: int = GSM.current_act()
	var themes: Dictionary = CHARACTER_THEMES.get(character, {})
	var track_id: String = themes.get(act, themes.get(1, ""))
	if not track_id.is_empty():
		play(track_id)


## Joue le thème de combat du personnage actif.
func play_combat_theme(character: String) -> void:
	var act: int = GSM.current_act()
	var themes: Dictionary = COMBAT_THEMES.get(character, {})
	var track_id: String = themes.get(act, "aldric_a1_combat")
	play(track_id, 0.5)  # crossfade plus court pour le combat


## Joue un événement ponctuel (non-loopable, ne coupe pas la musique principale).
## Réduit temporairement le volume principal le temps de l'event.
func play_event(track_id: String, duck_main_volume: bool = false) -> void:
	var path: String = TRACKS.get(track_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	_player_event.stream = stream
	_player_event.play()

	if duck_main_volume:
		_duck_main(0.3, _player_event.stream.get_length() + 0.5)

	_player_event.finished.connect(
		func(): track_finished.emit(track_id),
		CONNECT_ONE_SHOT
	)


## Joue l'ambiance Échorite en couche (indépendante de la musique principale).
## volume_target : 0.0 = silence, 1.0 = plein volume Échorite.
func set_echorite_ambiance(volume_target: float, fade: float = 2.0) -> void:
	if volume_target > 0.0 and not _player_echorite.playing:
		var path: String = TRACKS.get("ambient_mine_echorite", "")
		if ResourceLoader.exists(path):
			_player_echorite.stream = load(path)
			_player_echorite.volume_db = linear_to_db(0.0)
			_player_echorite.play()

	var tween: Tween = create_tween()
	tween.tween_method(
		func(v: float): _player_echorite.volume_db = linear_to_db(v * Settings.get_music_volume()),
		_echorite_volume,
		volume_target,
		fade
	)
	_echorite_volume = volume_target

	if volume_target <= 0.0:
		tween.tween_callback(_player_echorite.stop)


## Stop avec fadeout.
func stop(fade_duration: float = crossfade_duration) -> void:
	if _crossfade_tween:
		_crossfade_tween.kill()
	var active: AudioStreamPlayer = _get_active_player()
	var tween: Tween = create_tween()
	tween.tween_method(
		func(v: float): active.volume_db = linear_to_db(v),
		db_to_linear(active.volume_db),
		0.0,
		fade_duration
	)
	tween.tween_callback(active.stop)
	_current_track_id = ""


## Retourne l'id de la track en cours.
func get_current_track() -> String:
	return _current_track_id


# ─────────────────────────────────────────────────────────────────────────────
# CROSSFADE INTERNE
# ─────────────────────────────────────────────────────────────────────────────

func _crossfade_to(stream: AudioStream, duration: float) -> void:
	if _crossfade_tween:
		_crossfade_tween.kill()

	var current: AudioStreamPlayer = _get_active_player()
	var next: AudioStreamPlayer = _get_inactive_player()
	_active_bus = 1 - _active_bus

	var target_vol: float = Settings.get_music_volume()

	next.stream = stream
	next.volume_db = linear_to_db(0.0)
	next.play()

	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)
	_crossfade_tween.tween_method(
		func(v: float): current.volume_db = linear_to_db(v),
		db_to_linear(current.volume_db), 0.0, duration
	)
	_crossfade_tween.tween_method(
		func(v: float): next.volume_db = linear_to_db(v),
		0.0, target_vol, duration
	)
	_crossfade_tween.chain().tween_callback(current.stop)


## Baisse temporairement le volume principal (duck) pendant la durée donnée.
func _duck_main(target_volume: float, restore_after: float) -> void:
	var active: AudioStreamPlayer = _get_active_player()
	var original: float = db_to_linear(active.volume_db)
	var tween: Tween = create_tween()
	tween.tween_method(
		func(v: float): active.volume_db = linear_to_db(v),
		original, target_volume, 0.3
	)
	tween.tween_interval(restore_after)
	tween.tween_method(
		func(v: float): active.volume_db = linear_to_db(v),
		target_volume, original, 0.5
	)


func _get_active_player() -> AudioStreamPlayer:
	return _player_a if _active_bus == 0 else _player_b


func _get_inactive_player() -> AudioStreamPlayer:
	return _player_b if _active_bus == 0 else _player_a


# ─────────────────────────────────────────────────────────────────────────────
# SETUP
# ─────────────────────────────────────────────────────────────────────────────

func _setup_players() -> void:
	_player_a = AudioStreamPlayer.new()
	_player_a.bus = "Music"
	_player_a.name = "PlayerA"
	add_child(_player_a)

	_player_b = AudioStreamPlayer.new()
	_player_b.bus = "Music"
	_player_b.name = "PlayerB"
	add_child(_player_b)

	_player_event = AudioStreamPlayer.new()
	_player_event.bus = "Music"
	_player_event.name = "PlayerEvent"
	add_child(_player_event)

	_player_echorite = AudioStreamPlayer.new()
	_player_echorite.bus = "Music"
	_player_echorite.volume_db = linear_to_db(0.0)
	_player_echorite.name = "PlayerEchorite"
	add_child(_player_echorite)


func _on_settings_changed(key: String, value: Variant) -> void:
	if key == "music_volume":
		var vol: float = float(value)
		_get_active_player().volume_db = linear_to_db(vol)
		if _echorite_volume > 0.0:
			_player_echorite.volume_db = linear_to_db(vol * _echorite_volume)
