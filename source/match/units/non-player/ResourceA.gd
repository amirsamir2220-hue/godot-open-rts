extends "res://source/match/units/non-player/ResourceUnit.gd"

@export var resource_a = 300:
	set(value):
		resource_a = max(0, value)
		if resource_a == 0:
			queue_free()

var color = Constants.Match.Resources.A.COLOR:
	set(_value):
		pass


func _ready():
	_apply_model()
