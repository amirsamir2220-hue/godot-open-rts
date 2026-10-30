# Shared palette, materials and node helpers for the code-built faction models.
const ModelBuilder = preload("res://source/match/units/models/ModelBuilder.gd")
const Spinner = preload("res://source/match/units/models/Spinner.gd")

const TEAM = ModelBuilder.TEAM
const TEAM_MATERIAL_NAME = "team_color"


class Palette:
	# shared
	const DARK = Color("2a2a27")
	const RUBBER = Color("1f1f1d")
	const METAL = Color("6d7073")
	const GUNMETAL = Color("3b3e40")
	const GLASS = Color("27363f")
	const WHITE = Color("e6e3da")
	const YELLOW = Color("d9b13b")
	const ORANGE = Color("d8752f")
	const RED = Color("a8342b")
	const WOOD = Color("8a6a40")
	const SANDBAG = Color("bca578")
	const CONCRETE = Color("b3a891")
	const CONCRETE_DARK = Color("8c8474")
	const ASPHALT = Color("4a4843")
	# USA
	const US_TAN = Color("c4ab7c")
	const US_TAN_DARK = Color("a38d62")
	const US_OLIVE = Color("4c5137")
	const US_GRAY = Color("a2a7a9")
	const US_BUILDING = Color("cdbb95")
	const US_JAVELIN = Color("5c6542")
	# Russia
	const RU_GREEN = Color("5a6340")
	const RU_GREEN_DARK = Color("454c30")
	const RU_HELI = Color("3e4640")
	const RU_GRAY = Color("a9b0b2")
	const RU_BUILDING = Color("929780")
	const RU_TARP = Color("6b6a48")


static var _base_material = null
static var _team_placeholder = null


static func builder():
	return ModelBuilder.new()


static func xf(pos = Vector3.ZERO, rot_deg = Vector3.ZERO, scl = Vector3.ONE):
	return ModelBuilder.xf(pos, rot_deg, scl)


static func base_material():
	if _base_material == null:
		_base_material = StandardMaterial3D.new()
		_base_material.vertex_color_use_as_albedo = true
		_base_material.vertex_color_is_srgb = true
		_base_material.roughness = 0.85
	return _base_material


## Material on team-color surfaces until a player's material replaces it (e.g. blueprints).
static func team_placeholder():
	if _team_placeholder == null:
		_team_placeholder = StandardMaterial3D.new()
		_team_placeholder.resource_name = TEAM_MATERIAL_NAME
		_team_placeholder.albedo_color = Color("d8d4c8")
		_team_placeholder.roughness = 0.6
	return _team_placeholder


static func mesh_node(node_name, a_builder, transform = Transform3D.IDENTITY):
	var node = MeshInstance3D.new()
	node.name = node_name
	node.mesh = a_builder.build(base_material(), team_placeholder())
	node.transform = transform
	return node


static func pivot(node_name, transform = Transform3D.IDENTITY):
	var node = Node3D.new()
	node.name = node_name
	node.transform = transform
	return node


static func marker(node_name, position):
	var node = Marker3D.new()
	node.name = node_name
	node.position = position
	return node


static func spinner(node_name, transform, axis, speed):
	var node = Node3D.new()
	node.set_script(Spinner)
	node.name = node_name
	node.transform = transform
	node.axis = axis
	node.speed = speed
	return node


static func add(parent, child):
	parent.add_child(child)
	return child


static func sandbag_ring(b, radius, count, layers):
	for layer in range(layers):
		for i in range(count):
			if i == 0:
				continue  # opening at the back
			var angle = 360.0 * (i + layer * 0.5) / count
			b.box(
				(
					xf(Vector3(0, 0.05 + layer * 0.09, 0), Vector3(0, angle, 0))
					* xf(Vector3(0, 0, radius))
				),
				Vector3(0.3, 0.09, 0.14),
				Palette.SANDBAG
			)
