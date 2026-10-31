class_name UnitStackState
extends RefCounted

var instance_id: String
var unit_id: String
var quantity: int
var current_member_health: int
var loyalty: int
var status_ids: Array[String]


func _init(
	p_unit_id: String = "",
	p_quantity: int = 1,
	p_current_member_health: int = 1,
	p_loyalty: int = 100,
	p_instance_id: String = ""
) -> void:
	instance_id = p_instance_id if not p_instance_id.is_empty() else _new_instance_id()
	unit_id = p_unit_id
	quantity = p_quantity
	current_member_health = p_current_member_health
	loyalty = p_loyalty
	status_ids = []


func to_dict() -> Dictionary:
	return {
		"instance_id": instance_id,
		"unit_id": unit_id,
		"quantity": quantity,
		"current_member_health": current_member_health,
		"loyalty": loyalty,
		"status_ids": status_ids.duplicate()
	}


static func from_dict(data: Dictionary) -> UnitStackState:
	var stack := UnitStackState.new(
		str(data.get("unit_id", "")),
		int(data.get("quantity", 0)),
		int(data.get("current_member_health", 0)),
		int(data.get("loyalty", 100)),
		str(data.get("instance_id", ""))
	)
	for status_id in data.get("status_ids", []):
		stack.status_ids.append(str(status_id))
	return stack


static func _new_instance_id() -> String:
	return "stack-%s" % Time.get_ticks_usec()

