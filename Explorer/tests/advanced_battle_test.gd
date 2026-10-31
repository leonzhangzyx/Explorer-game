extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_test_ranged_cover_and_high_ground()
	_test_flanking()
	_test_hazard_status_and_cleanse()
	_test_morale_and_construct_immunity()
	_test_hero_skills()
	_test_unit_traits()
	_test_guardian_push_dive_and_area_traits()
	if _failures.is_empty():
		print("ADVANCED BATTLE TEST PASSED")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _test_ranged_cover_and_high_ground() -> void:
	var plain := _ranged_battle(12)
	plain.start_battle()
	var plain_preview := plain.preview_attack("ranger", "enemy")
	var covered := _ranged_battle(12)
	covered.set_terrain(Vector2i(5, 1), "cover")
	covered.start_battle()
	var cover_preview := covered.preview_attack("ranger", "enemy")
	_assert_true(plain_preview.damage_max > cover_preview.damage_max, "Cover reduces ranged damage")
	var high := _ranged_battle(12)
	high.set_terrain(Vector2i(1, 1), "high_ground")
	high.start_battle()
	var high_preview := high.preview_attack("ranger", "enemy")
	_assert_true(high_preview.damage_max > plain_preview.damage_max, "High ground increases ranged damage")


func _test_flanking() -> void:
	var battle := BattleCore.new(2)
	battle.add_unit(BattleUnit.new("left", "unit.militia", "左翼", "player", Vector2i(2, 3), 20, 8, 4, 8, 2))
	battle.add_unit(BattleUnit.new("right", "unit.militia", "右翼", "player", Vector2i(4, 3), 20, 8, 4, 5, 2))
	battle.add_unit(BattleUnit.new("enemy", "unit.shield_guard", "敌卫", "enemy", Vector2i(3, 3), 30, 8, 10, 2, 2))
	battle.start_battle()
	var preview := battle.preview_attack("left", "enemy")
	_assert_true(preview.damage_min >= 4, "Opposite adjacent allies create a flanking defense penalty")


func _test_hazard_status_and_cleanse() -> void:
	var battle := BattleCore.new(3)
	var priest := BattleUnit.new("priest", "unit.priest", "祭司", "player", Vector2i(1, 1), 20, 4, 4, 8, 3, false, 1, "trait.purifying_prayer")
	var ally := BattleUnit.new("ally", "unit.militia", "民兵", "player", Vector2i(1, 2), 20, 7, 4, 6, 3)
	battle.add_unit(priest)
	battle.add_unit(ally)
	battle.add_unit(BattleUnit.new("enemy", "unit.militia", "敌兵", "enemy", Vector2i(7, 7), 20, 7, 4, 1, 2))
	battle.set_terrain(Vector2i(2, 2), "hazard")
	battle.start_battle()
	if battle.active_unit().instance_id == "priest":
		battle.wait_active_unit()
	battle.move_active_unit(Vector2i(2, 2))
	_assert_true(ally.has_status("status.scorched"), "Hazard applies a timed status")
	var cleanse := battle.heal_or_cleanse("priest", "ally")
	_assert_true(cleanse.get("ok", false) and not ally.has_status("status.scorched"), "Priest cleanses a status")


func _test_morale_and_construct_immunity() -> void:
	var battle := BattleCore.new(4)
	battle.faction_morale["player"] = 3
	var militia := BattleUnit.new("militia", "unit.militia", "民兵", "player", Vector2i(1, 1), 20, 8, 4, 8, 2)
	var golem := BattleUnit.new("golem", "unit.war_golem", "傀儡", "player", Vector2i(1, 3), 20, 8, 4, 7, 2, false, 1, "trait.construct")
	var enemy := BattleUnit.new("enemy", "unit.militia", "敌兵", "enemy", Vector2i(2, 1), 30, 5, 4, 2, 2)
	battle.add_unit(militia)
	battle.add_unit(golem)
	battle.add_unit(enemy)
	battle.start_battle()
	var militia_preview := battle.preview_attack("militia", "enemy")
	militia.has_acted = true
	battle.active_index = 1
	enemy.grid_position = Vector2i(2, 3)
	var golem_preview := battle.preview_attack("golem", "enemy")
	_assert_true(militia_preview.damage_max > golem_preview.damage_max, "Construct ignores positive morale while normal units receive it")


func _test_hero_skills() -> void:
	var battle := BattleCore.new(5)
	var hero := BattleUnit.new("hero", "hero.frontier", "英雄", "player", Vector2i(1, 1), 30, 10, 6, 9, 3, true)
	var enemy := BattleUnit.new("enemy", "unit.militia", "敌兵", "enemy", Vector2i(4, 1), 12, 6, 4, 2, 2)
	battle.add_unit(hero)
	battle.add_unit(enemy)
	battle.start_battle()
	var charge := battle.use_heroic_charge(Vector2i(3, 1), "enemy")
	_assert_true(charge.get("ok", false), "Heroic charge moves and attacks")
	_assert_true(int(hero.skill_cooldowns.get("skill.heroic_charge", 0)) > 0, "Heroic charge starts cooldown")

	var guard_battle := BattleCore.new(6)
	var guard_hero := BattleUnit.new("hero", "hero.frontier", "英雄", "player", Vector2i(1, 1), 30, 10, 6, 9, 3, true)
	guard_battle.add_unit(guard_hero)
	guard_battle.add_unit(BattleUnit.new("enemy", "unit.militia", "敌兵", "enemy", Vector2i(5, 1), 30, 6, 4, 2, 2))
	guard_battle.start_battle()
	_assert_true(guard_battle.use_guard_stance().get("ok", false) and guard_hero.has_status("status.guard_stance"), "Guard stance applies protection")

	var strike_battle := BattleCore.new(7)
	var strike_hero := BattleUnit.new("hero", "hero.frontier", "英雄", "player", Vector2i(1, 1), 30, 12, 6, 9, 3, true)
	var weak_enemy := BattleUnit.new("enemy", "unit.militia", "敌兵", "enemy", Vector2i(2, 1), 20, 6, 4, 2, 2)
	weak_enemy.current_health = 5
	strike_battle.add_unit(strike_hero)
	strike_battle.add_unit(weak_enemy)
	strike_battle.start_battle()
	_assert_true(strike_battle.use_decisive_strike("enemy").get("ok", false), "Decisive strike executes a wounded target")


