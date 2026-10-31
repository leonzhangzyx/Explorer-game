extends Control

const NODE_COLORS := {
	"camp": Color("68a675"),
	"path": Color("81909b"),
	"resource": Color("62a35c"),
	"encounter": Color("ba684f"),
	"territory": Color("cfaa4a"),
	"event": Color("8867bd"),
	"locked": Color("4e5660")
}

const ART_ROOT := "res://assets/vendor/ancient_isometric_tiles_v1/Isometric tileset/tile_images/"
const LOCATION_ART := {
	"camp": ART_ROOT + "clutter/tent.png",
	"path": ART_ROOT + "clutter/signpost.png",
	"resource": ART_ROOT + "nature/tree2.png",
	"encounter": ART_ROOT + "reference/characters/adventurer.png",
	"territory": ART_ROOT + "castle/turret2b.png",
	"event": ART_ROOT + "clutter/altar_stone.png",
	"locked": ART_ROOT + "castle/arch2/wall_e.png"
}

@onready var map_canvas: Control = $MapPanel/MapCanvas
@onready var day_label: Label = $Header/HeaderMargin/HeaderRow/Day
@onready var action_label: Label = $Header/HeaderMargin/HeaderRow/ActionPoints
@onready var threat_label: Label = $Header/HeaderMargin/HeaderRow/Threat
@onready var resources_label: Label = $Header/HeaderMargin/HeaderRow/Resources
@onready var location_title: Label = $Sidebar/SidebarMargin/SidebarContent/LocationTitle
@onready var location_description: Label = $Sidebar/SidebarMargin/SidebarContent/LocationDescription
@onready var route_info: Label = $Sidebar/SidebarMargin/SidebarContent/RouteInfo
@onready var move_button: Button = $Sidebar/SidebarMargin/SidebarContent/MoveButton
@onready var interact_button: Button = $Sidebar/SidebarMargin/SidebarContent/InteractButton
@onready var end_day_button: Button = $Sidebar/SidebarMargin/SidebarContent/EndDayButton
@onready var message_label: Label = $Sidebar/SidebarMargin/SidebarContent/Message

var game_state := GameState.new()
var service: WorldMapService
var selected_node_id: String = ""
var _node_buttons: Dictionary = {}
var _location_sprites: Dictionary = {}
var _hero_sprite: Sprite2D
var _connections: WorldConnections


func _ready() -> void:
	_apply_visual_theme()
	game_state.seed = 20261027
	game_state.resources["resource.gold"] = 100
	service = WorldMapService.new(game_state, WorldMapService.load_map_file("res://data/world_map.json"))
	service.world_changed.connect(_refresh_all)
	service.message_emitted.connect(_show_message)
	move_button.pressed.connect(_on_move_pressed)
	interact_button.pressed.connect(_on_interact_pressed)
	end_day_button.pressed.connect(_on_end_day_pressed)
	_build_map()
	_select_node(game_state.world.current_node_id)
	_refresh_all()


func _apply_visual_theme() -> void:
	var header_style := _panel_style(Color("171a17e8"), Color("8b7444"), 2, 0)
	$Header.add_theme_stylebox_override("panel", header_style)
	var sidebar_style := _panel_style(Color("191b18f2"), Color("9a7a3e"), 2, 12)
	$Sidebar.add_theme_stylebox_override("panel", sidebar_style)
	var map_style := _panel_style(Color("252b22"), Color("62583c"), 3, 8)
	$MapPanel.add_theme_stylebox_override("panel", map_style)
	for button in [move_button, interact_button, end_day_button]:
		button.add_theme_stylebox_override("normal", _button_style(Color("363226"), Color("8c7441")))
		button.add_theme_stylebox_override("hover", _button_style(Color("55482e"), Color("d0aa58")))
		button.add_theme_stylebox_override("pressed", _button_style(Color("28251e"), Color("f0c969")))
		button.add_theme_stylebox_override("disabled", _button_style(Color("222521"), Color("4b4b40")))
		button.add_theme_color_override("font_color", Color("f2e3bd"))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_disabled_color", Color("77776c"))
	$Header/HeaderMargin/HeaderRow/Title.add_theme_color_override("font_color", Color("e8ca7a"))
	location_title.add_theme_color_override("font_color", Color("e8ca7a"))
	$Sidebar/SidebarMargin/SidebarContent/HeroTitle.add_theme_color_override("font_color", Color("d9ba6b"))


func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 8
	return style


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 4
	return style


