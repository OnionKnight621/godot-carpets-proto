extends Node2D
class_name LevelBase

@export var carpet_scene: PackedScene
@export var tool_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	run_state.start_new_run() # or only once at game start
	_spawn_carpet()


func _spawn_carpet() -> void:
	if carpet_scene == null: 
		return
	var carpet = carpet_scene.instantiate()
	$CarpetRoot.add_child(carpet)
	carpet.cleaned.connect(_on_carpet_cleaned)
	carpet.progress_changed.connect(_on_progress)
	
func _spawn_tool() -> void:
	if tool_scene == null:
		return
	var tool = tool_scene.instantiate()
	add_child(tool)


func _on_progress(p: float) -> void:
	$HUDLayer/HUDBase.set_progress(p)

func _on_carpet_cleaned() -> void:
	$HUDLayer/HUDBase.show_perk_choice()
