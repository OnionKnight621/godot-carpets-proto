extends Area2D
class_name ToolBase

var tool_type
var tool_active: bool = false;
var tool_draggable: bool = false

@onready var particles: GPUParticles2D = $GPUParticles2D;
@onready var tool_scale: Vector2 = scale;
@onready var clean_area: Area2D = $HitArea;
@onready var tool_sprite: Sprite2D = $Sprite2D;
@onready var tool_sprite_mat: ShaderMaterial = tool_sprite.material;

@export var clean_power = 5.0;
@export var min_speed_px_s = 80;
@export var max_speed_px_s = 1000;
@export var hold_clean_factor = 0;

@export var mech: float = 1.0
@export var fluid: float = 0.0
@export var solvent: float = 0.0
@export var holy: float = 0.0
@export var occult: float = 0.0

@export var fluid_buff_outline_color: Color = Color8(64, 170, 255, 255)

var _prev_pos = Vector2.ZERO;
var _active_mods: Array = []    # [{pack: ModifierPack, t_end: float, source: String}]
var _stat_cache := {}           # cache of computed stats (avoids recomputing every frame)

func _ready() -> void:
	_prev_pos = global_position;
	particles.emitting = false
	_rebuild_stat_cache()
	_update_buff_fx()
		
func _physics_process(delta: float) -> void:
	_tick_mods()
	if run_state.tool_is_dragging and run_state.active_tool == self:
		var cur = get_global_mouse_position();
		var dist = cur.distance_to(_prev_pos);
		var speed = dist / max(delta, 0.0001) #px/s
		
		if speed <= 0.0001: particles.emitting = false
		
		global_position = cur
		_prev_pos = cur;

		var move_factor = _calculate_move_factor(speed);

		_clean_overlaps(delta, move_factor)
	else:
		particles.emitting = false
		
func _effective_vs(chunk: DirtChunk, move_factor: float) -> float:
	var d_mech := get_damage("mech");
	var d_fluid := get_damage("fluid");
	var d_solvent := get_damage("solvent");
	var d_holy := get_damage("holy");
	var d_occult := get_damage("occult");
	print('mech: ', mech, " fluid: ", fluid, " d_mech: ", d_mech, " d_fluid: ", d_fluid)

	var d_mech_calculated := d_mech * (1.0 - chunk.resist_mech)
	var d_fluid_calculated := d_fluid * (1.0 - chunk.resist_fluid)
	var d_solvent_calculated := d_solvent * (1.0 - chunk.resist_solvent)
	var d_holy_calculated := d_holy * (1.0 - chunk.resist_holy)
	var d_occult_calculated := d_occult * (1.0 - chunk.resist_occult)

	var dot: float = d_mech_calculated + d_fluid_calculated + d_solvent_calculated + d_holy_calculated + d_occult_calculated
	dot = max(0.0, dot)
	# Keep the original brush-derived scale so balance stays intact
	return clean_power * move_factor  * dot

func _calculate_move_factor(speed: float) -> float:
	if speed >= min_speed_px_s:
		return clamp((speed - min_speed_px_s) / (max_speed_px_s - min_speed_px_s), 0.0, 1.0)
	else:
		return hold_clean_factor


func _fluid_buff_frac() -> float:
	var now = Time.get_unix_time_from_system()
	var frac := 0.0
	for m in _active_mods:
		var touches_fluid := false
		for mod: StatModifier in m.pack.mods:
			if mod.path == "damage.fluid.mul" and mod.value > 0.0:
				touches_fluid = true
				break
		if touches_fluid:
			var left  = max(m.t_end - now, 0.0)
			var total = max(m.pack.duration_sec, 0.001)
			frac = max(frac, left / total)
	return frac
		
func _update_buff_fx() -> void:
	if tool_sprite_mat == null: return
	print('rsid: ', run_state.tool_is_dragging, ' rsa: ', run_state.active_tool )

	var frac := _fluid_buff_frac()          # 0..1
	var on := (frac > 0.0)
	
	if (!run_state.tool_is_dragging or !run_state.active_tool == self) and frac:
		return

	tool_sprite_mat.set_shader_parameter("outline_on", on)

	# Color: start from the configured blue and fade alpha linearly from 0.9 down to 0.0
	var a: float = 0.0
	if (on):
		a = lerp(0.0, 0.9, frac)
	var c := fluid_buff_outline_color
	c.a = a
	tool_sprite_mat.set_shader_parameter("color", c)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton): return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed: return

	# If this tool is already active, release it
	if run_state.active_tool == self:
		run_state.end_drag(self)
		z_index = 0
		
		return

	# Release whatever tool is currently active
	if run_state.active_tool != null:
		run_state.end_drag(run_state.active_tool)

	# Only allow pickup when the cursor is over the tool (tool_draggable toggled in on_enter)
	if not tool_draggable:
		return

	run_state.begin_drag(self)
	z_index = 100
	_prev_pos = global_position
	


