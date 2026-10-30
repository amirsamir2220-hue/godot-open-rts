extends "res://source/match/units/non-player/ResourceUnit.gd"

@export var resource_b = 300:
	set(value):
		resource_b = max(0, value)
		if resource_b == 0:
			queue_free()

var color = Constants.Match.Resources.B.COLOR:
	set(_value):
		pass


func _ready():
	_apply_model()
