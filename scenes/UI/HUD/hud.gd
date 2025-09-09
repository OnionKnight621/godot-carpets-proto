extends CanvasLayer

@onready var carpet_progress_bar = $MarginContainer/ProgressBar

func _ready() -> void:
	run_state.connect("progress_change", update_progress_bar)

func update_progress_bar() -> void:
	carpet_progress_bar.value = run_state.carpet_progress * 100
