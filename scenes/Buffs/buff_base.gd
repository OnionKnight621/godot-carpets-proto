extends Area2D
class_name BuffBase

@onready var tool_scale: Vector2 = scale;

@export var modifier_pack: ModifierPack
@export var modifier_source: String = "water_bucket"

func _ready() -> void:
	monitoring = true
	input_pickable = true
	#body_entered.connect(_on_body_entered)


func _on_mouse_entered() -> void:
	scale = scale * 1.1;


func _on_mouse_exited() -> void:
	scale = tool_scale


func _on_area_entered(area: Area2D) -> void:
	var tool := area.get_parent() as ToolBase
	if tool == null:
		return
	# Only buff the currently active tool
	if tool != run_state.active_tool:
		return
		
	# Expect the tool to expose apply_modifier_pack
	if tool.has_method("apply_modifier_pack"):
		print('has meth')
		tool.apply_modifier_pack(modifier_pack, modifier_source)
		# Optional: trigger particles/sound/cooldown/cleanup here


func _on_area_exited(area: Area2D) -> void:
	pass
