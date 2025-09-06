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
var layer_totals: Array[int] = []
var layer_removed: Array[int] = []

var grid := {}      # Dictionary<Vector2i, Array[DirtChunk]>
var grid_top := {}  # Dictionary<Vector2i, int>

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
	_spawn_dirt_layers(data)
	
func _spawn_dirt_layers(data: CarpetData) -> void:
	if dirt_chunk_scene == null: return 
	var sprite := area.get_node_or_null("sprite") as Sprite2D
	print('s', sprite)
	if sprite == null or sprite.texture == null: return

	var size := sprite.texture.get_size()
	var cols := int(size.x / tile_px)
	var rows := int(size.y / tile_px)
	var half := size * 0.5

	layer_totals.clear()
	layer_removed.clear()
	grid.clear()
	grid_top.clear()

	var rng := RandomNumberGenerator.new(); rng.randomize()
	
	print("ddl", data.dirt_layers)

	for li in data.dirt_layers.size():
		var spec: DirtLayerData = data.dirt_layers[li]
		# (на цьому етапі tile_px у всіх шарах повинен збігатися з експортним tile_px)
		var layer_node := Node2D.new()
		layer_node.name = "Layer_%d" % li
		$DirtLayers.add_child(layer_node)

		var total := 0
		print('rows', rows)
		for y in rows:
			for x in cols:
				if rng.randf() > spec.density: continue

				var chunk := dirt_chunk_scene.instantiate() as DirtChunk
				chunk.layer_index = li
				chunk.cell = Vector2i(x, y)
				chunk.hp = spec.hp
				chunk.cleaning_rate = spec.cleaning_rate
				chunk.atlas = spec.atlas
				chunk.tile_px = spec.tile_px
				chunk.atlas_cols = spec.atlas_cols
				chunk.set_variant(rng.randi_range(0, spec.atlas_cols * spec.atlas_cols - 1))

				# pos from center
				chunk.position = Vector2(x * tile_px + tile_px * 0.5, y * tile_px + tile_px * 0.5) - half

				# base tie
				chunk.set_meta("dirty_base", self)

				# cell stack
				var key := chunk.cell
				if not grid.has(key): grid[key] = []
				grid[key].append(chunk)
				# top — msx layer index
				var prev_top := int(grid_top.get(key, -1))
				if li > prev_top: grid_top[key] = li

				# on removed: update progress і top (only in that cell)
				var c := chunk
				chunk.removed.connect(func(): _on_chunk_removed(li, c))

				layer_node.add_child(chunk)
				total += 1

		layer_totals.append(total)
		layer_removed.append(0)

	_emit_progress()

func _on_chunk_removed(li: int, chunk: DirtChunk) -> void:
	layer_removed[li] += 1

	var key := chunk.cell
	if grid.has(key):
		grid[key].erase(chunk)
		var new_top := -1
		for c in grid[key]:
			if c.layer_index > new_top:
				new_top = c.layer_index
		if new_top == -1:
			grid.erase(key); grid_top.erase(key)
		else:
			grid_top[key] = new_top

	_emit_progress()

	# all clear
	var all_total := 0; for t in layer_totals: all_total += t
	var all_removed := 0; for r in layer_removed: all_removed += r
	if all_total > 0 and all_removed >= all_total:
		cleaned.emit()

# allow to clean only if chunk is top in his cell
func can_clean_chunk(chunk: DirtChunk) -> bool:
	return grid_top.get(chunk.cell, chunk.layer_index) == chunk.layer_index

func _emit_progress() -> void:
	var all_total := 0; for t in layer_totals: all_total += t
	var all_removed := 0; for r in layer_removed: all_removed += r
	var p := 0.0
	if all_total > 0:
		p = float(all_removed) / float(all_total)
	progress_changed.emit(p)
