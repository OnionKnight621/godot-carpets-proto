extends Area2D
class_name DirtyCarpetBase;

signal progress_changed(p: float)
signal cleaned

@export var dirt_chunk_scene: PackedScene
@export var tile_px: int = 2;
@export var atlas_cols: int = 16
@export var density: float = 0.9;
@export var tile_scale: int = 1;

var total_dirt_chunks: int = 0;
var removed_dirt_chunks: int = 0;

var area: Area2D
var layer_totals: Array[int] = []
var layer_removed: Array[int] = []

var grid := {}      # Dictionary<Vector2i, Array[DirtChunk]>
var grid_top := {}  # Dictionary<Vector2i, int>

var col_poly: CollisionPolygon2D
var col_shape: CollisionShape2D

func _ready() -> void:
	print('dirty carpet spawned')
	
func configure(data: CarpetData) -> void:
	area = data.clean_carpet_scene.instantiate() as Area2D
	area.name = "clean_carpet"
	area.set_meta("dirty_base", self)
	area.add_to_group("carpet_area")
	
	$CarpetComponents.add_child(area)
	
	# mirror transform to match coordinates
	$DirtLayers.position = area.position
	$DirtLayers.scale = area.scale
	$DirtLayers.rotation = area.rotation
	
	# find collision nodes
	col_poly  = area.get_node_or_null("CollisionPolygon2D")
	col_shape = area.get_node_or_null("CollisionShape2D")
	
	_spawn_dirt_layers(data)
	
func _spawn_dirt_layers(data: CarpetData) -> void:
	if dirt_chunk_scene == null: return 
	var sprite := area.get_node_or_null("sprite") as Sprite2D
	if sprite == null or sprite.texture == null: return

	var size := sprite.texture.get_size()
	var cols:int = int(size.x / tile_px)
	var rows:int = int(size.y / tile_px)
	var half := size * 0.5

	layer_totals.clear()
	layer_removed.clear()
	grid.clear()
	grid_top.clear()

	var rng := RandomNumberGenerator.new(); rng.randomize()
	
	print("dirt layers: ", data.dirt_layers)

	for li in data.dirt_layers.size():
		var spec: DirtLayerData = data.dirt_layers[li]
		var s :int = max(1, spec.tile_scale) # tile scale
		
		print("dirt layer ", spec.layer_tag, " : density - ", spec.density)

		var layer_node := Node2D.new()
		layer_node.name = "Layer_%d" % li
		$DirtLayers.add_child(layer_node)

		var total := 0
		for gy in range(0, rows, s):
			for gx in range(0, cols, s):
				# do not go out of bounds
				if gx + s > cols or gy + s > rows:
					continue
				# chance to place a block
				if rng.randf() > spec.density:
					continue
					
				if not _block_fully_inside(gx, gy, s, tile_px, half):
					continue

				var chunk := dirt_chunk_scene.instantiate() as DirtChunk

				# layer data
				chunk.layer_index = li
				chunk.cell = Vector2i(gx, gy)
				chunk.hp = spec.hp
				chunk.cleaning_rate = spec.cleaning_rate
				chunk.atlas = spec.atlas
				chunk.tile_px = spec.tile_px
				chunk.atlas_cols = spec.atlas_cols
				chunk.set_variant(rng.randi_range(0, spec.atlas_cols * spec.atlas_cols - 1))
				chunk.apply_scale_and_collision(s)
				chunk.set_resistances_from(spec)

				# position at the center of the s×s block
				var center_cell := Vector2(gx + s * 0.5, gy + s * 0.5)
				chunk.position = center_cell * tile_px - half

				# record in the base
				chunk.set_meta("dirty_base", self)

				# this chunk occupies s×s cells — update stacks
				chunk.covered_cells.clear()
				for oy in s:
					for ox in s:
						var key := Vector2i(gx + ox, gy + oy)
						chunk.covered_cells.append(key)
						if not grid.has(key):
							grid[key] = []
						grid[key].append(chunk)
						# top — largest layer index
						var prev_top := int(grid_top.get(key, -1))
						if li > prev_top:
							grid_top[key] = li

				# update on removal: need to remove it from ALL cells
				var c := chunk
				chunk.removed.connect(func(): _on_chunk_removed(li, c))

				layer_node.add_child(chunk)
				total += 1

		layer_totals.append(total)
		layer_removed.append(0)

	_emit_progress()

func _on_chunk_removed(li: int, chunk: DirtChunk) -> void:
	layer_removed[li] += 1

	# remove chunk from each covered cell and recalculate top
	for key in chunk.covered_cells:
		if grid.has(key):
			grid[key].erase(chunk)
			var new_top := -1
			for c in grid[key]:
				if c.layer_index > new_top:
					new_top = c.layer_index
			if new_top == -1:
				grid.erase(key)
				grid_top.erase(key)
			else:
				grid_top[key] = new_top

	_emit_progress()

	var all_total := 0; for t in layer_totals: all_total += t
	var all_removed := 0; for r in layer_removed: all_removed += r
	if all_total > 0 and all_removed >= all_total:
		cleaned.emit()
		
func _point_inside_carpet_world(world_p: Vector2) -> bool:
	if col_poly:
		var p := col_poly.to_local(world_p)
		return Geometry2D.is_point_in_polygon(p, col_poly.polygon)

	if col_shape and col_shape.shape:
		var p := col_shape.to_local(world_p)
		if col_shape.shape is CircleShape2D:
			return p.length() <= (col_shape.shape as CircleShape2D).radius
		elif col_shape.shape is RectangleShape2D:
			var e : Vector2 = (col_shape.shape as RectangleShape2D).extents
			return abs(p.x) <= e.x and abs(p.y) <= e.y
		elif col_shape.shape is ConvexPolygonShape2D:
			var pts := (col_shape.shape as ConvexPolygonShape2D).points
			return Geometry2D.is_point_in_polygon(p, pts)
		# інші шейпи — як є
	return true  # якщо колізії нема — вважай усе валідним
	
func _block_fully_inside(gx: int, gy: int, s: int, tile_px: int, half: Vector2) -> bool:
	for oy in s:
		for ox in s:
			var local_center := Vector2(
				(gx + ox) * tile_px + tile_px * 0.5,
				(gy + oy) * tile_px + tile_px * 0.5
			) - half
			var world_center : Vector2 = $DirtLayers.to_global(local_center)
			if not _point_inside_carpet_world(world_center):
				return false
	return true

# allow to clean only if chunk is top in its cell
func can_clean_chunk(chunk: DirtChunk) -> bool:
	return grid_top.get(chunk.cell, chunk.layer_index) == chunk.layer_index

func _emit_progress() -> void:
	var all_total := 0; for t in layer_totals: all_total += t
	var all_removed := 0; for r in layer_removed: all_removed += r
	var p := 0.0
	if all_total > 0:
		p = float(all_removed) / float(all_total)
	progress_changed.emit(p)
