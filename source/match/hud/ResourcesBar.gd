extends PanelContainer

const FactionUi = preload("res://source/match/hud/FactionUi.gd")

var player = null

@onready var _resource_a_label = find_child("ResourceALabel")
@onready var _resource_b_label = find_child("ResourceBLabel")
@onready var _resource_a_color_rect = find_child("ResourceAColorRect")
@onready var _resource_b_color_rect = find_child("ResourceBColorRect")


func _ready():
	_setup_resource_icon(_resource_a_color_rect, "ResourceA", Constants.Match.Resources.A.COLOR)
	_setup_resource_icon(_resource_b_color_rect, "ResourceB", Constants.Match.Resources.B.COLOR)


## Shows the supply crates / fuel drums icon instead of the plain colored diamond.
func _setup_resource_icon(color_rect, resource_type, color):
	color_rect.color = color
	var texture = FactionUi.icon(resource_type, FactionUi.NEUTRAL)
	if texture == null:
		return
	var icon = TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.get_parent().custom_minimum_size = Vector2(32, 32)
	color_rect.get_parent().add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.hide()


func setup(a_player):
	assert(player == null, "player cannot be null")
	player = a_player
	_on_player_resource_changed()
	player.changed.connect(_on_player_resource_changed)


func _on_player_resource_changed():
	_resource_a_label.text = str(player.resource_a)
	_resource_b_label.text = str(player.resource_b)
