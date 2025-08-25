extends Resource
class_name CarpetData

@export var clean_carpet_scene: PackedScene

@export var dirt_textures: Array[Texture2D] = []  

@export var dirt_atlas: Texture2D
@export var atlas_cols: int = 4
@export var tile_px: int = 8

@export var tags: Array[String] = []
@export var difficulty: int = 1