func _build_map() -> void:
	for child in map_canvas.get_children():
		child.queue_free()
	_node_buttons.clear()
	_location_sprites.clear()
	_build_isometric_backdrop()
	_connections = WorldConnections.new()
	_connections.name = "Connections"
	_connections.map_data = service.map_data
	_connections.world_state = game_state.world
	_connections.selected_path = []
	map_canvas.add_child(_connections)
	for node_id in service.get_nodes():
		var node := service.get_node(node_id)
		var button := Button.new()
		button.name = node_id.replace(".", "_")
		button.text = str(node.get("name", node_id))
		button.tooltip_text = str(node.get("description", ""))
		button.custom_minimum_size = Vector2(138, 34)
		var position_data: Array = node.get("position", [0, 0])
		var node_position := Vector2(float(position_data[0]), float(position_data[1]))
		button.position = node_position + Vector2(-69, 42)
		button.flat = true
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color("ead9b0"))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.pressed.connect(_select_node.bind(node_id))
		map_canvas.add_child(button)
		_node_buttons[node_id] = button
		var marker := _make_art_sprite(str(LOCATION_ART.get(str(node.get("type", "path")), ART_ROOT + "clutter/signpost.png")), node_position)
		marker.z_index = int(node_position.y)
		map_canvas.add_child(marker)
		_location_sprites[node_id] = marker
	_build_hero_marker()


func _build_isometric_backdrop() -> void:
	var backdrop := Node2D.new()
	backdrop.name = "IsometricBackdrop"
	backdrop.z_index = -1000
	map_canvas.add_child(backdrop)
	var grass := load(ART_ROOT + "ground/grasstile1.png") as Texture2D
	for row in range(7):
		for column in range(10):
			var tile := Sprite2D.new()
			tile.texture = grass
			tile.scale = Vector2(0.72, 0.72)
			tile.modulate = Color(0.72, 0.72, 0.62)
			tile.position = Vector2(110 + column * 128 + (row % 2) * 64, 120 + row * 62)
			backdrop.add_child(tile)
	var scenery := [
		[ART_ROOT + "nature/tree3.png", Vector2(90, 170), 0.48],
		[ART_ROOT + "nature/tree2.png", Vector2(230, 210), 0.42],
		[ART_ROOT + "nature/tree3.png", Vector2(450, 185), 0.44],
		[ART_ROOT + "nature/tree2.png", Vector2(620, 180), 0.38],
		[ART_ROOT + "nature/tree3.png", Vector2(845, 215), 0.42],
		[ART_ROOT + "nature/tree2.png", Vector2(1030, 190), 0.38],
		[ART_ROOT + "nature/tree2.png", Vector2(300, 690), 0.35],
		[ART_ROOT + "nature/tree3.png", Vector2(1040, 680), 0.40]
	]
	for item in scenery:
		var sprite := _make_art_sprite(str(item[0]), item[1], float(item[2]))
		sprite.modulate = Color(0.62, 0.66, 0.55)
		sprite.z_index = int(sprite.position.y) - 200
		backdrop.add_child(sprite)


func _make_art_sprite(path: String, at: Vector2, target_scale: float = 0.48) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path) as Texture2D
	sprite.position = at
	var max_side := maxf(float(sprite.texture.get_width()), float(sprite.texture.get_height())) if sprite.texture else 1.0
	var normalized := 150.0 / max_side
	sprite.scale = Vector2.ONE * normalized * target_scale / 0.48
	return sprite


func _build_hero_marker() -> void:
	_hero_sprite = _make_art_sprite(ART_ROOT + "reference/characters/wanderer.png", Vector2.ZERO, 0.46)
	_hero_sprite.name = "Hero"
	_hero_sprite.modulate = Color("fff1ba")
	map_canvas.add_child(_hero_sprite)
	_update_hero_marker()


func _update_hero_marker() -> void:
	if _hero_sprite == null or service == null:
		return
	var current := service.get_node(game_state.world.current_node_id)
	var position_data: Array = current.get("position", [0, 0])
	_hero_sprite.position = Vector2(float(position_data[0]), float(position_data[1])) + Vector2(-38, -20)
	_hero_sprite.z_index = int(_hero_sprite.position.y) + 20


func _refresh_all() -> void:
	day_label.text = "第 %d 天" % game_state.day
	action_label.text = "行动点 %d / %d" % [game_state.world.action_points, WorldState.MAX_ACTION_POINTS]
	threat_label.text = "威胁 %d" % game_state.threat
	resources_label.text = "金币 %d  木材 %d  矿石 %d  精华 %d" % [
		game_state.resources.get("resource.gold", 0),
		game_state.resources.get("resource.wood", 0),
		game_state.resources.get("resource.ore", 0),
		game_state.resources.get("resource.arcane_essence", 0)
	]
	for node_id in _node_buttons:
		var button: Button = _node_buttons[node_id]
		var marker: Sprite2D = _location_sprites.get(node_id)
		var revealed := service.is_revealed(node_id)
		button.visible = revealed
		if marker:
			marker.visible = revealed
		if not revealed:
			continue
		var node := service.get_node(node_id)
		var node_type := str(node.get("type", "path"))
		var color: Color = NODE_COLORS.get(node_type, Color.GRAY)
		if node_id == game_state.world.current_node_id:
			button.modulate = Color.WHITE
			button.text = "◆ %s" % node.get("name", node_id)
		elif service.is_collected(node_id):
			button.modulate = color.darkened(0.45)
			button.text = "✓ %s" % node.get("name", node_id)
		else:
			button.modulate = color
			button.text = str(node.get("name", node_id))
		if marker:
			marker.modulate = Color.WHITE if node_id == game_state.world.current_node_id else Color(0.78, 0.78, 0.72)
	_update_hero_marker()
	if _connections:
		_connections.world_state = game_state.world
		_connections.queue_redraw()
	_select_node(selected_node_id if not selected_node_id.is_empty() else game_state.world.current_node_id)


