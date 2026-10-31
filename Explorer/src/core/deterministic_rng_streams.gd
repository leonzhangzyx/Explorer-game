class_name DeterministicRngStreams
extends RefCounted

const STREAM_NAMES: Array[String] = ["world", "event", "battle", "loot"]
const STREAM_SALTS := {
	"world": 0x13579BDF,
	"event": 0x2468ACE1,
	"battle": 0x5A17B4C3,
	"loot": 0x7F4A7C15
}

var master_seed: int
var _streams: Dictionary = {}


func _init(p_master_seed: int = 1) -> void:
	master_seed = p_master_seed
	for stream_name in STREAM_NAMES:
		var rng := RandomNumberGenerator.new()
		rng.seed = _derive_seed(master_seed, int(STREAM_SALTS[stream_name]))
		_streams[stream_name] = rng


func next_int(stream_name: String, minimum: int, maximum: int) -> int:
	var rng := _get_stream(stream_name)
	return rng.randi_range(minimum, maximum)


func next_float(stream_name: String) -> float:
	return _get_stream(stream_name).randf()


func save_states() -> Dictionary:
	var result := {"master_seed": master_seed}
	for stream_name in STREAM_NAMES:
		result[stream_name] = _get_stream(stream_name).state
	return result


func restore_states(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if int(data.get("master_seed", master_seed)) != master_seed:
		errors.append("RNG master seed does not match the game state")
	for stream_name in STREAM_NAMES:
		if not data.has(stream_name):
			errors.append("Missing RNG state: %s" % stream_name)
			continue
		_get_stream(stream_name).state = int(data[stream_name])
	return errors


func _get_stream(stream_name: String) -> RandomNumberGenerator:
	assert(_streams.has(stream_name), "Unknown RNG stream: %s" % stream_name)
	return _streams[stream_name]


static func _derive_seed(source_seed: int, salt: int) -> int:
	var mixed := source_seed ^ salt
	mixed = int((mixed * 1103515245 + 12345) & 0x7FFFFFFF)
	return mixed if mixed != 0 else salt

