# Visual-only motion for faction models (Generals-like feel). It animates the "Model" node
# under a unit's "Geometry" and its parts; the unit's own transform, speed, ranges and attack
# timing are never touched, so gameplay stays exactly the same.
#
#   GROUND  - hull slews towards the heading, pitches on acceleration/braking, leans in turns;
#             a "Turret" tracks the current target independently of the hull.
#   HELI    - nose dips with speed, banks into turns, hovers with a slight bob.
#   PLANE   - banks harder into turns, gentle bob; when it stops, the model keeps flying a small
#             banked circle around the unit (jets and drones never hover).
#   TURRET  - (detached structure turrets) "Turret" slews towards "TurretAim", which is what
#             the unit's RotationSynchronizer and idle rotator drive.
# Every kind gets recoil and a muzzle flash at "ProjectileOrigin" when a projectile is fired.
extends Node

enum Kind { GROUND, HELI, PLANE, TURRET }

const HULL_TURN_RATE = {
	"Tank": deg_to_rad(160.0),
	"Worker": deg_to_rad(260.0),
	"Humvee": deg_to_rad(300.0),
	"Rifleman": deg_to_rad(420.0),
	"AntiTankSoldier": deg_to_rad(420.0),
}
const DEFAULT_HULL_TURN_RATE = deg_to_rad(220.0)
const TURRET_TURN_RATE = deg_to_rad(150.0)
const STRUCTURE_TURRET_TURN_RATE = deg_to_rad(220.0)
const MOVING_SPEED_THRESHOLD = 0.05
const SMOOTHING = 8.0  # 1/s, for velocity/pitch/roll filters
const MUZZLE_FLASH_TIME_S = 0.07
const RECOIL_DISTANCE = 0.09
const RECOIL_RECOVERY = 6.0  # 1/s
const LOITER_RADIUS = 0.7
const LOITER_SPEED = 1.3  # rad/s

static var _muzzle_flash_material = null
static var _muzzle_flash_mesh = null

var kind = Kind.GROUND

var _unit = null
var _model = null
var _turret = null
var _turret_mesh = null
var _turret_aim = null
var _projectile_origin = null
var _muzzle_flash = null
var _muzzle_flash_time_left = 0.0
var _recoil = 0.0
var _kick_pitch = 0.0

var _last_position = null
var _velocity = Vector3.ZERO
var _speed = 0.0
var _speed_along_hull_last = 0.0
var _hull_yaw = null
var _drive_heading = null
var _last_hull_yaw = null
var _pitch = 0.0
var _roll = 0.0
var _turret_yaw = null
var _time = randf() * 10.0
var _loiter = 0.0
var _loiter_angle = randf() * TAU


static func kind_for(unit):
	if unit.find_child("Movement") == null:
		return Kind.TURRET if unit.find_child("RotationSynchronizer") != null else null
	if unit.movement_domain == Constants.Match.Navigation.Domain.AIR:
		return Kind.HELI if unit.find_child("Rotor") != null else Kind.PLANE
	return Kind.GROUND


func setup(unit, model, a_kind):
	_unit = unit
	_model = model
	kind = a_kind
	_turret = model.find_child("Turret")
	_turret_aim = model.find_child("TurretAim")
	_turret_mesh = _turret.find_child("Mesh") if _turret != null else null
	_projectile_origin = model.find_child("ProjectileOrigin")
	_setup_muzzle_flash()
	unit.child_entered_tree.connect(_on_unit_child_entered_tree)


func _process(delta):
	if _model == null or not is_instance_valid(_model):
		return
	delta = min(delta, 0.1)
	_time += delta
	_update_muzzle_flash(delta)
	_recoil = move_toward(_recoil, 0.0, RECOIL_DISTANCE * RECOIL_RECOVERY * delta)
	_kick_pitch = lerp(_kick_pitch, 0.0, 1.0 - exp(-SMOOTHING * delta))
	if _turret_mesh != null:
		_turret_mesh.position.z = _recoil
	if kind == Kind.TURRET:
		_update_structure_turret(delta)
		return
	_update_kinematics(delta)
	match kind:
		Kind.GROUND:
			_update_ground(delta)
		Kind.HELI:
			_update_air(delta, 0.09, 0.3, 0.32, 0.045, 1.6)
		Kind.PLANE:
			_update_air(delta, 0.03, 0.5, 0.6, 0.025, 2.2, true)


