extends Control

const LEVEL_BASE_SCENE: PackedScene = preload("res://scenes/Levels/level_base.tscn")
@export var LEVEL_TEST: PackedScene = preload("res://scenes/Levels/level_test.tscn") 
const CARPET_BASE_SCENE: PackedScene = preload("res://scenes/Carpets/dirty_carpet_base.tscn")

@export var test_level_scene: PackedScene #= preload("res://scenes/Levels/level_test.tscn");

func _on_start_btn_pressed() -> void:
	if test_level_scene:
		get_tree().change_scene_to_packed(test_level_scene)
		return
		
	var level: Node2D;
	
	if LEVEL_TEST:
		print('Starting test lvl')
		level = LEVEL_TEST.instantiate();
	else:
		level = LEVEL_BASE_SCENE.instantiate()
	
	level.seed = randi()
	level.difficulty = 1
	level.dirty_carpet_scene = CARPET_BASE_SCENE
	
	var tree = get_tree()
	var prev_scene = tree.current_scene
	tree.root.add_child(level);
	tree.current_scene = level
	if prev_scene: prev_scene.queue_free()


func _on_quit_btn_pressed() -> void:
	get_tree().quit()
