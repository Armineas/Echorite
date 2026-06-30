extends Node
## SettingsManager — Autoload (nom : "Settings")
## Gère les paramètres de jeu. Persistés dans user://settings.json.

signal settings_changed(key: String, value: Variant)


# ─────────────────────────────────────────────────────────────────────────────
# VALEURS PAR DÉFAUT
# ─────────────────────────────────────────────────────────────────────────────

const DEFAULTS: Dictionary = {
	"music_volume":      0.8,   # 0.0 - 1.0
	"sfx_volume":        0.9,
	"text_speed":        1.0,   # 0.5 = lent, 1.0 = normal, 2.0 = rapide, 0.0 = instantané
	"fullscreen":        false,
	"language":          "fr",
	"dialogue_log":      true,  # log narratif accessible via L
	"accessibility_high_contrast": false,
}

const SAVE_PATH: String = "user://settings.json"

var _settings: Dictionary = {}


func _ready() -> void:
	_settings = DEFAULTS.duplicate(true)
	_load()
	_apply_all()


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE
# ─────────────────────────────────────────────────────────────────────────────

func get_setting(key: String) -> Variant:
	return _settings.get(key, DEFAULTS.get(key))


func set_setting(key: String, value: Variant) -> void:
	if not DEFAULTS.has(key):
		push_warning("SettingsManager: clé inconnue — " + key)
		return
	_settings[key] = value
	_apply(key, value)
	_save()
	settings_changed.emit(key, value)


## Raccourcis typés pour les usages fréquents.

func get_music_volume() -> float:
	return float(get_setting("music_volume"))


func get_sfx_volume() -> float:
	return float(get_setting("sfx_volume"))


func get_text_speed() -> float:
	return float(get_setting("text_speed"))


func get_language() -> String:
	return str(get_setting("language"))


func is_fullscreen() -> bool:
	return bool(get_setting("fullscreen"))


## Vitesse de dialogue en secondes par caractère (pour le typewriter effect).
func chars_per_second() -> float:
	var speed: float = get_text_speed()
	if speed <= 0.0:
		return 0.0  # instantané
	return 30.0 * speed  # 30 chars/s au niveau 1.0


## Remet tous les paramètres à leur valeur par défaut.
func reset_to_defaults() -> void:
	_settings = DEFAULTS.duplicate(true)
	_apply_all()
	_save()


# ─────────────────────────────────────────────────────────────────────────────
# APPLICATION
# ─────────────────────────────────────────────────────────────────────────────

func _apply_all() -> void:
	for key in _settings:
		_apply(key, _settings[key])


func _apply(key: String, value: Variant) -> void:
	match key:
		"music_volume":
			AudioServer.set_bus_volume_db(
				AudioServer.get_bus_index("Music"),
				linear_to_db(float(value))
			)
		"sfx_volume":
			AudioServer.set_bus_volume_db(
				AudioServer.get_bus_index("SFX"),
				linear_to_db(float(value))
			)
		"fullscreen":
			if bool(value):
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


# ─────────────────────────────────────────────────────────────────────────────
# PERSISTANCE
# ─────────────────────────────────────────────────────────────────────────────

func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SettingsManager: impossible d'écrire " + SAVE_PATH)
		return
	file.store_string(JSON.stringify(_settings, "\t"))
	file.close()


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var err: int = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("SettingsManager: settings.json corrompu — valeurs par défaut utilisées.")
		return
	var loaded: Variant = json.data
	if loaded is Dictionary:
		for key in loaded:
			if DEFAULTS.has(key):
				_settings[key] = loaded[key]
