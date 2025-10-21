extends CanvasLayer

@onready var carpet_progress_bar = $VBoxContainer/MarginContainer/ProgressBar
@onready var finish_button: Button = $VBoxContainer/MarginContainer2/FinishButton

func _ready() -> void:
	finish_button.visible = false
	finish_button.pressed.connect(_on_finish_button_pressed)
	run_state.connect("progress_change", _update_progress_state)
	_update_progress_state()

func _update_progress_state() -> void:
	var progress := run_state.carpet_progress
	carpet_progress_bar.value = progress * 100
	finish_button.visible = progress >= run_state.EARLY_FINISH_THRESHOLD

func _on_finish_button_pressed() -> void:
	if run_state.carpet_progress < run_state.EARLY_FINISH_THRESHOLD:
		return
	var level := get_parent()
	if level and level.has_method("request_finish_cleaning"):
		level.request_finish_cleaning()
