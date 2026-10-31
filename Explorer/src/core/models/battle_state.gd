class_name BattleState
extends RefCounted

var battle_id: String = ""
var round_number: int = 1
var active_unit_instance_id: String = ""
var action_order: Array[String] = []
var unit_snapshots: Array[Dictionary] = []
var objective_ids: Array[String] = []
var log_entries: Array[String] = []


func to_dict() -> Dictionary:
	return {
		"battle_id": battle_id,
		"round_number": round_number,
		"active_unit_instance_id": active_unit_instance_id,
		"action_order": action_order.duplicate(),
		"unit_snapshots": unit_snapshots.duplicate(true),
		"objective_ids": objective_ids.duplicate(),
		"log_entries": log_entries.duplicate()
	}


static func from_dict(data: Dictionary) -> BattleState:
	var battle := BattleState.new()
	battle.battle_id = str(data.get("battle_id", ""))
	battle.round_number = int(data.get("round_number", 1))
	battle.active_unit_instance_id = str(data.get("active_unit_instance_id", ""))
	for value in data.get("action_order", []):
		battle.action_order.append(str(value))
	battle.unit_snapshots = Array(data.get("unit_snapshots", [])).duplicate(true)
	for value in data.get("objective_ids", []):
		battle.objective_ids.append(str(value))
	for value in data.get("log_entries", []):
		battle.log_entries.append(str(value))
	return battle