func _on_mouse_entered() -> void:
	tool_draggable = (run_state.active_tool == null)
	if not run_state.tool_is_dragging:
		#tool_draggable = true;
		scale = scale * 1.1;


func _on_mouse_exited() -> void:
	if run_state.active_tool != self:
		tool_draggable = false
		scale = tool_scale
		particles.emitting = false


func _clean_overlaps(delta: float, move_factor: float) -> void:
	if move_factor <= 0: 
		particles.emitting = false
		return
	
	#print("m: ", mech," f: ", fluid," s: ", solvent," h: ", holy," o: ", occult)
	var cleaned_any := false
	for area in clean_area.get_overlapping_areas():
		if area is DirtChunk:
			var base : DirtyCarpetBase = (area as DirtChunk).get_meta("dirty_base") as DirtyCarpetBase
			if base and base.has_method("can_clean_chunk") and base.can_clean_chunk(area):
				var efficiency: float = _effective_vs(area, move_factor)
				if efficiency > 0.0:
					area.apply_clean(delta, efficiency)
					cleaned_any = true
	particles.emitting = cleaned_any
	
func apply_modifier_pack(pack: ModifierPack, source: String="pickup") -> void:
	# Find an existing entry with the same source/id
	if run_state.active_tool != self:
		return
		
	print('apply mod: ', pack, source)
	
	var now = Time.get_unix_time_from_system()
	var found := false
	for m in _active_mods:
		if m.pack.id == pack.id and m.source == source:
			match pack.stacking:
				ModifierPack.StackingMode.REFRESH:
					m.t_end = now + pack.duration_sec
				ModifierPack.StackingMode.STACK:
					_active_mods.append({ "pack": pack, "t_end": now + pack.duration_sec, "source": source })
				ModifierPack.StackingMode.IGNORE:
					pass
			found = true
			break
	if not found:
		_active_mods.append({ "pack": pack, "t_end": now + pack.duration_sec, "source": source })
	_rebuild_stat_cache()
	_update_buff_fx()
	
func _tick_mods() -> void:
	var now = Time.get_unix_time_from_system()
	var changed := false
	for i in range(_active_mods.size() - 1, -1, -1):
		if _active_mods[i].t_end <= now:
			_active_mods.remove_at(i)
			changed = true
	if changed:
		_rebuild_stat_cache()
	_update_buff_fx()
	
func _rebuild_stat_cache() -> void:
	# 1) Seed the cache with the tool's base stats
	var base = {
		"damage": { "mech": mech, "fluid": fluid, "solvent": solvent, "holy": 0.0, "occult": 0.0 }
	}
	# 2) Apply add/mul modifiers from all active packs
	var add := {}
	var mul := {}
	for m in _active_mods:
		for mod: StatModifier in m.pack.mods:
			var parts = mod.path.split(".") # e.g. ["damage","water","mul"]
			if parts.size() != 3: continue
			var grp = parts[0]; var key = parts[1]; var kind = parts[2] # add|mul
			if kind == "add":
				add[grp] = add.get(grp, {})
				add[grp][key] = (add[grp].get(key, 0.0) + mod.value)
			elif kind == "mul":
				mul[grp] = mul.get(grp, {})
				mul[grp][key] = (mul[grp].get(key, 0.0) + mod.value)
	# Combine the results
	_stat_cache = base
	for grp in add.keys():
		for key in add[grp].keys():
			_stat_cache[grp][key] = (_stat_cache.get(grp, {}).get(key, 0.0) + add[grp][key])
	for grp in mul.keys():
		for key in mul[grp].keys():
			_stat_cache[grp][key] = _stat_cache.get(grp, {}).get(key, 0.0) * (1.0 + mul[grp][key])
			
func get_damage(channel: String) -> float:
	return _stat_cache.get("damage", {}).get(channel, 0.0)
