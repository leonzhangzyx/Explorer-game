class_name WorldMapService
extends RefCounted

signal world_changed
signal message_emitted(message: String)

var state: GameState
var map_data: Dictionary
var _neighbors: Dictionary = {}


func _init(p_state: GameState, p_map_data: Dictionary) -> void:
	state = p_state
	map_data = p_map_data.duplicate(true)
	_build_neighbors()
	reveal_around(state.world.current_node_id)


static func load_map_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text()) if file != null else null
	return parsed if parsed is Dictionary else {}


func get_node(node_id: String) -> Dictionary:
	return Dictionary(Dictionary(map_data.get("nodes", {})).get(node_id, {})).duplicate(true)


func get_nodes() -> Dictionary:
	return Dictionary(map_data.get("nodes", {})).duplicate(true)


func get_edges() -> Array:
	return Array(map_data.get("edges", [])).duplicate(true)


func is_revealed(node_id: String) -> bool:
	return node_id in state.world.revealed_node_ids


func is_visited(node_id: String) -> bool:
	return node_id in state.world.visited_node_ids


func is_collected(node_id: String) -> bool:
	return node_id in state.world.collected_node_ids


func find_path(target_node_id: String) -> Array[String]:
	var start := state.world.current_node_id
	if target_node_id == start:
		return [start]
	if not get_nodes().has(target_node_id) or not is_revealed(target_node_id):
		return []
	var frontier: Array[String] = [start]
	var came_from: Dictionary = {start: ""}
	var costs: Dictionary = {start: 0}
	while not frontier.is_empty():
		frontier.sort_custom(func(a: String, b: String) -> bool: return int(costs[a]) < int(costs[b]))
		var current: String = frontier.pop_front()
		if current == target_node_id:
			break
		for neighbor_value in _neighbors.get(current, []):
			var neighbor := str(neighbor_value)
			if not is_revealed(neighbor):
				continue
			var new_cost: int = int(costs[current]) + get_move_cost(neighbor)
			if not costs.has(neighbor) or new_cost < int(costs[neighbor]):
				costs[neighbor] = new_cost
				came_from[neighbor] = current
				if neighbor not in frontier:
					frontier.append(neighbor)
	if not came_from.has(target_node_id):
		return []
	var path: Array[String] = []
	var cursor := target_node_id
	while not cursor.is_empty():
		path.push_front(cursor)
		cursor = str(came_from.get(cursor, ""))
	return path


func get_path_cost(path: Array[String]) -> int:
	var total := 0
	for index in range(1, path.size()):
		total += get_move_cost(path[index])
	return total


func get_move_cost(node_id: String) -> int:
	var node := get_node(node_id)
	var terrain := str(node.get("terrain", "plains"))
	return int(Dictionary(map_data.get("terrain_costs", {})).get(terrain, 1))


func move_to(target_node_id: String) -> Dictionary:
	var node := get_node(target_node_id)
	if node.is_empty():
		return {"ok": false, "message": "未知地点。"}
	if str(node.get("type", "")) == "locked":
		return {"ok": false, "message": "关口尚未开放。"}
	var path := find_path(target_node_id)
	if path.is_empty():
		return {"ok": false, "message": "当前无法到达该地点。"}
	var cost := get_path_cost(path)
	if cost > state.world.action_points:
		return {"ok": false, "message": "行动点不足，需要 %d 点。" % cost, "cost": cost}
	state.world.action_points -= cost
	state.world.current_node_id = target_node_id
	if target_node_id not in state.world.visited_node_ids:
		state.world.visited_node_ids.append(target_node_id)
	reveal_around(target_node_id)
	world_changed.emit()
	return {"ok": true, "message": "到达%s，消耗 %d 行动点。" % [node.get("name", target_node_id), cost], "cost": cost}


func interact_current_node() -> Dictionary:
	var node_id := state.world.current_node_id
	var node := get_node(node_id)
	match str(node.get("type", "path")):
		"resource":
			if is_collected(node_id):
				return {"ok": false, "message": "这里的资源已经采集。"}
			for resource_id in Dictionary(node.get("reward", {})):
				state.resources[resource_id] = int(state.resources.get(resource_id, 0)) + int(node["reward"][resource_id])
			state.world.collected_node_ids.append(node_id)
			world_changed.emit()
			return {"ok": true, "message": "采集完成：木材 +20。"}
		"encounter":
			return {"ok": true, "message": "叛军拒绝让路，准备战斗。", "action": "battle"}
		"territory":
			return {"ok": true, "message": "发现绿望前哨。领地占领将在经济阶段接入。"}
		"event":
			return {"ok": true, "message": "山丘祭坛的事件将在事件阶段接入。"}
		_:
			return {"ok": false, "message": str(node.get("description", "这里没有可执行的交互。"))}


func end_day() -> void:
	state.day += 1
	state.threat += 1
	state.world.action_points = WorldState.MAX_ACTION_POINTS
	world_changed.emit()
	message_emitted.emit("第 %d 天开始。行动点已恢复，区域威胁上升。" % state.day)


func reveal_around(node_id: String) -> void:
	_add_unique(state.world.revealed_node_ids, node_id)
	_add_unique(state.world.discovered_node_ids, node_id)
	for neighbor in _neighbors.get(node_id, []):
		_add_unique(state.world.revealed_node_ids, neighbor)
		_add_unique(state.world.discovered_node_ids, neighbor)


func _build_neighbors() -> void:
	_neighbors.clear()
	for node_id in get_nodes():
		_neighbors[node_id] = []
	for edge in get_edges():
		if edge.size() != 2:
			continue
		var first := str(edge[0])
		var second := str(edge[1])
		_neighbors[first].append(second)
		_neighbors[second].append(first)


func _add_unique(values: Array[String], value: String) -> void:
	if value not in values:
		values.append(value)
