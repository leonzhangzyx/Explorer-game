class_name EncounterState
extends RefCounted

var encounter_id: String = ""
var participant_ids: Array[String] = []
var diplomacy_resolved: bool = false
var battle_config_id: String = ""
var resolution_id: String = ""


func to_dict() -> Dictionary:
	return {
		"encounter_id": encounter_id,
		"participant_ids": participant_ids.duplicate(),
		"diplomacy_resolved": diplomacy_resolved,
		"battle_config_id": battle_config_id,
		"resolution_id": resolution_id
	}


static func from_dict(data: Dictionary) -> EncounterState:
	var encounter := EncounterState.new()
	encounter.encounter_id = str(data.get("encounter_id", ""))
	for participant_id in data.get("participant_ids", []):
		encounter.participant_ids.append(str(participant_id))
	encounter.diplomacy_resolved = bool(data.get("diplomacy_resolved", false))
	encounter.battle_config_id = str(data.get("battle_config_id", ""))
	encounter.resolution_id = str(data.get("resolution_id", ""))
	return encounter

