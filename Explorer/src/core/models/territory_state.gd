class_name TerritoryState
extends RefCounted

var territory_id: String = ""
var owner: String = "neutral"
var level: int = 1
var facility_ids: Array[String] = []
var recruit_pool: Dictionary = {}
var garrison: Array[UnitStackState] = []


func to_dict() -> Dictionary:
	var serialized_garrison: Array[Dictionary] = []
	for stack in garrison:
		serialized_garrison.append(stack.to_dict())
	return {
		"territory_id": territory_id,
		"owner": owner,
		"level": level,
		"facility_ids": facility_ids.duplicate(),
		"recruit_pool": recruit_pool.duplicate(true),
		"garrison": serialized_garrison
	}


static func from_dict(data: Dictionary) -> TerritoryState:
	var territory := TerritoryState.new()
	territory.territory_id = str(data.get("territory_id", ""))
	territory.owner = str(data.get("owner", "neutral"))
	territory.level = int(data.get("level", 1))
	for facility_id in data.get("facility_ids", []):
		territory.facility_ids.append(str(facility_id))
	territory.recruit_pool = Dictionary(data.get("recruit_pool", {})).duplicate(true)
	for stack_data in data.get("garrison", []):
		territory.garrison.append(UnitStackState.from_dict(stack_data))
	return territory

