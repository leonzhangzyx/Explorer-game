extends SceneTree


func _initialize() -> void:
	var failures: Array[String] = []
	_assert_true(FileAccess.file_exists("res://project.godot"), "project.godot exists", failures)
	_assert_true(ResourceLoader.exists("res://src/ui/main/main.tscn"), "main scene is loadable", failures)
	var main_scene := load("res://src/ui/main/main.tscn") as PackedScene
	_assert_true(main_scene != null, "main scene resource loads", failures)
	if main_scene != null:
		var instance := main_scene.instantiate()
		_assert_true(instance is Control, "main scene instantiates as Control", failures)
		instance.free()

	if failures.is_empty():
		print("SMOKE TEST PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _assert_true(condition: bool, description: String, failures: Array[String]) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures.append("FAIL: %s" % description)

