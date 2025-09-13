extends Area2D
class_name DirtChunk

signal removed

@export var hp: float = 1;
@export var cleaning_rate: float = 1;

@onready var sprite: Sprite2D = $Sprite2D;
@onready var shape: CollisionShape2D = $CollisionShape2D;

var layer_index: int = 0;
var cell: Vector2i = Vector2i.ZERO;
var covered_cells: Array[Vector2i] = []; # all cells covered by this one

@export var atlas: Texture2D
@export var tile_px: int = 8
@export var atlas_cols: int = 4

@export var base_radius: float = 4.0         # if round
@export var base_extents: Vector2 = Vector2(4,4) # if square

var resist_mech: float = 0.0;
var resist_fluid: float = 0.0;
var resist_solvent: float = 0.0;
var resist_holy: float = 0.0;
var resist_occult: float = 0.0

func set_resistances_from(spec: DirtLayerData) -> void:
	resist_mech    = clamp(spec.resist_mech, 0.0, 1.0)
	resist_fluid   = clamp(spec.resist_fluid, 0.0, 1.0)
	resist_solvent = clamp(spec.resist_solvent, 0.0, 1.0)
	resist_holy    = clamp(spec.resist_holy, 0.0, 1.0)
	resist_occult  = clamp(spec.resist_occult, 0.0, 1.0)

func set_variant(index: int) -> void:
	if sprite == null: sprite = get_node("Sprite2D")
	var col = index % atlas_cols
	var row = index / atlas_cols
	sprite.texture = atlas
	sprite.region_enabled = true
	sprite.region_rect = Rect2(col * tile_px, row * tile_px, tile_px, tile_px)
	sprite.centered = true
	
func apply_scale_and_collision(s: int) -> void:
	scale = Vector2(s, s)
	if shape and shape.shape:
		if shape.shape is CircleShape2D:
			(shape.shape as CircleShape2D).radius = base_radius * s
		elif shape.shape is RectangleShape2D:
			(shape.shape as RectangleShape2D).extents = base_extents * s

func apply_clean(dt: float, power: float) -> void:
	hp = max(0.0, hp - power * cleaning_rate * dt)
	sprite.modulate.a = hp;
	if hp <= 0:
		removed.emit()
		queue_free()
		
