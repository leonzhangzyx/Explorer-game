class_name BattleUnit
extends RefCounted

var instance_id: String
var definition_id: String
var display_name: String
var faction: String
var grid_position: Vector2i
var max_health: int
var current_health: int
var attack: int
var defense: int
var speed: int
var move_range: int
var attack_range: int = 1
var trait_id: String = ""
var is_hero: bool
var is_defending: bool = false
var has_acted: bool = false
var has_moved: bool = false
var can_counter: bool = true
var is_down: bool = false
var moved_distance: int = 0
var morale: int = 0
var statuses: Dictionary = {}
var skill_cooldowns: Dictionary = {}
var charge: int = 0


func _init(
	p_instance_id: String,
	p_definition_id: String,
	p_display_name: String,
	p_faction: String,
	p_grid_position: Vector2i,
	p_max_health: int,
	p_attack: int,
	p_defense: int,
	p_speed: int,
	p_move_range: int,
	p_is_hero: bool = false,
	p_attack_range: int = 1,
	p_trait_id: String = ""
) -> void:
	instance_id = p_instance_id
	definition_id = p_definition_id
	display_name = p_display_name
	faction = p_faction
	grid_position = p_grid_position
	max_health = p_max_health
	current_health = p_max_health
	attack = p_attack
	defense = p_defense
	speed = p_speed
	move_range = p_move_range
	is_hero = p_is_hero
	attack_range = p_attack_range
	trait_id = p_trait_id


func is_active() -> bool:
	return current_health > 0 and not is_down


func to_dict() -> Dictionary:
	return {
		"instance_id": instance_id,
		"definition_id": definition_id,
		"display_name": display_name,
		"faction": faction,
		"grid_position": [grid_position.x, grid_position.y],
		"max_health": max_health,
		"current_health": current_health,
		"attack": attack,
		"defense": defense,
		"speed": speed,
		"move_range": move_range,
		"attack_range": attack_range,
		"trait_id": trait_id,
		"is_hero": is_hero,
		"is_defending": is_defending,
		"has_acted": has_acted,
		"has_moved": has_moved,
		"can_counter": can_counter,
		"is_down": is_down
		,"moved_distance": moved_distance,
		"morale": morale,
		"statuses": statuses.duplicate(true),
		"skill_cooldowns": skill_cooldowns.duplicate(true),
		"charge": charge
	}


func has_status(status_id: String) -> bool:
	return statuses.has(status_id)


func add_status(status_id: String, duration: int) -> void:
	statuses[status_id] = maxi(duration, int(statuses.get(status_id, 0)))


func remove_status(status_id: String) -> void:
	statuses.erase(status_id)

