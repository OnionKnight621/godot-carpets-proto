extends Control
class_name UpgradeScreen

signal upgrade_selected(index: int, data)
signal upgrade_accepted(index: int, data)

@onready var options_container: HBoxContainer = $MarginContainer/VBoxContainer/OptionsMargin/OptionsContainer
@onready var accept_container: Control = $MarginContainer/VBoxContainer/AcceptContainer
@onready var accept_button: Button = $MarginContainer/VBoxContainer/AcceptContainer/AcceptButton

var _option_buttons: Array[Button] = []
var _option_payloads: Array = []
var _selected_button: Button = null
var _selected_index: int = -1

var _style_selected_normal := StyleBoxFlat.new()
var _style_selected_hover := StyleBoxFlat.new()
var _style_selected_pressed := StyleBoxFlat.new()

func _ready() -> void:
	#_initialize_styles()
	_collect_existing_buttons()
	accept_container.visible = false
	accept_button.visible = false
	accept_button.disabled = true
	accept_button.pressed.connect(_on_accept_pressed)
	reset_selection()

func set_available_options(options: Array) -> void:
	_option_payloads = []
	for i in options.size():
		var option_data = options[i]
		var button := _ensure_button_index(i)
		button.text = _format_option_label(option_data)
		button.set_meta("payload", option_data)
		button.visible = true
		button.disabled = false
		_option_payloads.append(option_data)
	for j in range(options.size(), _option_buttons.size()):
		var btn := _option_buttons[j]
		btn.visible = false
		btn.disabled = true
		btn.set_meta("payload", null)
		_clear_selection_visuals(btn)
	reset_selection()

func reset_selection() -> void:
	_set_selected_button(null)
	accept_container.visible = false
	accept_button.visible = false
	accept_button.disabled = true

func _on_option_pressed(button: Button) -> void:
	_set_selected_button(button)
	if _selected_index != -1 and _selected_index < _option_payloads.size():
		accept_container.visible = true
		accept_button.visible = true
		accept_button.disabled = false
		var payload = _option_payloads[_selected_index]
		emit_signal("upgrade_selected", _selected_index, payload)

func _set_selected_button(button: Button) -> void:
	if _selected_button == button:
		return
	if _selected_button:
		_clear_selection_visuals(_selected_button)
	_selected_button = button
	if _selected_button:
		_apply_selection_visuals(_selected_button)
		_selected_index = _option_buttons.find(_selected_button)
	else:
		_selected_index = -1

func _on_accept_pressed() -> void:
	if _selected_index == -1:
		return
	if _selected_index >= _option_payloads.size():
		return
	var payload = _option_payloads[_selected_index]
	emit_signal("upgrade_accepted", _selected_index, payload)

func _initialize_styles() -> void:
	_style_selected_normal.bg_color = Color(0.19, 0.42, 0.78, 0.18)
	_style_selected_normal.border_color = Color(0.55, 0.8, 1.0)
	_style_selected_normal.border_width_all = 3
	_style_selected_normal.corner_radius_all = 12

	_style_selected_hover = _style_selected_normal.duplicate()
	_style_selected_hover.bg_color = Color(0.19, 0.42, 0.78, 0.28)

	_style_selected_pressed = _style_selected_normal.duplicate()
	_style_selected_pressed.bg_color = Color(0.19, 0.42, 0.78, 0.38)

func _collect_existing_buttons() -> void:
	_option_buttons.clear()
	for child in options_container.get_children():
		if child is Button:
			_register_option_button(child)

func _register_option_button(button: Button) -> void:
	_option_buttons.append(button)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_option_pressed.bind(button))

func _ensure_button_index(idx: int) -> Button:
	if idx < _option_buttons.size():
		return _option_buttons[idx]
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.text = "Option"
	options_container.add_child(button)
	_register_option_button(button)
	return button

func _format_option_label(option_data) -> String:
	if option_data is Dictionary and option_data.has("label"):
		return str(option_data.label)
	return str(option_data)

func _apply_selection_visuals(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _style_selected_normal)
	button.add_theme_stylebox_override("hover", _style_selected_hover)
	button.add_theme_stylebox_override("pressed", _style_selected_pressed)
	button.add_theme_stylebox_override("focus", _style_selected_hover)
	button.add_theme_color_override("font_color", Color.WHITE)

func _clear_selection_visuals(button: Button) -> void:
	button.remove_theme_stylebox_override("normal")
	button.remove_theme_stylebox_override("hover")
	button.remove_theme_stylebox_override("pressed")
	button.remove_theme_stylebox_override("focus")
	button.remove_theme_color_override("font_color")
