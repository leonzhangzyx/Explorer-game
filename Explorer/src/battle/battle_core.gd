class_name BattleCore
extends RefCounted

signal battle_changed
signal battle_finished(result: String)
signal log_added(message: String)

const GRID_WIDTH := 10
const GRID_HEIGHT := 8

var units: Dictionary = {}
var action_order: Array[String] = []
var active_index: int = 0
var round_number: int = 0
var phase: String = "deployment"
var result: String = ""
var rng: DeterministicRngStreams
var terrain: Dictionary = {}
var faction_morale := {"player": 0, "enemy": 0}


func _init(seed: int = 4242) -> void:
	rng = DeterministicRngStreams.new(seed)


func add_unit(unit: BattleUnit) -> bool:
	if units.has(unit.instance_id) or not is_inside_grid(unit.grid_position) or unit_at(unit.grid_position) != null:
		return false
	units[unit.instance_id] = unit
	return true


func start_battle() -> void:
	if phase != "deployment":
		return
	phase = "combat"
	start_new_round()
	_add_log("战斗开始。")
	battle_changed.emit()


func start_new_round() -> void:
	round_number += 1
	action_order.clear()
	for unit in units.values():
		if unit.is_active():
			unit.has_acted = false
			unit.has_moved = false
			unit.moved_distance = 0
			unit.can_counter = true
			unit.is_defending = false
			_tick_statuses(unit)
			_tick_cooldowns(unit)
			action_order.append(unit.instance_id)
	action_order.sort_custom(func(a: String, b: String) -> bool:
		var unit_a: BattleUnit = units[a]
		var unit_b: BattleUnit = units[b]
		return unit_a.speed > unit_b.speed if unit_a.speed != unit_b.speed else a < b
	)
	active_index = 0
	_add_log("第 %d 轮。" % round_number)


func active_unit() -> BattleUnit:
	if phase != "combat" or action_order.is_empty() or active_index >= action_order.size():
		return null
	return units.get(action_order[active_index])


func is_player_turn() -> bool:
	var unit := active_unit()
	return unit != null and unit.faction == "player"


func legal_move_cells(unit_id: String) -> Array[Vector2i]:
	var result_cells: Array[Vector2i] = []
	var unit: BattleUnit = units.get(unit_id)
	if unit == null or not unit.is_active() or unit.has_moved:
		return result_cells
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var cell := Vector2i(x, y)
			if unit_at(cell) == null and _distance(unit.grid_position, cell) <= unit.move_range and _cell_is_walkable(unit, cell):
				result_cells.append(cell)
	return result_cells


func move_active_unit(target: Vector2i) -> Dictionary:
	var unit := active_unit()
	if unit == null:
		return _failure("当前没有可行动单位。")
	if target not in legal_move_cells(unit.instance_id):
		return _failure("该位置不可到达。")
	unit.moved_distance = _distance(unit.grid_position, target)
	unit.grid_position = target
	_apply_cell_effect(unit)
	unit.has_moved = true
	_add_log("%s移动到 %s。" % [unit.display_name, _cell_name(target)])
	battle_changed.emit()
	return {"ok": true}


func attack_with_active_unit(target_id: String) -> Dictionary:
	var attacker := active_unit()
	var target: BattleUnit = units.get(target_id)
	if attacker == null or target == null or not target.is_active():
		return _failure("攻击目标无效。")
	if attacker.faction == target.faction:
		return _failure("不能攻击友军。")
	if not can_attack(attacker, target):
		return _failure("目标不在攻击范围或视线内。")
	var damage := _apply_attack(attacker, target, false)
	if target.is_active() and target.can_counter and can_attack(target, attacker):
		target.can_counter = false
		var counter_damage := _apply_attack(target, attacker, true)
		_add_log("%s反击，造成 %d 伤害。" % [target.display_name, counter_damage])
	finish_active_action()
	return {"ok": true, "damage": damage}


func preview_attack(attacker_id: String, target_id: String) -> Dictionary:
	var attacker: BattleUnit = units.get(attacker_id)
	var target: BattleUnit = units.get(target_id)
	if attacker == null or target == null or not attacker.is_active() or not target.is_active():
		return {}
	if attacker.faction == target.faction or not can_attack(attacker, target):
		return {}
	var base_damage := _base_damage(attacker, target, false)
	var minimum := maxi(1, int(round(base_damage * 0.9)))
	var maximum := maxi(1, int(round(base_damage * 1.1)))
	var counter_minimum := 0
	var counter_maximum := 0
	if target.can_counter:
		var counter_base := _base_damage(target, attacker, true)
		counter_minimum = maxi(1, int(round(counter_base * 0.9)))
		counter_maximum = maxi(1, int(round(counter_base * 1.1)))
	return {
		"damage_min": minimum,
		"damage_max": maximum,
		"counter_min": counter_minimum,
		"counter_max": counter_maximum
	}


