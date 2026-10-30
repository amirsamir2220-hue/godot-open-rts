extends Area3D

const ResourceDecayAnimation = preload("res://source/match/utils/ResourceDecayAnimation.tscn")
const FactionModels = preload("res://source/match/units/models/FactionModels.gd")

var radius = null:
	set = _ignore,
	get = _get_radius


func _enter_tree():
	tree_exiting.connect(_animate_decay)


func _ignore(_value):
	pass


## Puts the code-built model (supply crates / fuel drums) under "Geometry".
func _apply_model():
	var geometry = find_child("Geometry")
	var type = get_script().resource_path.get_file().get_basename()
	var model = FactionModels.build(type, FactionModels.NEUTRAL)
	if geometry == null or model == null:
		return
	for child in geometry.get_children():
		geometry.remove_child(child)
		child.free()
	geometry.add_child(model)
	model.owner = self
	model.rotation.y = randf() * TAU  # break up repetition between deposits


func _get_radius():
	return find_child("MovementObstacle").radius


func _animate_decay():
	var decay_animation = ResourceDecayAnimation.instantiate()
	decay_animation.global_transform = global_transform
	get_parent().add_child.call_deferred(decay_animation)
