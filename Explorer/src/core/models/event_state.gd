class_name EventState
extends RefCounted

var event_id: String = ""
var current_node_id: String = ""
var chosen_option_ids: Array[String] = []
var flags: Dictionary = {}
var reward_claimed: bool = false


func to_dict() -> Dictionary:
	return {
		"event_id": event_id,
		"current_node_id": current_node_id,
		"chosen_option_ids": chosen_option_ids.duplicate(),
		"flags": flags.duplicate(true),
		"reward_claimed": reward_claimed
	}


static func from_dict(data: Dictionary) -> EventState:
	var event_state := EventState.new()
	event_state.event_id = str(data.get("event_id", ""))
	event_state.current_node_id = str(data.get("current_node_id", ""))
	for option_id in data.get("chosen_option_ids", []):
		event_state.chosen_option_ids.append(str(option_id))
	event_state.flags = Dictionary(data.get("flags", {})).duplicate(true)
	event_state.reward_claimed = bool(data.get("reward_claimed", false))
	return event_state

