extends Control

const CELL_SIZE := Vector2(82, 70)

@onready var grid: GridContainer = $GridPanel/GridMargin/Grid
@onready var round_label: Label = $Top/TopMargin/TopRow/Round
@onready var active_label: Label = $Top/TopMargin/TopRow/Active
@onready var unit_info: Label = $Sidebar/SideMargin/SideContent/UnitInfo
@onready var start_button: Button = $Sidebar/SideMargin/SideContent/StartButton
@onready var defend_button: Button = $Sidebar/SideMargin/SideContent/DefendButton
@onready var wait_button: Button = $Sidebar/SideMargin/SideContent/WaitButton
@onready var hint_label: Label = $Sidebar/SideMargin/SideContent/Hint
@onready var log_label: RichTextLabel = $Sidebar/SideMargin/SideContent/Log
@onready var return_button: Button = $Sidebar/SideMargin/SideContent/ReturnButton

var battle := BattleCore.new(20261027)
var selected_unit_id: String = ""
var cells: Array[Button] = []


func _ready() -> void:
	_create_units()
	_create_grid()
	battle.battle_changed.connect(_on_battle_changed)
	battle.log_added.connect(_append_log)
	battle.battle_finished.connect(_on_battle_finished)
	start_button.pressed.connect(_on_start_pressed)
	defend_button.pressed.connect(func() -> void: battle.defend_active_unit(); _continue_ai())
	wait_button.pressed.connect(func() -> void: battle.wait_active_unit(); _continue_ai())
	return_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://src/world/world_map.tscn"))
	_refresh()


func _create_units() -> void:
	battle.add_unit(BattleUnit.new("hero", "hero.frontier_commander", "英雄", "player", Vector2i(1, 3), 36, 11, 8, 7, 3, true))
	battle.add_unit(BattleUnit.new("militia", "unit.militia", "民兵", "player", Vector2i(0, 2), 24, 8, 5, 5, 3))
	battle.add_unit(BattleUnit.new("shield", "unit.shield_guard", "盾卫", "player", Vector2i(0, 5), 32, 7, 10, 3, 2))
	battle.add_unit(BattleUnit.new("rebel_a", "unit.militia", "叛军甲", "enemy", Vector2i(8, 2), 22, 8, 5, 5, 3))
	battle.add_unit(BattleUnit.new("rebel_b", "unit.militia", "叛军乙", "enemy", Vector2i(8, 5), 22, 8, 5, 4, 3))
	battle.add_unit(BattleUnit.new("captain", "unit.shield_guard", "叛军队长", "enemy", Vector2i(9, 3), 30, 9, 8, 6, 2))


func _create_grid() -> void:
	for y in range(BattleCore.GRID_HEIGHT):
		for x in range(BattleCore.GRID_WIDTH):
			var button := Button.new()
			button.custom_minimum_size = CELL_SIZE
			button.focus_mode = Control.FOCUS_NONE
			button.pressed.connect(_on_cell_pressed.bind(Vector2i(x, y)))
			button.mouse_entered.connect(_on_cell_hovered.bind(Vector2i(x, y)))
			grid.add_child(button)
			cells.append(button)


func _on_start_pressed() -> void:
	battle.start_battle()
	selected_unit_id = ""
	_continue_ai()


func _on_cell_pressed(cell: Vector2i) -> void:
	var clicked := battle.unit_at(cell)
	if battle.phase == "deployment":
		if clicked != null and clicked.faction == "player":
			selected_unit_id = clicked.instance_id
		elif not selected_unit_id.is_empty() and clicked == null and cell.x <= 2:
			var selected: BattleUnit = battle.units[selected_unit_id]
			selected.grid_position = cell
		_refresh()
		return
	if battle.phase != "combat" or not battle.is_player_turn():
		return
	if clicked != null and clicked.faction == "enemy":
		var attack_result := battle.attack_with_active_unit(clicked.instance_id)
		if not attack_result.get("ok", false):
			hint_label.text = str(attack_result.get("message", "无法攻击。"))
		else:
			_continue_ai()
	elif clicked == null:
		var move_result := battle.move_active_unit(cell)
		if not move_result.get("ok", false):
			hint_label.text = str(move_result.get("message", "无法移动。"))
		else:
			_refresh()
	else:
		selected_unit_id = clicked.instance_id
		_refresh()


func _on_cell_hovered(cell: Vector2i) -> void:
	if battle.phase != "combat" or not battle.is_player_turn():
		return
	var target := battle.unit_at(cell)
	var active := battle.active_unit()
	if target == null or active == null or target.faction == active.faction:
		return
	var preview := battle.preview_attack(active.instance_id, target.instance_id)
	if preview.is_empty():
		return
	hint_label.text = "预计伤害 %d–%d；可能反击 %d–%d。点击敌人确认攻击。" % [preview.damage_min, preview.damage_max, preview.counter_min, preview.counter_max]


func _continue_ai() -> void:
	while battle.phase == "combat" and not battle.is_player_turn():
		battle.perform_ai_turn()
	_refresh()


func _on_battle_changed() -> void:
	_refresh()


func _on_battle_finished(_result: String) -> void:
	_refresh()


func _refresh() -> void:
	for y in range(BattleCore.GRID_HEIGHT):
		for x in range(BattleCore.GRID_WIDTH):
			var cell := Vector2i(x, y)
			var button := cells[y * BattleCore.GRID_WIDTH + x]
			var unit := battle.unit_at(cell)
			button.text = ""
			button.modulate = Color("718092") if (x + y) % 2 == 0 else Color("606e7f")
			if battle.phase == "deployment" and x <= 2:
				button.modulate = Color("536f67")
			if unit != null:
				button.text = "%s\n%d/%d" % [unit.display_name, unit.current_health, unit.max_health]
				button.modulate = Color("5f93c8") if unit.faction == "player" else Color("bd665b")
				if unit.instance_id == selected_unit_id or (battle.active_unit() == unit and battle.phase == "combat"):
					button.modulate = Color("e3c55d")
	if battle.phase == "deployment":
		round_label.text = "部署阶段"
		active_label.text = "调整我方部署"
		start_button.visible = true
		defend_button.disabled = true
		wait_button.disabled = true
	elif battle.phase == "combat":
		var active := battle.active_unit()
		round_label.text = "第 %d 轮" % battle.round_number
		active_label.text = "行动：%s" % (active.display_name if active != null else "-")
		start_button.visible = false
		defend_button.disabled = not battle.is_player_turn()
		wait_button.disabled = not battle.is_player_turn()
		hint_label.text = "我方回合：点击空格移动，点击相邻敌人攻击。" if battle.is_player_turn() else "敌方正在行动。"
	else:
		round_label.text = "战斗结束"
		active_label.text = "胜利" if battle.result == "victory" else "失败"
		start_button.visible = false
		defend_button.disabled = true
		wait_button.disabled = true
		return_button.visible = true
		hint_label.text = "英雄将在战后结算阶段恢复。" if battle.result == "victory" else "所有我方单位失去战斗能力。"
	var info_unit: BattleUnit = battle.units.get(selected_unit_id)
	if info_unit == null:
		info_unit = battle.active_unit()
	unit_info.text = "%s%s" % [
		("英雄单位\n" if info_unit != null and info_unit.is_hero else "战斗单位\n"),
		("%s  生命 %d/%d\n攻击 %d  防御 %d  速度 %d" % [info_unit.display_name, info_unit.current_health, info_unit.max_health, info_unit.attack, info_unit.defense, info_unit.speed] if info_unit != null else "选择单位查看属性")
	]


func _append_log(message: String) -> void:
	log_label.append_text("%s\n" % message)
