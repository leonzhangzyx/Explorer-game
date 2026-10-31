extends SceneTree

var _failures: Array[String] = []
var _service: WorldMapService
var _state: GameState


func _initialize() -> void:
	_state = GameState.new()
	_service = WorldMapService.new(_state, WorldMapService.load_map_file("res://data/world_map.json"))
	_test_initial_visibility()
	_test_movement_and_costs()
	_test_insufficient_action_points()
	_test_resource_collection()
	_test_end_day()
	_test_world_state_round_trip()
	if _failures.is_empty():
		print("WORLD MAP TEST PASSED")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _test_initial_visibility() -> void:
	_assert_true(_service.is_revealed("map.starting_camp"), "Starting camp is revealed")
	_assert_true(_service.is_revealed("map.old_road"), "Neighbor of starting camp is revealed")
	_assert_true(not _service.is_revealed("map.greenwatch"), "Distant territory begins hidden")


func _test_movement_and_costs() -> void:
	var result := _service.move_to("map.old_road")
	_assert_true(result.get("ok", false), "Hero moves to an adjacent revealed node")
	_assert_equal(_state.world.action_points, 9, "Road movement costs one action point")
	var path := _service.find_path("map.forest_cache")
	_assert_equal(_service.get_path_cost(path), 2, "Forest destination costs two action points")
	result = _service.move_to("map.forest_cache")
	_assert_true(result.get("ok", false), "Hero moves into forest")
	_assert_equal(_state.world.action_points, 7, "Forest cost is applied")


func _test_insufficient_action_points() -> void:
	_state.world.action_points = 0
	var result := _service.move_to("map.old_road")
	_assert_true(not result.get("ok", true), "Movement is rejected when action points are insufficient")
	_assert_equal(_state.world.current_node_id, "map.forest_cache", "Rejected movement leaves hero in place")


func _test_resource_collection() -> void:
	var first := _service.interact_current_node()
	_assert_true(first.get("ok", false), "Resource node can be collected")
	_assert_equal(_state.resources["resource.wood"], 20, "Resource reward is granted")
	var second := _service.interact_current_node()
	_assert_true(not second.get("ok", true), "Resource cannot be collected twice")
	_assert_equal(_state.resources["resource.wood"], 20, "Duplicate interaction grants no reward")


func _test_end_day() -> void:
	_service.end_day()
	_assert_equal(_state.day, 2, "Ending day advances date once")
	_assert_equal(_state.threat, 1, "Ending day raises threat once")
	_assert_equal(_state.world.action_points, 10, "Ending day restores action points")


func _test_world_state_round_trip() -> void:
	var restored := GameState.from_dict(JSON.parse_string(JSON.stringify(_state.to_dict())))
	_assert_equal(restored.world.to_dict(), _state.world.to_dict(), "World exploration state survives save round trip")


func _assert_true(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		_failures.append("FAIL: %s" % description)


func _assert_equal(actual, expected, description: String) -> void:
	_assert_true(actual == expected, "%s | actual=%s expected=%s" % [description, actual, expected])

