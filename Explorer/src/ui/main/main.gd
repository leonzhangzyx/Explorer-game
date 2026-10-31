extends Control

const BUILD_LABEL := "Prototype 0.0.1"

@onready var start_button: Button = $Center/Panel/Margin/Content/StartButton
@onready var status_label: Label = $Center/Panel/Margin/Content/Status


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://src/world/world_map.tscn")

