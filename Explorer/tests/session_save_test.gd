extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_test_rng_streams_are_deterministic_and_independent()
	_test_rng_restore()
	_test_mode_transitions()
	_test_safe_save_round_trip()
	_test_broken_save_is_rejected()
	if _failures.is_empty():
		print("SESSION SAVE TEST PASSED")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _test_rng_streams_are_deterministic_and_independent() -> void:
	var first := DeterministicRngStreams.new(777)
	var second := DeterministicRngStreams.new(777)
	var first_battle := first.next_int("battle", 1, 100000)
	first.next_int("loot", 1, 100000)
	var first_battle_next := first.next_int("battle", 1, 100000)
	var second_battle := second.next_int("battle", 1, 100000)
	var second_battle_next := second.next_int("battle", 1, 100000)
	_assert_equal(first_battle, second_battle, "Same seed starts the battle stream identically")
	_assert_equal(first_battle_next, second_battle_next, "Loot calls do not change battle stream")


func _test_rng_restore() -> void:
	var original := DeterministicRngStreams.new(8080)
	original.next_int("event", 1, 1000)
	var saved_states := original.save_states()
	var expected_next := original.next_int("event", 1, 1000)
	var restored := DeterministicRngStreams.new(8080)
	var errors := restored.restore_states(saved_states)
	_assert_true(errors.is_empty(), "RNG state restores without errors")
	_assert_equal(restored.next_int("event", 1, 1000), expected_next, "Restored RNG continues at the same value")


func _test_mode_transitions() -> void:
	var session := GameSession.new()
	_assert_true(session.change_mode("battle"), "World can enter battle")
	_assert_true(not session.change_mode("battle"), "Battle cannot enter battle twice")
	_assert_true(session.change_mode("world"), "Battle can return to world")
	_assert_true(not session.change_mode("invalid"), "Unknown mode is rejected")


func _test_safe_save_round_trip() -> void:
	var directory := ProjectSettings.globalize_path("user://tests/session_save")
	var path := directory.path_join("slot_1.json")
	var session := GameSession.new()
	session.state.seed = 9191
	session.rng = DeterministicRngStreams.new(session.state.seed)
	session.state.day = 5
	session.state.resources["resource.gold"] = 300
	session.rng.next_int("world", 1, 100)
	var service := SaveGameService.new()
	var save_errors := service.save_game(path, session)
	_assert_true(save_errors.is_empty(), "Game saves safely: %s" % [save_errors])
	var result := service.load_game(path)
	_assert_true(result.get("errors", []).is_empty(), "Saved game loads without errors")
	if result.has("session"):
		var restored: GameSession = result["session"]
		_assert_equal(restored.state.day, 5, "Loaded day matches")
		_assert_equal(restored.state.resources["resource.gold"], 300, "Loaded resources match")
		_assert_equal(restored.rng.next_int("world", 1, 100), session.rng.next_int("world", 1, 100), "Loaded RNG state matches")
	var listed := service.list_saves(directory)
	_assert_equal(listed.size(), 1, "Save list finds the slot")


func _test_broken_save_is_rejected() -> void:
	var path := ProjectSettings.globalize_path("user://tests/session_save/broken.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var result := SaveGameService.new().load_game(path)
	_assert_true(not result.get("errors", []).is_empty(), "Broken save is rejected")


func _assert_true(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		_failures.append("FAIL: %s" % description)


func _assert_equal(actual, expected, description: String) -> void:
	_assert_true(actual == expected, "%s | actual=%s expected=%s" % [description, actual, expected])

