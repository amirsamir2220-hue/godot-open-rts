# Realistic unit models (CC BY, from Sketchfab, see assets/models/realistic/CREDITS.md).
#
# Each downloaded glTF is fitted to the game at build time:
#  - rotated so its front faces -Z, scaled to `length` game units (longest horizontal side),
#    and placed with its bottom on the ground (or centered around the flight height),
#  - parts named "Turret*" in the file are gathered under a "Turret" pivot (independent aim),
#    "Rotor*" under a "Rotor" pivot (spun by Helicopter.gd), "Prop*" under a spinning
#    "Propeller", and "Drop*" parts are removed (e.g. baked rotor blur planes),
#  - a "ProjectileOrigin" marker is placed at the front of the turret (or the nose).
# Part names are prepared offline (see Phase 3C in CLAUDE.md). If a file is missing, the
# code-built model is used instead.
const K = preload("res://source/match/units/models/ModelKit.gd")
const UsaModels = preload("res://source/match/units/models/UsaModels.gd")
const RussiaModels = preload("res://source/match/units/models/RussiaModels.gd")

const ROOT = "res://assets/models/realistic/"

# shown on the Credits screen; details in assets/models/realistic/CREDITS.md
const CREDITS = [
	'"General Dynamics M1A2 Abrams Main Battle Tank" by Muhamad Mirza Arrafi (CC BY 4.0, Sketchfab)',
	'"Boeing AH-64D Apache Combat Helicopter" by Muhamad Mirza Arrafi (CC BY 4.0, Sketchfab)',
	'"M978 HEMTT" by 42manako (CC BY 4.0, Sketchfab)',
	'"MIM-104 Patriot Air Defense System" by Muhamad Mirza Arrafi (CC BY 4.0, Sketchfab)',
	'"FGM-148 Javelin" by STALKER (CC BY 4.0, Sketchfab)',
	'"Uralvagonzavod T-90AM Main Battle Tank" by Muhamad Mirza Arrafi (CC BY 4.0, Sketchfab)',
	'"Russian Ka-52 Alligator" by 42manako (CC BY 4.0, Sketchfab)',
	'"Kamaz 5330" by Brout (CC BY 4.0, Sketchfab)',
	'"96K6 Pantsir-S2" by 42manako (CC BY 4.0, Sketchfab)',
	'"9M133 Kornet / AT-14 Spriggan" by XEPCOH_552 (CC BY 4.0, Sketchfab)',
	'"Orlan-10" by flightclubua (CC BY 4.0, Sketchfab)',
]

# forward: model-space axis pointing to the vehicle's front
# mount: "ground" (bottom on y=0), "air" (centered at y=AIR_CENTER), "base" (on a code-built base)
const AIR_CENTER = 0.25
const CONFIG = {
	"usa/Tank": {"forward": Vector3(0, 0, 1), "length": 2.1, "mount": "ground"},
	"usa/Worker": {"forward": Vector3(0, 0, 1), "length": 1.5, "mount": "ground"},
	"usa/Helicopter": {"forward": Vector3(1, 0, 0), "length": 2.3, "mount": "air"},
	"usa/AntiAirTurret": {"forward": Vector3(1, 0, 0), "length": 1.5, "mount": "ground"},
	"usa/AntiGroundTurret": {"forward": Vector3(0, 0, -1), "length": 0.62, "mount": "base"},
	"russia/Tank": {"forward": Vector3(1, 0, 0), "length": 2.1, "mount": "ground"},
	"russia/Worker": {"forward": Vector3(0, 0, 1), "length": 1.35, "mount": "ground"},
	"russia/Helicopter":
	{
		"forward": Vector3(0, 0, 1),
		"length": 2.2,
		"mount": "air",
		# the file's blades are only an animation: add coaxial blades (3 + 3, counter-rotating)
		"coaxial_blades": 3,
	},
	"russia/AntiAirTurret": {"forward": Vector3(0, 0, 1), "length": 1.6, "mount": "ground"},
	"russia/AntiGroundTurret": {"forward": Vector3(1, 0, 0), "length": 0.75, "mount": "base"},
	"russia/Drone": {"forward": Vector3(0, 0, 1), "length": 1.0, "mount": "air"},
}


