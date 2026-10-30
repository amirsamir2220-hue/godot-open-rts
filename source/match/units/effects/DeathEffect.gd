# Lightweight unit death visuals: burnt wreck + fireball + smoke puffs, all tween-driven.
# Air units fall and spin before exploding, structures collapse. Wrecks sink after a while.
# Purely visual; Phase 7 (VFX) replaces the fireball/smoke with proper effects.
extends Node3D

const WRECK_LIFETIME_S = 10.0
const WRECK_SINK_TIME_S = 2.0
const FALL_TIME_S = 0.9

static var _burnt_material = null
static var _sphere_mesh = null

var _size = 1.0


## Spawns the effect for a dying unit (call before the unit leaves the tree).
static func spawn(unit):
	if not unit.is_inside_tree() or not unit.visible:
		return
	var match_node = unit.find_parent("Match")
	if match_node == null:
		return
	var geometry = unit.find_child("Geometry")
	var model = (
		geometry.get_child(0) if geometry != null and geometry.get_child_count() > 0 else null
	)
	var effect = load("res://source/match/units/effects/DeathEffect.gd").new()
	effect.name = "DeathEffect"
	match_node.add_child(effect)
	effect.global_position = unit.global_position
	var radius = unit.radius if unit.radius != null else 1.0
	var is_air = unit.movement_domain == Constants.Match.Navigation.Domain.AIR
	var is_structure = unit.find_child("Movement") == null
	effect._play(model, radius, is_air, is_structure)


func _play(model, radius, is_air, is_structure):
	_size = radius * (1.6 if is_structure else 1.0)
	var wreck = _create_wreck(model)
	if is_air and wreck != null:
		var tween = create_tween().set_parallel()
		var ground = Vector3(wreck.global_position.x, 0.05, wreck.global_position.z)
		(
			tween
			. tween_property(wreck, "global_position", ground, FALL_TIME_S)
			. set_ease(Tween.EASE_IN)
			. set_trans(Tween.TRANS_QUAD)
		)
		tween.tween_property(wreck, "rotation:y", wreck.rotation.y + TAU * 1.5, FALL_TIME_S)
		tween.tween_property(wreck, "rotation:z", 0.5, FALL_TIME_S)
		tween.chain().tween_callback(func(): _explode(Vector3(ground.x, 0.1, ground.z)))
	else:
		_explode(global_position + Vector3(0, 0.3, 0))
		if wreck != null and is_structure:
			var tween = create_tween()
			tween.tween_property(wreck, "scale:y", 0.35, 0.5).set_ease(Tween.EASE_OUT)
	var cleanup = create_tween()
	cleanup.tween_interval(WRECK_LIFETIME_S)
	if wreck != null:
		cleanup.tween_property(wreck, "position:y", wreck.position.y - 0.8, WRECK_SINK_TIME_S)
	cleanup.tween_callback(queue_free)


func _create_wreck(model):
	if model == null or not is_instance_valid(model):
		return null
	var wreck = model.duplicate()
	add_child(wreck)
	wreck.global_transform = model.global_transform
	for node in [wreck] + wreck.find_children("*", "", true, false):
		node.set_process(false)  # stop spinners
		if node.name == "MuzzleFlash":
			node.visible = false
		if node is MeshInstance3D:
			node.material_override = _get_burnt_material()
	return wreck


func _explode(at):
	var fireball = _sphere(at, Color(1.0, 0.62, 0.2, 1.0), true)
	fireball.scale = Vector3.ONE * 0.3 * _size
	var tween = create_tween().set_parallel()
	tween.tween_property(fireball, "scale", Vector3.ONE * 1.5 * _size, 0.3)
	tween.tween_property(fireball.material_override, "albedo_color:a", 0.0, 0.45)
	tween.chain().tween_callback(fireball.queue_free)
	for i in range(3):
		var offset = Vector3(randf_range(-0.3, 0.3), 0.1 * i, randf_range(-0.3, 0.3)) * _size
		var smoke = _sphere(at + offset, Color(0.18, 0.16, 0.14, 0.7), false)
		smoke.scale = Vector3.ONE * 0.4 * _size
		var smoke_tween = create_tween().set_parallel()
		var duration = 1.4 + 0.3 * i
		smoke_tween.tween_property(smoke, "position:y", smoke.position.y + 1.2 * _size, duration)
		smoke_tween.tween_property(smoke, "scale", Vector3.ONE * 1.3 * _size, duration)
		smoke_tween.tween_property(smoke.material_override, "albedo_color:a", 0.0, duration)
		smoke_tween.chain().tween_callback(smoke.queue_free)


func _sphere(at, color, additive):
	if _sphere_mesh == null:
		_sphere_mesh = SphereMesh.new()
		_sphere_mesh.radius = 0.5
		_sphere_mesh.height = 1.0
		_sphere_mesh.radial_segments = 10
		_sphere_mesh.rings = 5
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	if additive:
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	var node = MeshInstance3D.new()
	node.mesh = _sphere_mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	node.global_position = at
	return node


static func _get_burnt_material():
	if _burnt_material == null:
		_burnt_material = StandardMaterial3D.new()
		_burnt_material.albedo_color = Color(0.11, 0.1, 0.09)
		_burnt_material.roughness = 1.0
	return _burnt_material
