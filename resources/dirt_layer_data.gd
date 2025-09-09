extends Resource
class_name DirtLayerData

@export var atlas: Texture2D
@export var atlas_cols: int = 4;
@export var tile_px: int = 8;
@export var tile_scale: int = 1;
@export_range(0, 1) var density: float = 0.9;

@export var hp: float = 1.0;
@export var cleaning_rate: float = 1.0;

@export var layer_tag: String = "";
