# Registry of faction-specific unit models, keyed by unit type ("Tank", "CommandCenter", ...).
#
# Models are built once per (faction, type) and cached as PackedScenes, so all units of a kind
# share their meshes. To replace a code-built model with an imported one later, add its
# PackedScene path to MODEL_OVERRIDES - nothing else has to change as long as it keeps
# the node names "Turret", "Rotor" and "ProjectileOrigin" where the unit needs them.
const ModelKit = preload("res://source/match/units/models/ModelKit.gd")
const UsaModels = preload("res://source/match/units/models/UsaModels.gd")
const RussiaModels = preload("res://source/match/units/models/RussiaModels.gd")

const MODEL_OVERRIDES = {
# "usa/Tank": "res://assets/models/desert-command/usa/m1a2.tscn",
}

static var _cache = {}


static func has_model(type, faction):
	return _builders_for(faction).has(type) or MODEL_OVERRIDES.has(_key(type, faction))


## Returns a new model instance (Node3D) or null if there is no model for that unit type.
static func build(type, faction):
	var key = _key(type, faction)
	if not key in _cache:
		var scene = null
		if key in MODEL_OVERRIDES:
			scene = load(MODEL_OVERRIDES[key])
		else:
			var builders = _builders_for(faction)
			if not builders.has(type):
				return null
			var root = builders[type].call()
			root.name = "Model"
			_set_owner_recursively(root, root)
			scene = PackedScene.new()
			scene.pack(root)
			root.free()
		_cache[key] = scene
	return _cache[key].instantiate()


## Paints every team-color surface found under `node` with `material`.
static func apply_team_color(node, material):
	if node == null:
		return
	var mesh_instances = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		mesh_instances.append(node)
	for mesh_instance in mesh_instances:
		var mesh = mesh_instance.mesh
		if mesh == null:
			continue
		for surface_id in range(mesh.get_surface_count()):
			var surface_material = mesh.surface_get_material(surface_id)
			if (
				surface_material != null
				and surface_material.resource_name == ModelKit.TEAM_MATERIAL_NAME
			):
				mesh_instance.set_surface_override_material(surface_id, material)


## Points a turret unit's RotationSynchronizer and idle rotator at the model's turret.
## They drive a "TurretAim" node placed on the "Turret" pivot; ModelMotion then slews the
## visible "Turret" towards it (Generals-like smooth turret traverse instead of snapping).
## Launcher elevation is part of the model, so the scene's extra upward tilt is reset.
static func retarget_turret(unit, model):
	var turret = model.find_child("Turret")
	if turret == null:
		return
	var aim = model.find_child("TurretAim")
	if aim == null:
		aim = Node3D.new()
		aim.name = "TurretAim"
		turret.add_sibling(aim)
		aim.transform = turret.transform
		aim.owner = model
	turret = aim
	var upwards_rotation = unit.find_child("UpwardsRotation")
	if upwards_rotation != null:
		upwards_rotation.transform = Transform3D.IDENTITY
	var synchronizer = unit.find_child("RotationSynchronizer")
	if synchronizer != null:
		synchronizer.remote_path = synchronizer.get_path_to(turret)
	var rotator = unit.find_child("RotateRandomly*")
	if rotator != null:
		rotator.node_to_rotate = rotator.get_path_to(turret)


static func _key(type, faction):
	return "{0}/{1}".format([faction, type])


static func _builders_for(faction):
	if faction == Constants.Faction.RUSSIA:
		return RussiaModels.builders()
	return UsaModels.builders()


static func _set_owner_recursively(node, owner):
	for child in node.get_children():
		child.owner = owner
		_set_owner_recursively(child, owner)
