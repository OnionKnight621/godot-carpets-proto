extends Node
class_name GameState

@export var HUB_SCENE: PackedScene = preload('res://scenes/Hub/hub.tscn')

var meta_currency: int = 0;
var unlocked_tools: Array[String] = [];

signal meta_changed

func add_currency(v: int) -> void:
	#meta progression
	meta_currency += meta_currency;
	meta_changed.emit();
