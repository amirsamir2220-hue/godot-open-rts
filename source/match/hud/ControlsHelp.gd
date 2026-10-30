# "How to play" panel: shown when a match with a human player starts, toggled with H
# or the small "?" button in the top-right corner.
extends Control

const LINES = [
	"HELP_CAMERA",
	"HELP_ZOOM_ROTATE",
	"HELP_SELECT",
	"HELP_MOVE_ATTACK",
	"HELP_BUILD",
	"HELP_TRAIN",
	"HELP_RESOURCES",
	"HELP_GROUPS",
]

var _panel = null


func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_toggle_button()
	_panel = _create_panel()
	add_child(_panel)


func _unhandled_input(event):
	if event.is_action_pressed("toggle_help"):
		_panel.visible = not _panel.visible
		get_viewport().set_input_as_handled()


func _add_toggle_button():
	var button = Button.new()
	button.text = "?"
	button.tooltip_text = tr("HELP_TITLE") + " (H)"
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(36, 36)
	button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	button.position = Vector2(-48, 12)
	button.pressed.connect(func(): _panel.visible = not _panel.visible)
	add_child(button)


func _create_panel():
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.05, 0.9)
	style.border_color = Color(0.82, 0.68, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title = Label.new()
	title.text = tr("HELP_TITLE")
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.91, 0.76, 0.45))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	for key in LINES:
		var label = Label.new()
		label.text = "•  " + tr(key)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(720, 0)
		box.add_child(label)
	var close_button = Button.new()
	close_button.text = tr("HELP_CLOSE")
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(func(): panel.hide())
	box.add_child(close_button)
	# center after the size is known
	panel.resized.connect(func(): panel.position = (size - panel.size) / 2.0)
	return panel