func can_attack(attacker: BattleUnit, target: BattleUnit) -> bool:
	if attacker == null or target == null or attacker.faction == target.faction:
		return false
	var distance := _distance(attacker.grid_position, target.grid_position)
	if distance < 1 or distance > attacker.attack_range:
		return false
	if attacker.attack_range > 1 and distance == 1 and attacker.trait_id != "trait.point_blank":
		return false
	return true


func set_terrain(cell: Vector2i, terrain_type: String) -> void:
	if is_inside_grid(cell):
		terrain[_cell_key(cell)] = terrain_type


func terrain_at(cell: Vector2i) -> String:
	return str(terrain.get(_cell_key(cell), "plain"))


func use_heroic_charge(target_cell: Vector2i, target_id: String) -> Dictionary:
	var hero := active_unit()
	var target: BattleUnit = units.get(target_id)
	if hero == null or not hero.is_hero or int(hero.skill_cooldowns.get("skill.heroic_charge", 0)) > 0:
		return _failure("英勇突击当前不可用。")
	if target == null or target.faction == hero.faction or unit_at(target_cell) != null:
		return _failure("突击目标无效。")
	if _distance(target_cell, target.grid_position) != 1 or _distance(hero.grid_position, target_cell) > hero.move_range + 1:
		return _failure("无法抵达突击位置。")
	hero.moved_distance = _distance(hero.grid_position, target_cell)
	hero.grid_position = target_cell
	var original_attack := hero.attack
	hero.attack += 3
	var damage := _apply_attack(hero, target, false)
	hero.attack = original_attack
	hero.skill_cooldowns["skill.heroic_charge"] = 3
	finish_active_action()
	return {"ok": true, "damage": damage}


func use_guard_stance() -> Dictionary:
	var hero := active_unit()
	if hero == null or not hero.is_hero or int(hero.skill_cooldowns.get("skill.guard_stance", 0)) > 0:
		return _failure("守护架势当前不可用。")
	hero.add_status("status.guard_stance", 2)
	hero.is_defending = true
	hero.skill_cooldowns["skill.guard_stance"] = 3
	_add_log("英雄进入守护架势。")
	finish_active_action()
	return {"ok": true}


func use_decisive_strike(target_id: String) -> Dictionary:
	var hero := active_unit()
	var target: BattleUnit = units.get(target_id)
	if hero == null or not hero.is_hero or target == null or not can_attack(hero, target):
		return _failure("决胜一击目标无效。")
	if int(hero.skill_cooldowns.get("skill.decisive_strike", 0)) > 0:
		return _failure("决胜一击正在冷却。")
	var original_attack := hero.attack
	if target.current_health * 2 <= target.max_health:
		hero.attack += 5
	var damage := _apply_attack(hero, target, false)
	hero.attack = original_attack
	hero.skill_cooldowns["skill.decisive_strike"] = 3 if target.is_active() else 1
	finish_active_action()
	return {"ok": true, "damage": damage}


func heal_or_cleanse(caster_id: String, target_id: String) -> Dictionary:
	var caster: BattleUnit = units.get(caster_id)
	var target: BattleUnit = units.get(target_id)
	if caster == null or target == null or caster.trait_id != "trait.purifying_prayer" or caster.faction != target.faction:
		return _failure("治疗目标无效。")
	if not target.statuses.is_empty():
		var first_status: String = target.statuses.keys()[0]
		target.remove_status(first_status)
		return {"ok": true, "cleansed": first_status}
	var healed := mini(8, target.max_health - target.current_health)
	target.current_health += healed
	return {"ok": true, "healed": healed}


func push_unit(target_id: String, direction: Vector2i) -> bool:
	var target: BattleUnit = units.get(target_id)
	if target == null or not target.is_active() or target.trait_id == "trait.construct":
		return false
	var destination := target.grid_position + direction
	if direction.length_squared() != 1 or not is_inside_grid(destination) or unit_at(destination) != null or terrain_at(destination) == "blocked":
		return false
	target.grid_position = destination
	_apply_cell_effect(target)
	return true