static func has(key):
	return CONFIG.has(key) and ResourceLoader.exists(_path(key))


static func build(key):
	var cfg = CONFIG[key]
	var root = Node3D.new()
	var holder = Node3D.new()
	holder.name = "Realistic"
	root.add_child(holder)
	var scene = load(_path(key)).instantiate()
	scene.scene_file_path = ""  # pack the fitted copy, not a reference to the source file
	holder.add_child(scene)
	for node in scene.find_children("Drop*", "", true, false):
		node.get_parent().remove_child(node)
		node.free()
	# orientation and scale
	var yaw = atan2(cfg["forward"].x, cfg["forward"].z) + PI  # rotate `forward` onto -Z
	holder.transform = Transform3D(Basis(Vector3.UP, -yaw), Vector3.ZERO)
	var aabb = _meshes_aabb(scene, root)
	var scale = cfg["length"] / max(aabb.size.x, aabb.size.z)
	holder.transform = Transform3D(
		Basis(Vector3.UP, -yaw).scaled(Vector3.ONE * scale), Vector3.ZERO
	)
	aabb = _meshes_aabb(scene, root)
	var center = aabb.get_center()
	var lift = -aabb.position.y
	if cfg["mount"] == "air":
		lift = AIR_CENTER - center.y
	holder.position = Vector3(-center.x, lift, -center.z)
	# moving parts
	var turret = _gather(root, scene, "Turret", "Turret", false)
	var rotor = _gather(root, scene, "Rotor", "Rotor", true)
	if cfg.has("coaxial_blades"):
		rotor = _add_coaxial_rotor(root, rotor, cfg["coaxial_blades"], cfg["length"] * 0.42)
	var propeller = _gather(root, scene, "Prop", "Propeller", true)
	if propeller != null:
		propeller.set_script(K.Spinner)
		propeller.axis = Vector3.FORWARD
		propeller.speed = 2000.0
	# firing point
	var full = _meshes_aabb(root, root)
	var origin = Vector3(0, full.get_center().y, full.position.z + full.size.z * 0.05)
	if turret != null:
		var turret_aabb = _meshes_aabb(turret, root)
		var local = Vector3(
			turret_aabb.get_center().x,
			turret_aabb.position.y + turret_aabb.size.y * 0.55,
			turret_aabb.position.z
		)
		turret.add_child(K.marker("ProjectileOrigin", turret.transform.affine_inverse() * local))
	elif cfg["mount"] == "air":
		root.add_child(
			K.marker(
				"ProjectileOrigin", Vector3(0, full.position.y + full.size.y * 0.3, origin.z * 0.5)
			)
		)
	if cfg["mount"] != "air":
		_add_team_pennant(root)
	if cfg["mount"] == "base":
		root = _on_code_built_base(key, root)
	return root


## A small flag in the player's color on a short pole at the rear-left of a vehicle, so units of
## players sharing a faction stay distinguishable (the realistic textures have no team color).
static func _add_team_pennant(root):
	var aabb = _meshes_aabb(root, root)
	var height = aabb.size.y
	var pole_top = aabb.end.y + height * 0.25
	var pole_bottom = aabb.position.y + height * 0.55
	var position = Vector3(
		aabb.position.x + aabb.size.x * 0.22,
		(pole_top + pole_bottom) * 0.5,
		aabb.end.z - aabb.size.z * 0.12
	)
	var b = K.builder()
	b.cylinder(K.xf(position), 0.008, 0.008, pole_top - pole_bottom, K.Palette.DARK, 4)
	var flag_size = clamp(aabb.size.z * 0.09, 0.06, 0.14)
	b.box(
		K.xf(Vector3(position.x, pole_top - flag_size * 0.3, position.z + flag_size * 0.5)),
		Vector3(0.01, flag_size * 0.6, flag_size),
		K.TEAM
	)
	root.add_child(K.mesh_node("TeamPennant", b))


