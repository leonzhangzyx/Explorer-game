extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_test_initiative_and_movement()
	_test_attack_and_counterattack()
	_test_defend_and_wait()
	_test_hero_down_and_defeat()
	_test_victory()
	_test_deterministic_damage()
	if _failures.is_empty():
		print("BATTLE CORE TEST PASSED")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _battle(seed: int = 10) -> BattleCore:
	var battle := BattleCore.new(seed)
	battle.add_unit(BattleUnit.new("hero", "hero.test", "英雄", "player", Vector2i(1, 1), 30, 10, 6, 8, 3, true))
	battle.add_unit(BattleUnit.new("ally", "unit.militia", "民兵", "player", Vector2i(1, 3), 20, 7, 4, 5, 3))
	battle.add_unit(BattleUnit.new("enemy", "unit.militia", "敌兵", "enemy", Vector2i(3, 1), 20, 8, 4, 6, 3))
	return battle


func _test_initiative_and_movement() -> void:
	var battle := _battle()
	battle.start_battle()
	_assert_equal(battle.active_unit().instance_id, "hero", "Fastest unit acts first")
	var result := battle.move_active_unit(Vector2i(2, 1))
	_assert_true(result.get("ok", false), "Active unit can move within range")
	_assert_equal(battle.units["hero"].grid_position, Vector2i(2, 1), "Movement changes grid position")
	_assert_equal(battle.active_unit().instance_id, "hero", "Movement preserves the primary action")
	var second_move := battle.move_active_unit(Vector2i(2, 2))
	_assert_true(not second_move.get("ok", true), "Unit cannot move twice in one turn")


func _test_attack_and_counterattack() -> void:
	var battle := _battle()
	battle.units["enemy"].grid_position = Vector2i(2, 1)
	battle.start_battle()
	var hero_health: int = battle.units["hero"].current_health
	var enemy_health: int = battle.units["enemy"].current_health
	var preview := battle.preview_attack("hero", "enemy")
	_assert_true(not preview.is_empty() and preview.damage_min <= preview.damage_max, "Adjacent attack provides a damage preview")
	var result := battle.attack_with_active_unit("enemy")
	_assert_true(result.get("ok", false), "Adjacent enemy can be attacked")
	_assert_true(battle.units["enemy"].current_health < enemy_health, "Attack deals damage")
	_assert_true(battle.units["hero"].current_health < hero_health, "Living adjacent target counterattacks")
	_assert_true(not battle.units["enemy"].can_counter, "Unit only has one counterattack per round")


func _test_defend_and_wait() -> void:
	var battle := _battle()
	battle.start_battle()
	battle.defend_active_unit()
	_assert_true(battle.units["hero"].is_defending, "Defend applies defensive stance")
	if battle.active_unit().faction == "enemy":
		battle.perform_ai_turn()
	var current := battle.active_unit()
	if current != null and current.faction == "player":
		var round_before := battle.round_number
		var result := battle.wait_active_unit()
		_assert_true(result.get("ok", false), "Wait is accepted for the active unit")
		_assert_true(battle.round_number >= round_before, "Wait advances action flow without reversing the round")


func _test_hero_down_and_defeat() -> void:
	var battle := _battle()
	battle.units["hero"].current_health = 1
	battle.units["ally"].current_health = 0
	battle.units["hero"].speed = 1
	battle.start_battle()
	battle.perform_ai_turn()
	_assert_true(battle.units["hero"].is_down, "Hero enters down state at zero health")
	_assert_equal(battle.result, "defeat", "Battle is lost when all player units are inactive")


func _test_victory() -> void:
	var battle := _battle()
	battle.units["enemy"].current_health = 1
	battle.units["enemy"].grid_position = Vector2i(2, 1)
	battle.start_battle()
	battle.attack_with_active_unit("enemy")
	_assert_equal(battle.result, "victory", "Battle ends in victory when enemies are defeated")


func _test_deterministic_damage() -> void:
	var first := _battle(999)
	var second := _battle(999)
	for battle in [first, second]:
		battle.units["enemy"].grid_position = Vector2i(2, 1)
		battle.start_battle()
		battle.attack_with_active_unit("enemy")
	_assert_equal(first.units["enemy"].current_health, second.units["enemy"].current_health, "Same battle seed produces same damage")


func _assert_true(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		_failures.append("FAIL: %s" % description)


func _assert_equal(actual, expected, description: String) -> void:
	_assert_true(actual == expected, "%s | actual=%s expected=%s" % [description, actual, expected])
