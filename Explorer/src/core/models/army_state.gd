class_name ArmyState
extends RefCounted

var stack_capacity: int = 4
var morale: int = 0
var supply: int = 100
var stacks: Array[UnitStackState] = []


func used_capacity(registry: ContentRegistry) -> int:
	var total := 0
	for stack in stacks:
		var definition := registry.get_definition("units", stack.unit_id)
		total += int(definition.get("capacity_cost", 1))
	return total


func can_add(unit_id: String, registry: ContentRegistry) -> bool:
	var definition := registry.get_definition("units", unit_id)
	if definition.is_empty():
		return false
	return used_capacity(registry) + int(definition.get("capacity_cost", 1)) <= stack_capacity


func to_dict() -> Dictionary:
	var serialized_stacks: Array[Dictionary] = []
	for stack in stacks:
		serialized_stacks.append(stack.to_dict())
	return {
		"stack_capacity": stack_capacity,
		"morale": morale,
		"supply": supply,
		"stacks": serialized_stacks
	}


static func from_dict(data: Dictionary) -> ArmyState:
	var army := ArmyState.new()
	army.stack_capacity = int(data.get("stack_capacity", 4))
	army.morale = int(data.get("morale", 0))
	army.supply = int(data.get("supply", 100))
	for stack_data in data.get("stacks", []):
		army.stacks.append(UnitStackState.from_dict(stack_data))
	return army

