extends Node2D
class_name Hub

@export var level_scene: PackedScene       

@onready var carpet_area: Area2D    = $CarpetArea
@onready var carpet_sprite: Sprite2D = $CarpetArea/Sprite2D
@onready var outline_mat: ShaderMaterial = carpet_sprite.material

const LEVEL_BASE_SCENE: PackedScene = preload("res://scenes/Levels/level_base.tscn")
const CARPET_BASE_SCENE: PackedScene = preload("res://scenes/Carpets/dirty_carpet_base.tscn")
@export var LEVEL_TEST: PackedScene = preload("res://scenes/Levels/level_test.tscn") 

@export var test_level_scene: PackedScene #= preload("res://scenes/Levels/level_test.tscn");

func _ready() -> void:
	# to make sure event is catched
	carpet_area.input_pickable = true
	
	carpet_area.mouse_entered.connect(_on_carpet_mouse_entered)
	carpet_area.mouse_exited.connect(_on_carpet_mouse_exited)
	carpet_area.input_event.connect(_on_carpet_input_event)

	_set_outline(false)
	
func _on_carpet_mouse_entered() -> void:
	_set_outline(true)

func _on_carpet_mouse_exited() -> void:
	_set_outline(false)

func _on_carpet_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		_start_cleaning_level()

func _set_outline(enabled: bool) -> void:
	if outline_mat:
		outline_mat.set_shader_parameter("outline_on", enabled)

func _start_cleaning_level() -> void:
	var level: Node2D;
	
	if LEVEL_TEST:
		print('Starting test lvl')
		level = LEVEL_TEST.instantiate();
	else:
		level = LEVEL_BASE_SCENE.instantiate()
	
	level.seed = randi()
	level.difficulty = 1
	level.dirty_carpet_scene = CARPET_BASE_SCENE
	
	var tree = get_tree()
	var prev_scene = tree.current_scene
	tree.root.add_child(level);
	tree.current_scene = level
	if prev_scene: prev_scene.queue_free()