## Adds two counter-rotating blade sets at the top of the model (Ka-52 style).
static func _add_coaxial_rotor(root, rotor, blade_count, radius):
	var top = _meshes_aabb(root, root)
	var hub = Vector3(0, top.end.y - 0.02, 0)
	if rotor == null:
		rotor = K.pivot("Rotor")
		root.add_child(rotor)
	var old_placement = rotor.transform
	rotor.position = hub
	for child in rotor.get_children():
		child.transform = rotor.transform.affine_inverse() * old_placement * child.transform
	rotor.add_child(K.mesh_node("Blades", _blades(blade_count, radius)))
	var lower = K.spinner("RotorLower", K.xf(hub - Vector3(0, 0.09, 0)), Vector3.UP, -800.0)
	lower.add_child(K.mesh_node("Blades", _blades(blade_count, radius)))
	root.add_child(lower)
	return rotor


static func _blades(blade_count, radius):
	var b = K.builder()
	for i in range(blade_count):
		b.box(
			(
				K.xf(Vector3.ZERO, Vector3(0, i * 360.0 / blade_count, 0))
				* K.xf(Vector3(0, 0, -radius * 0.5))
			),
			Vector3(0.05, 0.01, radius),
			K.Palette.DARK
		)
	b.cylinder(K.xf(), 0.04, 0.04, 0.04, K.Palette.METAL, 6)
	return b


static func _path(key):
	return ROOT + key + "/scene.gltf"


## Puts the realistic weapon on the code-built emplacement (sandbags/barriers and tripod).
static func _on_code_built_base(key, realistic_root):
	var builders = UsaModels.builders() if key.begins_with("usa/") else RussiaModels.builders()
	var base = builders[key.get_slice("/", 1)].call()
	var code_turret = base.find_child("Turret", false, false)
	var mount_height = code_turret.position.y if code_turret != null else 0.25
	if code_turret != null:
		base.remove_child(code_turret)
		code_turret.free()
	# the Kornet model brings its own tripod, the Javelin sits on the emplacement's tripod
	realistic_root.position.y = 0.03 if key == "russia/AntiGroundTurret" else mount_height
	base.add_child(realistic_root)
	return base


## Moves every mesh whose name starts with `prefix` under a new pivot named `pivot_name`,
## centered on those meshes (at their bottom unless `centered`), keeping their placement.
static func _gather(root, scene, prefix, pivot_name, centered):
	var parts = scene.find_children(prefix + "*", "MeshInstance3D", true, false)
	for node in scene.find_children(prefix + "*", "Node3D", true, false):
		if not node is MeshInstance3D:
			parts += node.find_children("*", "MeshInstance3D", true, false)
	if parts.is_empty():
		return null
	var aabb = null
	for part in parts:
		var part_aabb = _relative_transform(part, root) * part.get_aabb()
		aabb = part_aabb if aabb == null else aabb.merge(part_aabb)
	var pivot = Node3D.new()
	pivot.name = pivot_name
	var center = aabb.get_center()
	pivot.position = Vector3(center.x, center.y if centered else aabb.position.y, center.z)
	root.add_child(pivot)
	for part in parts:
		var placement = _relative_transform(part, root)
		part.owner = null  # ownership is reassigned when the model is packed
		part.get_parent().remove_child(part)
		pivot.add_child(part)
		part.transform = pivot.transform.affine_inverse() * placement
	return pivot


static func _relative_transform(node, ancestor):
	var transform = Transform3D.IDENTITY
	var current = node
	while current != null and current != ancestor:
		transform = current.transform * transform
		current = current.get_parent()
	return transform


static func _meshes_aabb(node, relative_to):
	var aabb = null
	var meshes = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	for mesh in meshes:
		var mesh_aabb = _relative_transform(mesh, relative_to) * mesh.get_aabb()
		aabb = mesh_aabb if aabb == null else aabb.merge(mesh_aabb)
	return aabb if aabb != null else AABB()
