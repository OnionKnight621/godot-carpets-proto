extends Node2D
class_name LevelBase

#var HUB_SCENE = preload("res://scenes/Hub/hub.tscn")

@export var seed: int
@export var difficulty: int
@export var dirty_carpet_scene: PackedScene
@export var tool_scenes: Array[PackedScene]
@export var buff_scenes: Array[PackedScene]
@export var carpet_pool: Array[CarpetData] = []
@export var upgrade_screen_scene: PackedScene = preload("res://scenes/UI/upgrade_screen.tscn")
@export var upgrade_options: Array = ["brush boost", "new solvent", "run bonus"]

var rng := RandomNumberGenerator.new()
var _upgrade_screen: UpgradeScreen = null
var _selected_upgrade

func _ready() -> void:
	print('Level base run. Seed: ', seed, " diff: ", difficulty, " carpet: ", dirty_carpet_scene, " tool: ", tool_scenes)
	rng.seed = seed
	run_state.start_new_run() # or only once at game start
	_spawn_carpet(dirty_carpet_scene)
	_spawn_tools(tool_scenes)
	_spawn_buffs(buff_scenes)

func _exit_tree() -> void:
	_cleanup_upgrade_screen()


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
	
func _spawn_tools(tool_scenes: Array[PackedScene]) -> void:
	print('spawn tools: ', tool_scenes.size())
	if tool_scenes.is_empty(): return
	
	# gather all Marker2D in ToolsLocations
	var slots: Array[Marker2D] = []
	var l := get_node_or_null("ToolsLocations")
	if l:
		for c in l.get_children():
			if c is Marker2D:
				slots.append(c)
	
	if slots.is_empty():
		push_warning("No tool spawn markers under ToolsLocations; spawning at ToolBase origin.")
		
	var count: int = min(tool_scenes.size(), slots.size() if slots.size() > 0 else tool_scenes.size())
	
	for i in count:
		var scene := tool_scenes[i]
		if scene == null: continue
		var tool := scene.instantiate()
		$ToolBase.add_child(tool)
		if slots.size() > 0:
			tool.global_position = slots[i].global_position
			print('spawn tool: ', tool)
		else:
			tool.global_position = $ToolBase.global_position  # backup
			
func _spawn_buffs(buff_scenes: Array[PackedScene]) -> void:
	print('spawn buffs: ', buff_scenes.size())
	if buff_scenes.is_empty(): return
	
	# gather all Marker2D in BuffsLocations
	var slots: Array[Marker2D] = []
	var l := get_node_or_null("BuffsLocations")
	if l:
		for c in l.get_children():
			if c is Marker2D:
				slots.append(c)
				
	if slots.is_empty():
		push_warning("No buff spawn markers under BuffsLocations; spawning at ToolBase origin.")
		
	var count: int = min(buff_scenes.size(), slots.size() if slots.size() > 0 else buff_scenes.size())
	
	for i in count:
		var scene := buff_scenes[i]
		if scene == null: continue
		var buff := scene.instantiate()
		$ToolBase.add_child(buff)
		if slots.size() > 0:
			buff.global_position = slots[i].global_position
			print('spawn buff: ', buff)

func _on_progress(p: float) -> void:
	run_state.carpet_progress = p

func request_finish_cleaning() -> void:
	if run_state.carpet_progress < run_state.EARLY_FINISH_THRESHOLD:
		return
	run_state.carpet_progress = 1.0
	_show_upgrade_screen()

func _on_carpet_cleaned() -> void:
	print('cleaned')
	run_state.carpet_progress = 1.0
	_show_upgrade_screen()

func _show_upgrade_screen() -> void:
	if _upgrade_screen != null:
		return
	if upgrade_screen_scene == null:
		_transition_to_hub()
		return
	run_state.set_buffs_paused(true)
	_upgrade_screen = upgrade_screen_scene.instantiate() as UpgradeScreen
	if _upgrade_screen == null:
		run_state.set_buffs_paused(false)
		_transition_to_hub()
		return
	var ui_root: Node = get_node_or_null("HUD")
	if ui_root == null:
		ui_root = self
	ui_root.add_child(_upgrade_screen)
	_upgrade_screen.upgrade_selected.connect(_on_upgrade_option_selected)
	_upgrade_screen.upgrade_accepted.connect(_on_upgrade_accepted)
	if _upgrade_screen.has_method("set_available_options"):
		_upgrade_screen.set_available_options(_build_upgrade_options())
	else:
		print("Upgrade screen missing set_available_options; falling back to defaults")

func _build_upgrade_options() -> Array:
	if upgrade_options.is_empty():
		return ["upgrade option A", "upgrade option B", "upgrade option C"]
	return upgrade_options.duplicate(true)

func _on_upgrade_option_selected(_index: int, data) -> void:
	_selected_upgrade = data

func _on_upgrade_accepted(_index: int, data) -> void:
	_selected_upgrade = data
	_transition_to_hub()

func _cleanup_upgrade_screen() -> void:
	if _upgrade_screen:
		_upgrade_screen.queue_free()
		_upgrade_screen = null
	run_state.set_buffs_paused(false)

func _transition_to_hub() -> void:
	_cleanup_upgrade_screen()
	if game_state.HUB_SCENE:
		get_tree().change_scene_to_packed(game_state.HUB_SCENE);
