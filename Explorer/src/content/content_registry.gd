class_name ContentRegistry
extends RefCounted

const REQUIRED_SECTIONS: Array[String] = [
	"heroes", "units", "skills", "statuses", "equipment", "territory_levels", "events", "enemies", "resources"
]

var _definitions: Dictionary = {}


func load_from_file(path: String) -> Array[String]:
	if not FileAccess.file_exists(path):
		return ["Content file does not exist: %s" % path]
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ["Content file cannot be opened: %s" % path]
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return ["Content root must be a dictionary: %s" % path]
	_definitions = parsed
	return validate()


func load_from_dictionary(data: Dictionary) -> Array[String]:
	_definitions = data.duplicate(true)
	return validate()


func get_definition(section: String, definition_id: String) -> Dictionary:
	var section_data: Dictionary = _definitions.get(section, {})
	return Dictionary(section_data.get(definition_id, {})).duplicate(true)


func has_definition(section: String, definition_id: String) -> bool:
	var section_data: Dictionary = _definitions.get(section, {})
	return section_data.has(definition_id)


func get_section(section: String) -> Dictionary:
	return Dictionary(_definitions.get(section, {})).duplicate(true)


func validate() -> Array[String]:
	var errors: Array[String] = []
	for section in REQUIRED_SECTIONS:
		if not _definitions.has(section) or not _definitions[section] is Dictionary:
			errors.append("Missing or invalid content section: %s" % section)
	_validate_definition_ids(errors)
	_validate_units(errors)
	_validate_heroes(errors)
	_validate_territory_levels(errors)
	_validate_events(errors)
	return errors


func _validate_definition_ids(errors: Array[String]) -> void:
	var all_ids: Dictionary = {}
	for section in _definitions:
		if not _definitions[section] is Dictionary:
			continue
		for definition_id in _definitions[section]:
			if str(definition_id).is_empty():
				errors.append("Empty content ID in section %s" % section)
			if all_ids.has(definition_id):
				errors.append("Duplicate content ID %s in %s and %s" % [definition_id, all_ids[definition_id], section])
			else:
				all_ids[definition_id] = section


func _validate_units(errors: Array[String]) -> void:
	for unit_id in get_section("units"):
		var unit := get_definition("units", unit_id)
		for field in ["max_health", "attack", "defense", "speed", "capacity_cost"]:
			if int(unit.get(field, -1)) < 0:
				errors.append("Unit %s has invalid %s" % [unit_id, field])
		if int(unit.get("capacity_cost", 0)) < 1:
			errors.append("Unit %s must use at least one army capacity" % unit_id)
		if str(unit.get("rarity", "")) not in ["common", "rare", "legendary", "mythic"]:
			errors.append("Unit %s has invalid rarity" % unit_id)


func _validate_heroes(errors: Array[String]) -> void:
	for hero_id in get_section("heroes"):
		var hero := get_definition("heroes", hero_id)
		if int(hero.get("max_level", 0)) != 10:
			errors.append("Hero %s must have MVP max_level 10" % hero_id)
		if not bool(hero.get("is_battle_unit", false)):
			errors.append("Hero %s must be a battle unit" % hero_id)


func _validate_territory_levels(errors: Array[String]) -> void:
	for level_id in ["territory.level.1", "territory.level.2", "territory.level.3"]:
		if not has_definition("territory_levels", level_id):
			errors.append("Missing territory level definition: %s" % level_id)


func _validate_events(errors: Array[String]) -> void:
	for event_id in get_section("events"):
		var event_definition := get_definition("events", event_id)
		if str(event_definition.get("start_node_id", "")).is_empty():
			errors.append("Event %s has no start node" % event_id)
		var nodes: Array = event_definition.get("nodes", [])
		if nodes.is_empty():
			errors.append("Event %s has no reachable nodes" % event_id)

