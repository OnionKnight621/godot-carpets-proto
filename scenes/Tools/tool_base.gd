extends Area2D
class_name ToolBase

var tool_type
var tool_active: bool = false;
var tool_draggable: bool = false
@onready var particles: GPUParticles2D = $GPUParticles2D

@export var brush_radius = 16;
@export var clean_power = 5.0;
@export var min_speed_px_s = 80;
@export var max_speed_px_s = 1000;
@export var hold_clean_factor = 0;

@onready var tool_scale = scale;

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
	if move_factor <= 0: return
	
	for a in get_overlapping_areas():
		if a is DirtChunk:
			a.apply_clean(delta, clean_power * (brush_radius / 16))
			particles.emitting = true
		else:
			particles.emitting = false
