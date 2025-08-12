extends Area2D
class_name CarpetBase;

signal progress_changed(p: float)
signal cleaned

func _ready() -> void:
	print('carpet spawned')
	
