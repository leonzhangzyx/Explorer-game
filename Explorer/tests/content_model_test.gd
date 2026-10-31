extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_test_valid_content()
	_test_invalid_content()
	_test_game_state_round_trip()
	_test_army_capacity()
	if _failures.is_empty():
		print("CONTENT MODEL TEST PASSED")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _test_valid_content() -> void:
	var registry := ContentRegistry.new()
	var errors := registry.load_from_file("res://data/content.json")
	_assert_true(errors.is_empty(), "MVP content validates: %s" % [errors])
	_assert_equal(registry.get_section("units").size(), 8, "Eight unit definitions exist")
	_assert_true(bool(registry.get_definition("heroes", "hero.frontier_commander").get("is_battle_unit")), "Hero is defined as battle unit")


func _test_invalid_content() -> void:
	var registry := ContentRegistry.new()
	var invalid := {
		"heroes": {"shared.id": {"max_level": 9, "is_battle_unit": false}},
		"units": {"shared.id": {"rarity": "impossible", "max_health": -1, "attack": 1, "defense": 1, "speed": 1, "capacity_cost": 0}},
		"skills": {}, "statuses": {}, "equipment": {}, "territory_levels": {},
		"events": {"event.broken": {"start_node_id": "", "nodes": []}},
		"enemies": {}, "resources": {}
	}
	var errors := registry.load_from_dictionary(invalid)
	_assert_true(not errors.is_empty(), "Invalid content is rejected")
	_assert_true(_contains_fragment(errors, "Duplicate content ID"), "Duplicate IDs are reported")
	_assert_true(_contains_fragment(errors, "must be a battle unit"), "Non-combat hero is rejected")
	_assert_true(_contains_fragment(errors, "Missing territory level"), "Missing territory levels are reported")


func _test_game_state_round_trip() -> void:
	var state := GameState.new()
	state.seed = 24680
	state.day = 3
	state.resources["resource.gold"] = 125
	state.hero.learned_skill_ids.append("skill.heroic_charge")
	state.army.stacks.append(UnitStackState.new("unit.militia", 12, 8, 100, "stack-test-1"))
	var territory := TerritoryState.new()
	territory.territory_id = "territory.greenwatch"
	territory.owner = "player"
	state.territories.append(territory)
	var encoded := JSON.stringify(state.to_dict())
	var decoded = JSON.parse_string(encoded)
	var restored := GameState.from_dict(decoded)
	_assert_equal(restored.to_dict(), state.to_dict(), "Game state round trip preserves fields")


func _test_army_capacity() -> void:
	var registry := ContentRegistry.new()
	registry.load_from_file("res://data/content.json")
	var army := ArmyState.new()
	army.stack_capacity = 2
	_assert_true(army.can_add("unit.astral_colossus", registry), "Mythic unit fits two empty capacity")
	army.stacks.append(UnitStackState.new("unit.militia", 5, 10, 100, "stack-test-2"))
	_assert_true(not army.can_add("unit.astral_colossus", registry), "Mythic unit needs two free capacity")
	_assert_true(not army.can_add("unit.unknown", registry), "Unknown unit cannot be added")


func _contains_fragment(values: Array[String], fragment: String) -> bool:
	for value in values:
		if fragment in value:
			return true
	return false


func _assert_true(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		_failures.append("FAIL: %s" % description)


func _assert_equal(actual, expected, description: String) -> void:
	_assert_true(actual == expected, "%s | actual=%s expected=%s" % [description, actual, expected])

