class_name SaveGameService
extends RefCounted

const SAVE_EXTENSION := ".json"


func save_game(path: String, session: GameSession) -> Array[String]:
	var errors: Array[String] = []
	var directory_path := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(directory_path):
		var make_error := DirAccess.make_dir_recursive_absolute(directory_path)
		if make_error != OK:
			return ["Could not create save directory: %s" % error_string(make_error)]

	var temp_path := "%s.tmp" % path
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return ["Could not open temporary save file: %s" % FileAccess.get_open_error()]
	var payload := session.prepare_for_save()
	file.store_string(JSON.stringify(payload, "  "))
	file.flush()
	file.close()

	var verification_errors := _verify_file(temp_path)
	if not verification_errors.is_empty():
		DirAccess.remove_absolute(temp_path)
		return verification_errors

	if FileAccess.file_exists(path):
		var backup_path := "%s.backup" % path
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_path)
		var backup_error := DirAccess.rename_absolute(path, backup_path)
		if backup_error != OK:
			DirAccess.remove_absolute(temp_path)
			return ["Could not preserve previous save: %s" % error_string(backup_error)]

	var replace_error := DirAccess.rename_absolute(temp_path, path)
	if replace_error != OK:
		errors.append("Could not finalize save: %s" % error_string(replace_error))
	return errors


func load_game(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"errors": ["Save file does not exist: %s" % path]}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"errors": ["Could not open save file: %s" % FileAccess.get_open_error()]}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		return {"errors": ["Save file is not valid JSON data"]}
	var parsed: Dictionary = json.data
	var errors := _validate_save_data(parsed)
	if not errors.is_empty():
		return {"errors": errors}
	var state := GameState.from_dict(parsed)
	return {"errors": [], "session": GameSession.new(state)}


func list_saves(directory_path: String) -> Array[Dictionary]:
	var saves: Array[Dictionary] = []
	if not DirAccess.dir_exists_absolute(directory_path):
		return saves
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return saves
	for file_name in directory.get_files():
		if not file_name.ends_with(SAVE_EXTENSION):
			continue
		var path := directory_path.path_join(file_name)
		var file := FileAccess.open(path, FileAccess.READ)
		var json := JSON.new()
		var parsed = null
		if file != null and json.parse(file.get_as_text()) == OK:
			parsed = json.data
		if parsed is Dictionary:
			saves.append({
				"path": path,
				"file_name": file_name,
				"day": int(parsed.get("day", 0)),
				"game_version": str(parsed.get("game_version", "unknown"))
			})
	return saves


func _verify_file(path: String) -> Array[String]:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ["Could not reopen temporary save file"]
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		return ["Temporary save verification failed"]
	var parsed: Dictionary = json.data
	return _validate_save_data(parsed)


func _validate_save_data(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if int(data.get("schema_version", -1)) != GameState.SCHEMA_VERSION:
		errors.append("Unsupported save schema version")
	if str(data.get("game_version", "")).is_empty():
		errors.append("Save is missing game_version")
	if str(data.get("content_version", "")).is_empty():
		errors.append("Save is missing content_version")
	if not data.get("hero") is Dictionary:
		errors.append("Save is missing hero state")
	if not data.get("army") is Dictionary:
		errors.append("Save is missing army state")
	return errors

