extends Area2D
class_name DirtyCarpetBase;

signal progress_changed(p: float)
signal cleaned

var area: Area2D

func _ready() -> void:
	print('dirty carpet spawned')
	
func configure(data: CarpetData) -> void:
	area = data.clean_carpet_scene.instantiate() as Area2D
	area.name = 'clean carpet'
	area.set_meta("dirty_base", self)
	area.add_to_group("carpet_area")
	
	$CarpetComponents.add_child(area)
	
func clean_at(pos, radius):
	print("pos: ", pos, radius)