func _select_node(node_id: String) -> void:
	if not service.is_revealed(node_id):
		return
	selected_node_id = node_id
	for marker_id in _location_sprites:
		var location_marker: Sprite2D = _location_sprites[marker_id]
		location_marker.modulate = Color(0.78, 0.78, 0.72)
		if marker_id == node_id:
			location_marker.modulate = Color("fff1b2")
	var node := service.get_node(node_id)
	location_title.text = str(node.get("name", node_id))
	location_description.text = str(node.get("description", ""))
	var path := service.find_path(node_id)
	if _connections:
		_connections.selected_path = path
		_connections.queue_redraw()
	if node_id == game_state.world.current_node_id:
		route_info.text = "当前位置 · %s地形" % _terrain_name(str(node.get("terrain", "plains")))
		move_button.disabled = true
		interact_button.disabled = false
	else:
		var cost := service.get_path_cost(path) if not path.is_empty() else 0
		route_info.text = "路线 %d 段 · 需要 %d 行动点" % [maxi(path.size() - 1, 0), cost] if not path.is_empty() else "当前无法到达"
		move_button.disabled = path.is_empty() or cost > game_state.world.action_points or str(node.get("type", "")) == "locked"
		interact_button.disabled = true


func _on_move_pressed() -> void:
	var old_position := _hero_sprite.position if _hero_sprite else Vector2.ZERO
	var result := service.move_to(selected_node_id)
	_show_message(str(result.get("message", "")))
	if bool(result.get("ok", false)):
		if _hero_sprite:
			var destination := _hero_sprite.position
			_hero_sprite.position = old_position
			var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(_hero_sprite, "position", destination, 0.65)
			tween.parallel().tween_property(_hero_sprite, "scale", _hero_sprite.scale * 1.12, 0.3)
			tween.tween_property(_hero_sprite, "scale", _hero_sprite.scale, 0.3)
		_select_node(selected_node_id)


func _on_interact_pressed() -> void:
	var result := service.interact_current_node()
	_show_message(str(result.get("message", "")))
	if str(result.get("action", "")) == "battle":
		get_tree().change_scene_to_file("res://src/battle/battle.tscn")


func _on_end_day_pressed() -> void:
	service.end_day()


func _show_message(message: String) -> void:
	message_label.text = message


func _terrain_name(terrain: String) -> String:
	return {"road": "道路", "plains": "平原", "forest": "森林", "difficult": "困难"}.get(terrain, terrain)


class WorldConnections extends Control:
	var map_data: Dictionary
	var world_state: WorldState
	var selected_path: Array = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		if world_state == null:
			return
		var nodes: Dictionary = map_data.get("nodes", {})
		for edge in map_data.get("edges", []):
			var first := str(edge[0])
			var second := str(edge[1])
			if first not in world_state.revealed_node_ids or second not in world_state.revealed_node_ids:
				continue
			var first_position: Array = nodes[first].get("position", [0, 0])
			var second_position: Array = nodes[second].get("position", [0, 0])
			var from := Vector2(first_position[0], first_position[1])
			var to := Vector2(second_position[0], second_position[1])
			draw_line(from, to, Color(0.08, 0.09, 0.07, 0.9), 13.0, true)
			draw_line(from, to, Color(0.42, 0.42, 0.34, 0.95), 7.0, true)
		for index in range(selected_path.size() - 1):
			var first := str(selected_path[index])
			var second := str(selected_path[index + 1])
			if first not in nodes or second not in nodes:
				continue
			var first_position: Array = nodes[first].get("position", [0, 0])
			var second_position: Array = nodes[second].get("position", [0, 0])
			draw_line(Vector2(first_position[0], first_position[1]), Vector2(second_position[0], second_position[1]), Color(0.92, 0.72, 0.25, 0.95), 4.0, true)
		var current: Dictionary = nodes.get(world_state.current_node_id, {})
		var current_position: Array = current.get("position", [0, 0])
		draw_arc(Vector2(current_position[0], current_position[1]), 48.0, 0.0, TAU, 48, Color(0.98, 0.82, 0.38, 0.85), 4.0, true)

