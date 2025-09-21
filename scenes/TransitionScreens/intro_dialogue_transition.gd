extends Node2D

var INTRO_DIALOGUE = preload("res://Dialogues/intro.dialogue")

func _init() -> void:
	
	DialogueManager.show_dialogue_balloon(INTRO_DIALOGUE, "start")
	DialogueManager.dialogue_ended.connect(_on_dialogue_manager_dialogue_ended)

func _on_dialogue_manager_dialogue_ended(resource: DialogueResource) -> void:
	print("Dialogue ended for resource: " + resource.resource_path)
	
	if game_state.HUB_SCENE:
		#var hub = game_state.HUB_SCENE.instantiate()
		#var tree = get_tree()
		#var prev_scene = tree.current_scene
		#tree.root.add_child(hub);
		#tree.current_scene = hub
		#if prev_scene: prev_scene.queue_free()
		
		TransitionLayer.change_scene_packed(game_state.HUB_SCENE)
		return
		
	
