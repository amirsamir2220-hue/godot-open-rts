# Purely visual desert clutter (small rocks, dry shrubs, pebbles) scattered over the map.
# Each prop kind is one MultiMeshInstance3D, so hundreds of props cost a few draw calls.
# Props have no collision and no navigation influence; they keep clear of spawn points and
# resource deposits and are placed deterministically per map size.
extends Node3D

const ModelKit = preload("res://source/match/units/models/ModelKit.gd")

const PROPS_PER_SQUARE_UNIT = 1.0 / 7.0
const SPAWN_CLEARANCE = 7.0
const RESOURCE_CLEARANCE = 1.6
const EDGE_MARGIN = 1.0

const ROCK = Color("8d7a62")
const ROCK_DARK = Color("6f604d")
const SHRUB = Color("7a7346")
const SHRUB_DRY = Color("8f7a50")
const PEBBLE = Color("9a8468")

# kind: [share of all props, scale range, casts shadow]
const KINDS = {
	"pebbles": [0.5, Vector2(0.7, 1.4), false],
	"shrub": [0.3, Vector2(0.6, 1.3), true],
	"rock": [0.2, Vector2(0.5, 1.5), true],
}


func setup(map):
	var size = Vector2(map.size)
	var blocked = _blocked_circles(map)
	var rng = RandomNumberGenerator.new()
	rng.seed = int(size.x * 1000 + size.y)
	var total = int(size.x * size.y * PROPS_PER_SQUARE_UNIT)
	for kind in KINDS:
		var count = int(total * KINDS[kind][0])
		var transforms = []
		var attempts = 0
		while transforms.size() < count and attempts < count * 4:
			attempts += 1
			var position = Vector3(
				rng.randf_range(EDGE_MARGIN, size.x - EDGE_MARGIN),
				0.0,
				rng.randf_range(EDGE_MARGIN, size.y - EDGE_MARGIN)
			)
			if _is_blocked(position, blocked):
				continue
			var scale = rng.randf_range(KINDS[kind][1].x, KINDS[kind][1].y)
			var basis = Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * scale)
			transforms.append(Transform3D(basis, position))
		add_child(_multimesh_instance(kind, transforms, rng))


func _blocked_circles(map):
	var circles = []
	var spawn_points = map.find_child("SpawnPoints")
	if spawn_points != null:
		for spawn_point in spawn_points.get_children():
			circles.append([spawn_point.global_position * Vector3(1, 0, 1), SPAWN_CLEARANCE])
	for resource in get_tree().get_nodes_in_group("resource_units"):
		circles.append([resource.global_position * Vector3(1, 0, 1), RESOURCE_CLEARANCE])
	var decorations = map.find_child("Decorations")
	if decorations != null:
		for decoration in decorations.find_children("*", "StaticBody3D", true, false):
			circles.append([decoration.global_position * Vector3(1, 0, 1), 1.2])
	return circles


func _is_blocked(position, circles):
	for circle in circles:
		if position.distance_to(circle[0]) < circle[1]:
			return true
	return false


func _multimesh_instance(kind, transforms, rng):
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = _build_mesh(kind)
	multimesh.instance_count = transforms.size()
	for i in range(transforms.size()):
		multimesh.set_instance_transform(i, transforms[i])
		var tint = rng.randf_range(0.85, 1.1)
		multimesh.set_instance_color(i, Color(tint, tint, tint))
	var instance = MultiMeshInstance3D.new()
	instance.name = kind.capitalize()
	instance.multimesh = multimesh
	instance.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if KINDS[kind][2]
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)
	return instance


func _build_mesh(kind):
	var b = ModelKit.builder()
	match kind:
		"rock":
			b.tapered_box(
				ModelKit.xf(Vector3(0, -0.03, 0), Vector3(0, 0, 4)),
				Vector2(0.34, 0.28),
				Vector2(0.18, 0.14),
				0.2,
				ROCK,
				Vector2(0.03, -0.02)
			)
			b.tapered_box(
				ModelKit.xf(Vector3(0.18, -0.02, 0.1), Vector3(0, 35, -6)),
				Vector2(0.18, 0.16),
				Vector2(0.08, 0.07),
				0.11,
				ROCK_DARK
			)
		"shrub":
			for i in range(5):
				var angle = i * 72.0 + 20.0
				b.cylinder(
					(
						ModelKit.xf(Vector3.ZERO, Vector3(0, angle, 0))
						* ModelKit.xf(Vector3(0, 0.09, 0.05), Vector3(28, 0, 0))
					),
					0.012,
					0.0,
					0.2,
					SHRUB_DRY if i % 2 == 0 else SHRUB,
					4,
					false
				)
			b.dome(
				ModelKit.xf(Vector3(0, 0.03, 0), Vector3.ZERO, Vector3(1, 0.7, 1)),
				0.11,
				SHRUB,
				2,
				6
			)
		_:
			for i in range(4):
				var offset = Vector3(cos(i * 1.7) * 0.12, 0.0, sin(i * 2.3) * 0.12)
				b.tapered_box(
					ModelKit.xf(offset - Vector3(0, 0.01, 0), Vector3(0, i * 40.0, 0)),
					Vector2(0.06, 0.05),
					Vector2(0.03, 0.025),
					0.035,
					PEBBLE
				)
	return b.build(ModelKit.base_material(), ModelKit.team_placeholder())
