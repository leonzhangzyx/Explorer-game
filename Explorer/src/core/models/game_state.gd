class_name GameState
extends RefCounted

const SCHEMA_VERSION := 1
const GAME_VERSION := "0.0.1"
const CONTENT_VERSION := "0.1.0"

var day: int = 1
var threat: int = 0
var seed: int = 1
var top_level_mode: String = "world"
var rng_states: Dictionary = {}
var resources: Dictionary = {
	"resource.gold": 0,
	"resource.wood": 0,
	"resource.ore": 0,
	"resource.arcane_essence": 0
}
var quest_ids: Array[String] = []
var hero: HeroState = HeroState.new()
var army: ArmyState = ArmyState.new()
var territories: Array[TerritoryState] = []
var encounters: Array[EncounterState] = []
var events: Array[EventState] = []
var active_battle: BattleState
var world: WorldState = WorldState.new()


func to_dict() -> Dictionary:
	var territory_data: Array[Dictionary] = []
	var encounter_data: Array[Dictionary] = []
	var event_data: Array[Dictionary] = []
	for territory in territories:
		territory_data.append(territory.to_dict())
	for encounter in encounters:
		encounter_data.append(encounter.to_dict())
	for event_state in events:
		event_data.append(event_state.to_dict())
	return {
		"schema_version": SCHEMA_VERSION,
		"game_version": GAME_VERSION,
		"content_version": CONTENT_VERSION,
		"day": day,
		"threat": threat,
		"seed": seed,
		"top_level_mode": top_level_mode,
		"rng_states": rng_states.duplicate(true),
		"resources": resources.duplicate(true),
		"quest_ids": quest_ids.duplicate(),
		"hero": hero.to_dict(),
		"army": army.to_dict(),
		"territories": territory_data,
		"encounters": encounter_data,
		"events": event_data,
		"active_battle": active_battle.to_dict() if active_battle != null else null,
		"world": world.to_dict()
	}


static func from_dict(data: Dictionary) -> GameState:
	var state := GameState.new()
	state.day = int(data.get("day", 1))
	state.threat = int(data.get("threat", 0))
	state.seed = int(data.get("seed", 1))
	state.top_level_mode = str(data.get("top_level_mode", "world"))
	state.rng_states = Dictionary(data.get("rng_states", {})).duplicate(true)
	state.resources = {}
	var serialized_resources: Dictionary = data.get("resources", {})
	for resource_id in serialized_resources:
		state.resources[str(resource_id)] = int(serialized_resources[resource_id])
	for quest_id in data.get("quest_ids", []):
		state.quest_ids.append(str(quest_id))
	state.hero = HeroState.from_dict(data.get("hero", {}))
	state.army = ArmyState.from_dict(data.get("army", {}))
	for territory_data in data.get("territories", []):
		state.territories.append(TerritoryState.from_dict(territory_data))
	for encounter_data in data.get("encounters", []):
		state.encounters.append(EncounterState.from_dict(encounter_data))
	for event_data in data.get("events", []):
		state.events.append(EventState.from_dict(event_data))
	if data.get("active_battle") is Dictionary:
		state.active_battle = BattleState.from_dict(data.get("active_battle"))
	state.world = WorldState.from_dict(data.get("world", {}))
	return state

