extends Node
class_name RunState;

signal run_started
signal resource_changed
signal progress_change()
signal buffs_changed(tool: ToolBase)
signal active_tool_changed(new: ToolBase)

const _INF := INF
const EARLY_FINISH_THRESHOLD := 0.5

var rng := RandomNumberGenerator.new()
var run_id: int = 0
var tools: Array = []   # later: Array[ToolData]
var perks: Array = []   # later: Array[PerkData]

var tool_is_dragging: bool = false;
var active_tool: ToolBase = null

var global_mods: Array = []    # Array[ActiveMod]
var buff_paused: bool = false

func _ready() -> void:
	set_process(true)

func _process(_delta: float) -> void:
	if buff_paused:
		return
	if global_mods.is_empty():
		return
	var now := Time.get_unix_time_from_system()
	var changed := false
	for i in range(global_mods.size() - 1, -1, -1):
		var entry: Dictionary = global_mods[i]
		var t_end = entry.get("t_end", _INF)
		if t_end == _INF:
			continue
		if t_end <= now:
			global_mods.remove_at(i)
			changed = true
	if changed:
		buffs_changed.emit(null)

func begin_drag(tool: ToolBase) -> void:
	active_tool = tool
	tool_is_dragging = true
	active_tool_changed.emit(active_tool)

func end_drag(tool: ToolBase) -> void:
	if active_tool == tool:
		active_tool = null
		tool_is_dragging = false
		active_tool_changed.emit(null)

func add_global_pack(pack: ModifierPack, source: String = "perk:<id>") -> void:
	if pack == null:
		push_warning("Attempted to add null ModifierPack to global mods")
		return
	var now := Time.get_unix_time_from_system()
	var t_end := _INF
	if pack.duration_sec > 0.0:
		t_end = now + pack.duration_sec
	var entry := {"pack": pack, "t_end": t_end, "source": source}
	var handled := false
	var changed := false
	for i in range(global_mods.size() - 1, -1, -1):
		var existing: Dictionary = global_mods[i]
		if existing.get("source", "") != source:
			continue
		var existing_pack: ModifierPack = existing.get("pack")
		if existing_pack == null or existing_pack.id != pack.id:
			continue
		match pack.stacking:
			ModifierPack.StackingMode.REFRESH:
				existing["t_end"] = t_end
				existing["pack"] = pack
				handled = true
				changed = true
			ModifierPack.StackingMode.STACK:
				global_mods.append(entry)
				handled = true
				changed = true
			ModifierPack.StackingMode.IGNORE:
				handled = true
		if handled:
			break
	if not handled:
		global_mods.append(entry)
		changed = true
	if changed:
		buffs_changed.emit(null)

func remove_global_by_source(source: String) -> void:
	var removed := false
	for i in range(global_mods.size() - 1, -1, -1):
		var entry: Dictionary = global_mods[i]
		if entry.get("source", "") == source:
			global_mods.remove_at(i)
			removed = true
	if removed:
		buffs_changed.emit(null)

func get_global_mods() -> Array:
	return global_mods.duplicate(true)

func set_buffs_paused(paused: bool) -> void:
	if buff_paused == paused:
		return
	buff_paused = paused
	if paused:
		print("should be called upgrade screen")

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
