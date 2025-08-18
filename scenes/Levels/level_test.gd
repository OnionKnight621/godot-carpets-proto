extends LevelBase
	
func _ready() -> void:
	print('Level test run')
	dirty_carpet_scene = preload("res://scenes/Carpets/carpet_test.tscn")
	tool_scene = preload("res://scenes/Tools/simple_round_brush.tscn")
	run_state.start_new_run() # or only once at game start
	_spawn_carpet(dirty_carpet_scene)
	_spawn_tool(tool_scene)
