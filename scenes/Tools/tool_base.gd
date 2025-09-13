extends Area2D
class_name ToolBase

var tool_type
var tool_active: bool = false;
var tool_draggable: bool = false
@onready var particles: GPUParticles2D = $GPUParticles2D

@export var brush_radius = 12;
@export var clean_power = 5.0;
@export var min_speed_px_s = 80;
@export var max_speed_px_s = 1000;
@export var hold_clean_factor = 0;

@onready var tool_scale = scale;

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
	if run_state.tool_is_dragging:
		var cur = get_global_mouse_position();
		var dist = cur.distance_to(_prev_pos);
		var speed = dist / max(delta, 0.0001) #px/s
		
		if !speed: particles.emitting = false
		
		global_position = cur
		_prev_pos = cur;

		var move_factor = _calculate_move_factor(speed);

		_clean_overlaps(delta, move_factor)
		
func _effective_vs(chunk: DirtChunk, move_factor: float) -> float:
	var dot: float = mech * (1.0 - chunk.resist_mech) + fluid  * (1.0 - chunk.resist_fluid) + solvent * (1.0 - chunk.resist_solvent) + holy * (1.0 - chunk.resist_holy) + occult * (1.0 - chunk.resist_occult)
	dot = max(0.0, dot)
	# твій масштаб від розміру пензля лишаю, щоб не ламати баланс
	return clean_power * move_factor * (brush_radius / 16.0) * dot

func _calculate_move_factor(speed: float) -> float:
	if speed >= min_speed_px_s:
		return clamp((speed - min_speed_px_s) / (max_speed_px_s - min_speed_px_s), 0.0, 1.0)
	else:
		return hold_clean_factor

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if tool_draggable and event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			run_state.tool_is_dragging = !run_state.tool_is_dragging


func _on_mouse_entered() -> void:
	if not run_state.tool_is_dragging:
		tool_draggable = true;
		scale = scale * 1.1;


func _on_mouse_exited() -> void:
	if not run_state.tool_is_dragging:
		tool_draggable = false;
		scale = tool_scale;
		particles.emitting = false


func _clean_overlaps(delta: float, move_factor: float) -> void:
	if move_factor <= 0: 
		particles.emitting = false
		return
	
	var cleaned_any := false
	for area in get_overlapping_areas():
		if area is DirtChunk:
			var base : DirtyCarpetBase = (area as DirtChunk).get_meta("dirty_base") as DirtyCarpetBase
			if base and base.has_method("can_clean_chunk") and base.can_clean_chunk(area):
				var efficiency: float = _effective_vs(area, move_factor)
				if efficiency > 0.0:
					area.apply_clean(delta, efficiency)

			#a.apply_clean(delta, clean_power * (brush_radius / 16))
			particles.emitting = true
		else:
			particles.emitting = false