func _update_kinematics(delta):
	var position = _unit.global_position
	if _last_position == null:
		_last_position = position
	var instant_velocity = (position - _last_position) / max(delta, 0.0001)
	_last_position = position
	if instant_velocity.length() > 20.0:
		instant_velocity = Vector3.ZERO  # teleport (e.g. initial navmesh alignment)
	_velocity = _velocity.lerp(instant_velocity * Vector3(1, 0, 1), 1.0 - exp(-SMOOTHING * delta))
	_speed = _velocity.length()


func _update_ground(delta):
	var unit_yaw = _unit.global_rotation.y
	if _hull_yaw == null:
		_hull_yaw = unit_yaw
		_last_hull_yaw = unit_yaw
	# a turreted hull ignores rotations made while standing (unit turned to aim at a target)
	# and keeps turning towards the last heading it drove in
	if _speed > MOVING_SPEED_THRESHOLD or _turret == null or _drive_heading == null:
		_drive_heading = unit_yaw
	var turn_rate = HULL_TURN_RATE.get(_unit.type, DEFAULT_HULL_TURN_RATE)
	_hull_yaw = _rotate_angle_toward(_hull_yaw, _drive_heading, turn_rate * delta)
	var yaw_rate = angle_difference(_last_hull_yaw, _hull_yaw) / max(delta, 0.0001)
	_last_hull_yaw = _hull_yaw
	var forward = Vector3(-sin(_hull_yaw), 0, -cos(_hull_yaw))
	var forward_speed = _velocity.dot(forward)
	var acceleration = (forward_speed - _speed_along_hull_last) / max(delta, 0.0001)
	_speed_along_hull_last = forward_speed
	var target_pitch = clamp(acceleration * 0.012, -0.05, 0.05)  # squat on start, dip on stop
	var target_roll = clamp(yaw_rate * forward_speed * 0.02, -0.05, 0.05)  # lean out of turns
	var k = 1.0 - exp(-SMOOTHING * delta)
	_pitch = lerp(_pitch, target_pitch, k)
	_roll = lerp(_roll, target_roll, k)
	var bump = sin(_time * 23.0) * 0.004 * min(_speed / 2.0, 1.0)  # engine/terrain rumble
	_model.rotation = Vector3(_pitch + _kick_pitch, angle_difference(unit_yaw, _hull_yaw), _roll)
	_model.position.y = bump
	if _turret != null:
		_update_vehicle_turret(delta)


func _update_vehicle_turret(delta):
	var target = _find_target()
	var desired = _hull_yaw
	if target != null:
		var direction = target.global_position - _turret.global_position
		if Vector2(direction.x, direction.z).length() > 0.01:
			desired = atan2(-direction.x, -direction.z)
	if _turret_yaw == null:
		_turret_yaw = _hull_yaw
	_turret_yaw = _rotate_angle_toward(_turret_yaw, desired, TURRET_TURN_RATE * delta)
	_turret.rotation.y = angle_difference(_hull_yaw, _turret_yaw)


