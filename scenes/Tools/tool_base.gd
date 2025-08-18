extends Area2D
class_name Toolbase

var tool_type
var tool_active: bool = false;
var tool_draggable: bool = false

@export var brush_radius = 16;
@onready var tool_scale = scale;

func _process(_delta: float) -> void:
	if run_state.tool_is_dragging:
		global_position = get_global_mouse_position()


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
