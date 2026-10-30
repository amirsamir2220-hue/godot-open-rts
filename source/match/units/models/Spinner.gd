# Spins a model part (propellers, tail rotors, radars) around a local axis. Purely visual.
extends Node3D

@export var axis = Vector3.UP
@export var speed = 720.0  # degrees/s


func _process(delta):
	rotate_object_local(axis, deg_to_rad(speed) * delta)
