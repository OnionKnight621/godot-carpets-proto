extends Node
class_name RunState;

signal run_started
signal resource_changed
signal progress_change()

var rng := RandomNumberGenerator.new()
var run_id: int = 0
var tools: Array = []   # later: Array[ToolData]
var perks: Array = []   # later: Array[PerkData]

var tool_is_dragging: bool = false;
var active_tool: ToolBase = null

func begin_drag(tool: ToolBase) -> void:
	active_tool = tool
	tool_is_dragging = true

func end_drag(tool: ToolBase) -> void:
	if active_tool == tool:
		active_tool = null
		tool_is_dragging = false

var carpet_progress: float = 0.0:
	set(val):
		carpet_progress = val;
		progress_change.emit()

func start_new_run(seed: int = Time.get_ticks_msec()) -> void:
	run_id += 1
	rng.seed = seed
	tools.clear()
	perks.clear()
	run_started.emit()
