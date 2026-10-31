class_name GameSession
extends RefCounted

signal mode_changed(previous_mode: String, current_mode: String)

const VALID_MODES: Array[String] = ["menu", "world", "battle"]
const ALLOWED_TRANSITIONS := {
	"menu": ["world"],
	"world": ["menu", "battle"],
	"battle": ["world", "menu"]
}

var state: GameState
var rng: DeterministicRngStreams


func _init(p_state: GameState = null) -> void:
	state = p_state if p_state != null else GameState.new()
	rng = DeterministicRngStreams.new(state.seed)
	if not state.rng_states.is_empty():
		rng.restore_states(state.rng_states)


func change_mode(next_mode: String) -> bool:
	if next_mode not in VALID_MODES:
		return false
	var current_mode := state.top_level_mode
	var allowed: Array = ALLOWED_TRANSITIONS.get(current_mode, [])
	if next_mode not in allowed:
		return false
	state.top_level_mode = next_mode
	mode_changed.emit(current_mode, next_mode)
	return true


func prepare_for_save() -> Dictionary:
	state.rng_states = rng.save_states()
	return state.to_dict()