func _test_unit_traits() -> void:
	var trait_ids := [
		"trait.militia_cohesion", "trait.guardian", "trait.steady_aim", "trait.momentum",
		"trait.purifying_prayer", "trait.construct", "trait.dive_attack", "trait.astral_charge"
	]
	_assert_equal(trait_ids.size(), 8, "All eight MVP unit trait hooks are represented")
	var colossus := BattleUnit.new("colossus", "unit.astral_colossus", "巨像", "player", Vector2i(1, 1), 60, 18, 14, 2, 2, false, 1, "trait.astral_charge")
	var battle := BattleCore.new(8)
	battle.add_unit(colossus)
	battle.add_unit(BattleUnit.new("enemy", "unit.militia", "敌兵", "enemy", Vector2i(8, 7), 20, 5, 4, 1, 2))
	battle.start_battle()
	battle.move_active_unit(Vector2i(2, 1))
	_assert_equal(colossus.charge, 1, "Astral colossus gains charge by moving")


func _test_guardian_push_dive_and_area_traits() -> void:
	var guard_battle := BattleCore.new(20)
	var attacker := BattleUnit.new("attacker", "unit.militia", "敌兵", "enemy", Vector2i(3, 2), 30, 12, 4, 9, 2)
	var ally := BattleUnit.new("ally", "unit.militia", "民兵", "player", Vector2i(2, 2), 20, 7, 4, 4, 2)
	var guardian := BattleUnit.new("guardian", "unit.shield_guard", "盾卫", "player", Vector2i(2, 3), 30, 6, 10, 3, 2, false, 1, "trait.guardian")
	guard_battle.add_unit(attacker)
	guard_battle.add_unit(ally)
	guard_battle.add_unit(guardian)
	guard_battle.start_battle()
	var ally_before := ally.current_health
	guard_battle.attack_with_active_unit("ally")
	_assert_true(guardian.current_health < guardian.max_health and ally.current_health > ally_before - 8, "Shield guard shares adjacent ally damage")

	var push_battle := BattleCore.new(21)
	var golem := BattleUnit.new("golem", "unit.war_golem", "傀儡", "enemy", Vector2i(4, 4), 30, 8, 8, 2, 2, false, 1, "trait.construct")
	var normal := BattleUnit.new("normal", "unit.militia", "民兵", "enemy", Vector2i(4, 2), 20, 7, 4, 2, 2)
	push_battle.add_unit(golem)
	push_battle.add_unit(normal)
	_assert_true(not push_battle.push_unit("golem", Vector2i.RIGHT), "War golem is immune to forced movement")
	_assert_true(push_battle.push_unit("normal", Vector2i.RIGHT), "Normal unit can be pushed")

	var dive_plain := BattleCore.new(22)
	var griffin_plain := BattleUnit.new("griffin", "unit.griffin_knight", "狮鹫", "player", Vector2i(1, 1), 25, 10, 6, 9, 5, false, 1, "trait.dive_attack")
	var target_plain := BattleUnit.new("target", "unit.militia", "目标", "enemy", Vector2i(2, 1), 30, 5, 6, 2, 2)
	dive_plain.add_unit(griffin_plain)
	dive_plain.add_unit(target_plain)
	dive_plain.start_battle()
	var plain_preview := dive_plain.preview_attack("griffin", "target")
	griffin_plain.moved_distance = 4
	var dive_preview := dive_plain.preview_attack("griffin", "target")
	_assert_true(dive_preview.damage_max > plain_preview.damage_max, "Griffin gains damage after a long dive")

	var area_battle := BattleCore.new(23)
	var colossus := BattleUnit.new("colossus", "unit.astral_colossus", "巨像", "player", Vector2i(2, 2), 60, 18, 14, 9, 2, false, 1, "trait.astral_charge")
	colossus.charge = 2
	area_battle.add_unit(colossus)
	area_battle.add_unit(BattleUnit.new("enemy_a", "unit.militia", "敌甲", "enemy", Vector2i(4, 2), 20, 5, 4, 2, 2))
	area_battle.add_unit(BattleUnit.new("enemy_b", "unit.militia", "敌乙", "enemy", Vector2i(4, 3), 20, 5, 4, 1, 2))
	area_battle.start_battle()
	var area_result := area_battle.use_colossus_area_attack(Vector2i(4, 2))
	_assert_equal(area_result.get("hit_ids", []).size(), 2, "Astral colossus charged attack hits an area")


func _ranged_battle(seed: int) -> BattleCore:
	var battle := BattleCore.new(seed)
	battle.add_unit(BattleUnit.new("ranger", "unit.ranger", "游侠", "player", Vector2i(1, 1), 18, 10, 3, 8, 3, false, 6, "trait.steady_aim"))
	battle.add_unit(BattleUnit.new("enemy", "unit.militia", "敌兵", "enemy", Vector2i(5, 1), 25, 6, 6, 2, 2))
	return battle


func _assert_true(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		_failures.append("FAIL: %s" % description)


func _assert_equal(actual, expected, description: String) -> void:
	_assert_true(actual == expected, "%s | actual=%s expected=%s" % [description, actual, expected])
