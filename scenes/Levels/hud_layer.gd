extends CanvasLayer


@onready var carpet_progress_bar = $HUDBase/MarginContainer/ProgressBar

func update_progress_bar() -> void:
	carpet_progress_bar.value = run_state.carpet_progress * 100
