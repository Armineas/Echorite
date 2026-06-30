extends Node
## SaveSystem — Autoload singleton (P0, tâche #3)
## Sauvegarde et chargement de l'état du jeu via JSON.
## Ajouter dans Project > Project Settings > Autoload avec le nom "SaveSystem".


const SAVE_PATH: String = "user://save_slot_1.json"
const SAVE_VERSION: int = 1


signal save_completed()
signal load_completed(success: bool)


# ─────────────────────────────────────────────────────────────────────────────
# SAUVEGARDE
# ─────────────────────────────────────────────────────────────────────────────

## Sauvegarde l'état complet du jeu.
func save() -> void:
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_state": GSM.to_dict(),
	}

	var json_string: String = JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("SaveSystem : impossible d'ouvrir le fichier de sauvegarde en écriture.")
		return

	file.store_string(json_string)
	file.close()
	save_completed.emit()


# ─────────────────────────────────────────────────────────────────────────────
# CHARGEMENT
# ─────────────────────────────────────────────────────────────────────────────

## Charge la sauvegarde. Retourne true si succès.
func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		load_completed.emit(false)
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveSystem : impossible d'ouvrir le fichier de sauvegarde en lecture.")
		load_completed.emit(false)
		return false

	var content: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var err: Error = json.parse(content)
	if err != OK:
		push_error("SaveSystem : JSON invalide — " + json.get_error_message())
		load_completed.emit(false)
		return false

	var data: Dictionary = json.get_data()

	if not _validate_save(data):
		push_error("SaveSystem : fichier de sauvegarde incompatible (version trop ancienne ?).")
		load_completed.emit(false)
		return false

	GSM.from_dict(data.get("game_state", {}))
	load_completed.emit(true)
	return true


## Retourne true si une sauvegarde existe.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Supprime la sauvegarde (nouveau run / reset).
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


# ─────────────────────────────────────────────────────────────────────────────
# VALIDATION
# ─────────────────────────────────────────────────────────────────────────────

func _validate_save(data: Dictionary) -> bool:
	if not data.has("version"):
		return false
	if data["version"] > SAVE_VERSION:
		push_warning("SaveSystem : version de sauvegarde plus récente que le jeu (%d > %d)." \
			% [data["version"], SAVE_VERSION])
	return data.has("game_state")


# ─────────────────────────────────────────────────────────────────────────────
# MÉTADONNÉES (pour l'écran de sélection de sauvegarde)
# ─────────────────────────────────────────────────────────────────────────────

## Retourne les métadonnées de la sauvegarde sans charger l'état complet.
func get_save_metadata() -> Dictionary:
	if not has_save():
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return {}

	file.close()
	var data: Dictionary = json.get_data()
	return {
		"timestamp": data.get("timestamp", 0),
		"current_act": data.get("game_state", {}).get("current_act", 1),
	}
