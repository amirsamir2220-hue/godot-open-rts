extends Button

const FactionUi = preload("res://source/match/hud/FactionUi.gd")

var queue = null
var queue_element = null


func _ready():
	if queue == null or queue_element == null:
		return
	queue_element.changed.connect(_on_queue_element_changed)
	pressed.connect(func(): queue.cancel(queue_element))
	var type = FactionUi.unit_type(queue_element.unit_prototype)
	var faction = FactionUi.faction_of(queue.get_parent())
	var texture = FactionUi.icon(type, faction)
	tooltip_text = FactionUi.unit_name(type, faction)
	if texture != null:
		icon = texture
		expand_icon = true
		icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text = ""
	else:
		text = type
	find_child("Label").text = "{0}%".format([int(queue_element.progress() * 100.0)])


func _on_queue_element_changed():
	find_child("Label").text = "{0}%".format([int(queue_element.progress() * 100.0)])
