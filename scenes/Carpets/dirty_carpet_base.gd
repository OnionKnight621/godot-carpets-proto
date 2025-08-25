extends Area2D
class_name DirtyCarpetBase;

signal progress_changed(p: float)
signal cleaned

@export var dirt_chunk_scene: PackedScene
@export var tile_px: int = 2;
@export var atlas_cols: int = 16
@export var density: float = 0.95;

var total_dirt_chunks: int = 0;
var removed_dirt_chunks: int = 0;

var area: Area2D

func _ready() -> void:
	print('dirty carpet spawned')
	
func configure(data: CarpetData) -> void:
	area = data.clean_carpet_scene.instantiate() as Area2D
	area.name = "clean_carpet"
	area.set_meta("dirty_base", self)
	area.add_to_group("carpet_area")
	
	$CarpetComponents.add_child(area)
	$DirtLayers.position = area.position
	$DirtLayers.scale = area.scale
	$DirtLayers.rotation = area.rotation
	_spawn_dirt_grid(data)
	
func clean_at(pos, radius):
	print("pos: ", pos, radius)
	
func _spawn_dirt_grid(data: CarpetData) -> void:
	if dirt_chunk_scene == null: return
	print('area: ', area)
	var sprite = area.get_node_or_null("sprite") as Sprite2D;
	print("dirt sprite ", sprite)
	var size = sprite.texture.get_size();
	print('sprite size: ', size)
	var cols = int(size.x / tile_px)
	print('cols: ', cols)
	var rows = int(size.y / tile_px)
	print('rows: ', rows)
	var half = size * 0.5;
	
	var rng = RandomNumberGenerator.new();
	rng.randomize();
	print('rng: ', rng)
	
	total_dirt_chunks = 0;
	removed_dirt_chunks = 0
	
	for y in rows:
		for x in cols:
			if rng.randf() > density:
				continue
			var chunk = dirt_chunk_scene.instantiate() as DirtChunk
			
			if data.dirt_atlas:
				chunk.atlas = data.dirt_atlas
				chunk.tile_px = tile_px
				chunk.atlas_cols = atlas_cols
				var idx := rng.randi_range(0, atlas_cols * atlas_cols)
				chunk.set_variant(idx)
			if data.dirt_textures.size() > 0:
				var tex = data.dirt_textures[rng.randi_range(0, data.dirt_textures.size() - 1)]
				chunk.get_node("Sprite2D").texture = tex
				
			var local_pos = Vector2(x * tile_px + tile_px * 0.5, y * tile_px + tile_px * 0.5) - half
			chunk.position = local_pos
			
			chunk.removed.connect(_on_chunk_removed)
			$DirtLayers.add_child(chunk)
			total_dirt_chunks += 1
			
		print("tdch: ",total_dirt_chunks)
		_emit_progress()

func _on_chunk_removed() -> void:
	removed_dirt_chunks += 1
	print("chunk removed: ", removed_dirt_chunks)
	_emit_progress()
	if removed_dirt_chunks >= total_dirt_chunks and total_dirt_chunks > 0:
		cleaned.emit()
	
func _emit_progress() -> void:
	var p = 0.0
	if total_dirt_chunks > 0:
		p = float(removed_dirt_chunks) / float(total_dirt_chunks)
	progress_changed.emit(p)
