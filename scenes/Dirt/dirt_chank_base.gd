extends Area2D
class_name DirtChunk

signal removed

@export var hp: float = 1;
@export var cleaning_rate: float = 1;
@onready var sprite: Sprite2D = $Sprite2D;

@export var atlas: Texture2D
@export var tile_px: int = 8
@export var atlas_cols: int = 4

func set_variant(index: int) -> void:
	if sprite == null:
		sprite = get_node("Sprite2D")
	var col = index % atlas_cols
	var row = index / atlas_cols
	sprite.texture = atlas
	sprite.region_enabled = true
	sprite.region_rect = Rect2(col * tile_px, row * tile_px, tile_px, tile_px)
	sprite.centered = true

func apply_clean(dt: float, power: float) -> void:
	hp = max(0.0, hp - power * cleaning_rate * dt)
	sprite.modulate.a = hp;
	if hp <= 0:
		removed.emit()
		queue_free()
		
