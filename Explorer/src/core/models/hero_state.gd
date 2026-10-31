class_name HeroState
extends RefCounted

var definition_id: String = "hero.frontier_commander"
var level: int = 1
var experience: int = 0
var skill_points: int = 0
var learned_skill_ids: Array[String] = []
var equipment_by_slot: Dictionary = {}
var injury_ids: Array[String] = []
var map_node_id: String = "map.starting_camp"
var current_health: int = 100


func to_dict() -> Dictionary:
	return {
		"definition_id": definition_id,
		"level": level,
		"experience": experience,
		"skill_points": skill_points,
		"learned_skill_ids": learned_skill_ids.duplicate(),
		"equipment_by_slot": equipment_by_slot.duplicate(true),
		"injury_ids": injury_ids.duplicate(),
		"map_node_id": map_node_id,
		"current_health": current_health
	}


static func from_dict(data: Dictionary) -> HeroState:
	var hero := HeroState.new()
	hero.definition_id = str(data.get("definition_id", ""))
	hero.level = int(data.get("level", 1))
	hero.experience = int(data.get("experience", 0))
	hero.skill_points = int(data.get("skill_points", 0))
	for skill_id in data.get("learned_skill_ids", []):
		hero.learned_skill_ids.append(str(skill_id))
	hero.equipment_by_slot = Dictionary(data.get("equipment_by_slot", {})).duplicate(true)
	for injury_id in data.get("injury_ids", []):
		hero.injury_ids.append(str(injury_id))
	hero.map_node_id = str(data.get("map_node_id", ""))
	hero.current_health = int(data.get("current_health", 0))
	return hero

