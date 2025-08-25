extends Node2D
class_name LevelBase

@export var seed: int
@export var difficulty: int
@export var dirty_carpet_scene: PackedScene
@export var tool_scene: PackedScene
@export var carpet_pool: Array[CarpetData] = []

var rng := RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print('Level base run. Seed: ', seed, " diff: ", difficulty, " carpet: ", dirty_carpet_scene, " tool: ", tool_scene)
	rng.seed = seed
	run_state.start_new_run() # or only once at game start
	_spawn_carpet(dirty_carpet_scene)
	_spawn_tool(tool_scene)


func _spawn_carpet(carpet_scene: PackedScene) -> void:
	print('spawn carpet', dirty_carpet_scene)
	if carpet_scene == null or carpet_pool.is_empty(): return
	
	var data: CarpetData = _pick_carpet_data();
	var carpet = dirty_carpet_scene.instantiate() as DirtyCarpetBase
	carpet.configure(data)
	print('carpet data: ', data)
	$CarpetRoot.add_child(carpet)
	carpet.cleaned.connect(_on_carpet_cleaned)
	carpet.progress_changed.connect(_on_progress)
	
func _pick_carpet_data() -> CarpetData:
	var idx = rng.randi_range(0, carpet_pool.size() - 1)
	print('carpets pool: ', carpet_pool)
	return carpet_pool[idx]
	
func _spawn_tool(tool_scene: PackedScene) -> void:
	print('spawn tool', tool_scene)
	if tool_scene == null: return
	var tool = tool_scene.instantiate()
	$ToolBase.add_child(tool)


func _on_progress(p: float) -> void:
	#$HUDLayer/HUDBase.set_progress(p)
	print("progress: ", p)

func _on_carpet_cleaned() -> void:
	#$HUDLayer/HUDBase.show_perk_choice()
	print('cleaned')
