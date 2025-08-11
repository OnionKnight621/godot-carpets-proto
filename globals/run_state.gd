extends Node
class_name RunState;

signal run_started
signal resource_changed

var rng := RandomNumberGenerator.new()
var run_id: int = 0
var tools: Array = []   # later: Array[ToolData]
var perks: Array = []   # later: Array[PerkData]
var water_left: float = 100.0

func start_new_run(seed: int = Time.get_ticks_msec()) -> void:
	run_id += 1
	rng.seed = seed
	tools.clear()
	perks.clear()
	water_left = 100.0
	run_started.emit()

func use_water(amount: float) -> void:
	water_left = max(0.0, water_left - amount)
	resource_changed.emit()