func use_colossus_area_attack(center: Vector2i) -> Dictionary:
	var colossus := active_unit()
	if colossus == null or colossus.trait_id != "trait.astral_charge" or colossus.charge < 2:
		return _failure("星界巨像尚未完成充能。")
	if _distance(colossus.grid_position, center) > 2:
		return _failure("范围攻击目标过远。")
	var hit_ids: Array[String] = []
	for unit in units.values():
		if unit.faction != colossus.faction and unit.is_active() and _distance(unit.grid_position, center) <= 1:
			var damage := maxi(1, int(round(colossus.attack * 0.65)) - int(floor(unit.defense * 0.35)))
			unit.current_health = maxi(0, unit.current_health - damage)
			hit_ids.append(unit.instance_id)
	colossus.charge = 0
	_add_log("星界巨像释放范围冲击，命中 %d 个目标。" % hit_ids.size())
	finish_active_action()
	return {"ok": true, "hit_ids": hit_ids}


func defend_active_unit() -> Dictionary:
	var unit := active_unit()
	if unit == null:
		return _failure("当前没有可行动单位。")
	unit.is_defending = true
	_add_log("%s采取防御姿态。" % unit.display_name)
	finish_active_action()
	return {"ok": true}


func wait_active_unit() -> Dictionary:
	var unit := active_unit()
	if unit == null:
		return _failure("当前没有可行动单位。")
	_add_log("%s等待。" % unit.display_name)
	finish_active_action()
	return {"ok": true}


func perform_ai_turn() -> void:
	var unit := active_unit()
	if unit == null or unit.faction != "enemy" or phase != "combat":
		return
	var targets := living_units("player")
	if targets.is_empty():
		_check_battle_result()
		return
	targets.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool:
		var distance_a := _distance(unit.grid_position, a.grid_position)
		var distance_b := _distance(unit.grid_position, b.grid_position)
		if distance_a != distance_b:
			return distance_a < distance_b
		return (0 if a.is_hero else 1) < (0 if b.is_hero else 1)
	)
	var target: BattleUnit = targets[0]
	if _distance(unit.grid_position, target.grid_position) == 1:
		attack_with_active_unit(target.instance_id)
		return
	var best_cell := unit.grid_position
	var best_distance := _distance(best_cell, target.grid_position)
	for cell in legal_move_cells(unit.instance_id):
		var candidate_distance := _distance(cell, target.grid_position)
		if candidate_distance < best_distance:
			best_cell = cell
			best_distance = candidate_distance
	if best_cell != unit.grid_position:
		unit.grid_position = best_cell
		unit.has_moved = true
		_add_log("%s逼近%s。" % [unit.display_name, target.display_name])
		if _distance(unit.grid_position, target.grid_position) == 1:
			var damage := _apply_attack(unit, target, false)
			_add_log("%s攻击%s，造成 %d 伤害。" % [unit.display_name, target.display_name, damage])
			finish_active_action()
		else:
			defend_active_unit()
	else:
		defend_active_unit()


func finish_active_action() -> void:
	var unit := active_unit()
	if unit != null:
		unit.has_acted = true
	if _check_battle_result():
		battle_changed.emit()
		return
	active_index += 1
	while active_index < action_order.size():
		var candidate: BattleUnit = units.get(action_order[active_index])
		if candidate != null and candidate.is_active():
			break
		active_index += 1
	if active_index >= action_order.size():
		start_new_round()
	battle_changed.emit()


func living_units(faction: String) -> Array[BattleUnit]:
	var living: Array[BattleUnit] = []
	for unit in units.values():
		if unit.faction == faction and unit.is_active():
			living.append(unit)
	return living


func unit_at(cell: Vector2i) -> BattleUnit:
	for unit in units.values():
		if unit.is_active() and unit.grid_position == cell:
			return unit
	return null


func is_inside_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_WIDTH and cell.y >= 0 and cell.y < GRID_HEIGHT


func _apply_attack(attacker: BattleUnit, target: BattleUnit, is_counter: bool) -> int:
	var base_damage := _base_damage(attacker, target, is_counter)
	var roll := rng.next_int("battle", 90, 110)
	var damage := maxi(1, int(round(base_damage * roll / 100.0)))
	var guardian := _guardian_for(target)
	if guardian != null and not is_counter:
		var guarded_damage := int(ceil(damage * 0.5))
		guardian.current_health = maxi(1, guardian.current_health - guarded_damage)
		damage -= guarded_damage
		_add_log("%s替%s承担 %d 伤害。" % [guardian.display_name, target.display_name, guarded_damage])
	target.current_health = maxi(0, target.current_health - damage)
	_add_log("%s攻击%s，造成 %d 伤害。" % [attacker.display_name, target.display_name, damage])
	if target.current_health == 0:
		faction_morale[target.faction] = clampi(int(faction_morale[target.faction]) - 2, -5, 5)
		faction_morale[attacker.faction] = clampi(int(faction_morale[attacker.faction]) + 1, -5, 5)
		if target.is_hero:
			target.is_down = true
			_add_log("英雄倒地。")
		else:
			_add_log("%s被击败。" % target.display_name)
	return damage


