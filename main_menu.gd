extends Control

@export var test_level_scene: PackedScene;

func _on_start_btn_pressed() -> void:
	if test_level_scene:
		get_tree().change_scene_to_packed(test_level_scene)


func _on_quit_btn_pressed() -> void:
	get_tree().quit()