func _update_air(
	delta, pitch_per_speed, max_pitch, bank_per_yaw_rate, bob, bob_speed, loiters = false
):
	var unit_yaw = _unit.global_rotation.y
	if _hull_yaw == null:
		_hull_yaw = unit_yaw
		_last_hull_yaw = unit_yaw
	_hull_yaw = _rotate_angle_toward(_hull_yaw, unit_yaw, deg_to_rad(300.0) * delta)
	var yaw = _hull_yaw
	var offset = Vector3.ZERO
	if loiters:
		var idle = _speed < MOVING_SPEED_THRESHOLD * 4.0
		_loiter = move_toward(_loiter, 1.0 if idle else 0.0, delta * 0.7)
		_loiter_angle = fmod(_loiter_angle + LOITER_SPEED * delta, TAU)
		var radius = LOITER_RADIUS * smoothstep(0.0, 1.0, _loiter)
		offset = Vector3(cos(_loiter_angle), 0, sin(_loiter_angle)) * radius
		var tangent = Vector3(-sin(_loiter_angle), 0, cos(_loiter_angle))
		yaw = lerp_angle(_hull_yaw, atan2(-tangent.x, -tangent.z), smoothstep(0.0, 1.0, _loiter))
	var yaw_rate = angle_difference(_last_hull_yaw, yaw) / max(delta, 0.0001)
	_last_hull_yaw = yaw
	var forward = Vector3(-sin(yaw), 0, -cos(yaw))
	var forward_speed = _velocity.dot(forward) + LOITER_RADIUS * LOITER_SPEED * _loiter
	var k = 1.0 - exp(-SMOOTHING * 0.5 * delta)
	_pitch = lerp(_pitch, clamp(-forward_speed * pitch_per_speed, -max_pitch, max_pitch), k)
	_roll = lerp(_roll, clamp(yaw_rate * bank_per_yaw_rate, -0.6, 0.6), k)
	_model.rotation = Vector3(_pitch + _kick_pitch, angle_difference(unit_yaw, yaw), _roll)
	_model.position = Basis(Vector3.UP, -unit_yaw) * offset
	_model.position.y = sin(_time * bob_speed) * bob


func _update_structure_turret(delta):
	if _turret == null or _turret_aim == null:
		return
	var desired = _turret_aim.global_rotation.y
	if _turret_yaw == null:
		_turret_yaw = desired
	_turret_yaw = _rotate_angle_toward(_turret_yaw, desired, STRUCTURE_TURRET_TURN_RATE * delta)
	_turret.global_rotation = Vector3(0, _turret_yaw, 0)


func _find_target():
	var action = _unit.action
	if action == null:
		return null
	var candidates = [action] + action.find_children("*", "Node", true, false)
	for candidate in candidates:
		var target = candidate.get("_target_unit")
		if target != null and is_instance_valid(target) and target.is_inside_tree():
			return target
	return null


func _rotate_angle_toward(from, to, max_step):
	var difference = angle_difference(from, to)
	return from + clamp(difference, -max_step, max_step)


func _setup_muzzle_flash():
	if _projectile_origin == null:
		return
	if _muzzle_flash_material == null:
		_muzzle_flash_material = StandardMaterial3D.new()
		_muzzle_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_muzzle_flash_material.albedo_color = Color(1.0, 0.78, 0.35)
		_muzzle_flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_muzzle_flash_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_muzzle_flash_mesh = SphereMesh.new()
		_muzzle_flash_mesh.radius = 0.09
		_muzzle_flash_mesh.height = 0.14
		_muzzle_flash_mesh.radial_segments = 8
		_muzzle_flash_mesh.rings = 4
		_muzzle_flash_mesh.material = _muzzle_flash_material
	_muzzle_flash = MeshInstance3D.new()
	_muzzle_flash.name = "MuzzleFlash"
	_muzzle_flash.mesh = _muzzle_flash_mesh
	_muzzle_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_muzzle_flash.visible = false
	_projectile_origin.add_child(_muzzle_flash)


func _update_muzzle_flash(delta):
	if _muzzle_flash == null or not _muzzle_flash.visible:
		return
	_muzzle_flash_time_left -= delta
	if _muzzle_flash_time_left <= 0.0:
		_muzzle_flash.visible = false


func _on_unit_child_entered_tree(node):
	if not "target_unit" in node:
		return  # not a projectile
	if kind == Kind.GROUND:
		_recoil = RECOIL_DISTANCE
		_kick_pitch = 0.06  # rock back on the suspension
	if _muzzle_flash != null and _unit.visible:
		_muzzle_flash.visible = true
		_muzzle_flash.scale = Vector3.ONE * randf_range(0.8, 1.3)
		_muzzle_flash_time_left = MUZZLE_FLASH_TIME_S
