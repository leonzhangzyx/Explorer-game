class_name WorldState
extends RefCounted

const MAX_ACTION_POINTS := 10

var current_node_id: String = "map.starting_camp"
var action_points: int = MAX_ACTION_POINTS
var discovered_node_ids: Array[String] = ["map.starting_camp"]
var visited_node_ids: Array[String] = ["map.starting_camp"]
var collected_node_ids: Array[String] = []
var revealed_node_ids: Array[String] = ["map.starting_camp"]


func to_dict() -> Dictionary:
	return {
		"current_node_id": current_node_id,
		"action_points": action_points,
		"discovered_node_ids": discovered_node_ids.duplicate(),
		"visited_node_ids": visited_node_ids.duplicate(),
		"collected_node_ids": collected_node_ids.duplicate(),
		"revealed_node_ids": revealed_node_ids.duplicate()
	}


static func from_dict(data: Dictionary) -> WorldState:
	var world := WorldState.new()
	world.current_node_id = str(data.get("current_node_id", "map.starting_camp"))
	world.action_points = int(data.get("action_points", MAX_ACTION_POINTS))
	world.discovered_node_ids = _string_array(data.get("discovered_node_ids", [world.current_node_id]))
	world.visited_node_ids = _string_array(data.get("visited_node_ids", [world.current_node_id]))
	world.collected_node_ids = _string_array(data.get("collected_node_ids", []))
	world.revealed_node_ids = _string_array(data.get("revealed_node_ids", [world.current_node_id]))
	return world


static func _string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	return result