func _base_damage(attacker: BattleUnit, target: BattleUnit, is_counter: bool) -> int:
	var effective_defense := target.defense + (4 if target.is_defending else 0)
	if target.has_status("status.guard_stance"):
		effective_defense += 3
	if _is_flanked(target):
		effective_defense -= 3
	if attacker.attack_range > 1:
		if terrain_at(target.grid_position) == "cover":
			effective_defense += 4
		if terrain_at(attacker.grid_position) == "high_ground":
			effective_defense -= 2
	var effective_attack := attacker.attack
	if attacker.trait_id == "trait.militia_cohesion":
		effective_attack += _adjacent_allies(attacker)
	if attacker.trait_id == "trait.steady_aim" and not attacker.has_moved:
		effective_attack += 2
	if attacker.trait_id == "trait.momentum":
		effective_attack += mini(attacker.moved_distance, 4)
	if attacker.trait_id == "trait.dive_attack" and attacker.moved_distance >= 3:
		effective_attack += 4
	if attacker.trait_id == "trait.astral_charge" and attacker.charge >= 2:
		effective_attack += 6
		attacker.charge = 0
	var morale_bonus := int(faction_morale.get(attacker.faction, 0))
	if attacker.trait_id == "trait.construct":
		morale_bonus = 0
	var base_damage := maxi(1, effective_attack + morale_bonus - int(floor(effective_defense * 0.5)))
	if is_counter:
		base_damage = maxi(1, int(floor(base_damage * 0.75)))
	return base_damage


func _is_flanked(target: BattleUnit) -> bool:
	var horizontal_left := unit_at(target.grid_position + Vector2i.LEFT)
	var horizontal_right := unit_at(target.grid_position + Vector2i.RIGHT)
	var vertical_up := unit_at(target.grid_position + Vector2i.UP)
	var vertical_down := unit_at(target.grid_position + Vector2i.DOWN)
	return _opposed_enemies(horizontal_left, horizontal_right, target.faction) or _opposed_enemies(vertical_up, vertical_down, target.faction)


func _opposed_enemies(first: BattleUnit, second: BattleUnit, target_faction: String) -> bool:
	return first != null and second != null and first.faction != target_faction and second.faction != target_faction


func _adjacent_allies(unit: BattleUnit) -> int:
	var count := 0
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor := unit_at(unit.grid_position + direction)
		if neighbor != null and neighbor.faction == unit.faction:
			count += 1
	return count


func _guardian_for(target: BattleUnit) -> BattleUnit:
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor := unit_at(target.grid_position + direction)
		if neighbor != null and neighbor.faction == target.faction and neighbor.trait_id == "trait.guardian":
			return neighbor
	return null


func _cell_is_walkable(unit: BattleUnit, cell: Vector2i) -> bool:
	var cell_terrain := terrain_at(cell)
	if cell_terrain == "blocked":
		return unit.trait_id == "trait.dive_attack"
	return true


func _apply_cell_effect(unit: BattleUnit) -> void:
	if terrain_at(unit.grid_position) == "hazard" and unit.trait_id != "trait.dive_attack":
		unit.current_health = maxi(1, unit.current_health - 3)
		unit.add_status("status.scorched", 2)
	if unit.trait_id == "trait.astral_charge":
		unit.charge = mini(unit.charge + 1, 2)


func _tick_statuses(unit: BattleUnit) -> void:
	var expired: Array[String] = []
	for status_id in unit.statuses:
		if status_id == "status.scorched":
			unit.current_health = maxi(1, unit.current_health - 1)
		unit.statuses[status_id] = int(unit.statuses[status_id]) - 1
		if int(unit.statuses[status_id]) <= 0:
			expired.append(status_id)
	for status_id in expired:
		unit.statuses.erase(status_id)


func _tick_cooldowns(unit: BattleUnit) -> void:
	for skill_id in unit.skill_cooldowns:
		unit.skill_cooldowns[skill_id] = maxi(0, int(unit.skill_cooldowns[skill_id]) - 1)


func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func _check_battle_result() -> bool:
	if living_units("enemy").is_empty():
		phase = "finished"
		result = "victory"
		_add_log("战斗胜利。")
		battle_finished.emit(result)
		return true
	if living_units("player").is_empty():
		phase = "finished"
		result = "defeat"
		_add_log("部队失去战斗能力。")
		battle_finished.emit(result)
		return true
	return false


func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}


func _add_log(message: String) -> void:
	log_added.emit(message)


func _distance(first: Vector2i, second: Vector2i) -> int:
	return absi(first.x - second.x) + absi(first.y - second.y)


func _cell_name(cell: Vector2i) -> String:
	return "(%d,%d)" % [cell.x + 1, cell.y + 1]
