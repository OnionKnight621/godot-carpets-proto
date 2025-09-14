extends Area2D
class_name ToolBase

var tool_type
var tool_active: bool = false;
var tool_draggable: bool = false

@onready var particles: GPUParticles2D = $GPUParticles2D;
@onready var tool_scale: Vector2 = scale;
@onready var clean_area: Area2D = $HitArea;

@export var clean_power = 5.0;
@export var min_speed_px_s = 80;
@export var max_speed_px_s = 1000;
@export var hold_clean_factor = 0;

@export var mech: float = 1.0
@export var fluid: float = 0.0
@export var solvent: float = 0.0
@export var holy: float = 0.0
@export var occult: float = 0.0

var _prev_pos = Vector2.ZERO;

func _ready() -> void:
	_prev_pos = global_position;
	particles.emitting = false
		
func _physics_process(delta: float) -> void:
	if run_state.tool_is_dragging and run_state.active_tool == self:
		var cur = get_global_mouse_position();
		var dist = cur.distance_to(_prev_pos);
		var speed = dist / max(delta, 0.0001) #px/s
		
		if !speed: particles.emitting = false
		
		global_position = cur
		_prev_pos = cur;

		var move_factor = _calculate_move_factor(speed);

		_clean_overlaps(delta, move_factor)
	else:
		particles.emitting = false
		
func _effective_vs(chunk: DirtChunk, move_factor: float) -> float:
	var dot: float = mech * (1.0 - chunk.resist_mech) + fluid  * (1.0 - chunk.resist_fluid) + solvent * (1.0 - chunk.resist_solvent) + holy * (1.0 - chunk.resist_holy) + occult * (1.0 - chunk.resist_occult)
	dot = max(0.0, dot)
	# твій масштаб від розміру пензля лишаю, щоб не ламати баланс
	return clean_power * move_factor  * dot

func _calculate_move_factor(speed: float) -> float:
	if speed >= min_speed_px_s:
		return clamp((speed - min_speed_px_s) / (max_speed_px_s - min_speed_px_s), 0.0, 1.0)
	else:
		return hold_clean_factor

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	#if tool_draggable and event is InputEventMouseButton:
		#var mb := event as InputEventMouseButton
		#if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			#if run_state.active_tool == self:
				#run_state.end_drag(self)
			#else:
				#if run_state.active_tool:
					#run_state.end_drag(run_state.active_tool)
			#run_state.begin_drag(self)
			#_prev_pos = global_position
			##run_state.tool_is_dragging = !run_state.tool_is_dragging
			
	if not (event is InputEventMouseButton): return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed: return

	# Якщо вже активний ми — відпускаємо
	if run_state.active_tool == self:
		run_state.end_drag(self)
		z_index = 0
		
		return

	# Якщо інший активний — відпустити його
	if run_state.active_tool != null:
		run_state.end_drag(run_state.active_tool)

	# Брати в руки дозволяємо тільки коли курсор на тулі (tool_draggable виставляємо on_enter)
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
