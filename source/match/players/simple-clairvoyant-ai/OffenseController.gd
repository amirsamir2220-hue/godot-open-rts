extends Node

signal resources_required(resources, metadata)

const Worker = preload("res://source/match/units/Worker.gd")
const CommandCenter = preload("res://source/match/units/CommandCenter.gd")
const Tank = preload("res://source/match/units/Tank.gd")
const Helicopter = preload("res://source/match/units/Helicopter.gd")
const Fighter = preload("res://source/match/units/Fighter.gd")
const AutoAttackingBattlegroup = preload(
	"res://source/match/players/simple-clairvoyant-ai/AutoAttackingBattlegroup.gd"
)

const TankScene = preload("res://source/match/units/Tank.tscn")
const RiflemanScene = preload("res://source/match/units/Rifleman.tscn")

const REFRESH_INTERVAL_S = 1.0 / 60.0 * 30.0
# per offensive structure: [structure scene, structure script, units it trains (picked randomly)]
const OFFENSIVE_STRUCTURES = {
	0:
	[
		preload("res://source/match/units/VehicleFactory.tscn"),
		preload("res://source/match/units/VehicleFactory.gd"),
		[
			TankScene,
			TankScene,
			preload("res://source/match/units/Humvee.tscn"),
		],
	],
	1:
	[
		preload("res://source/match/units/AircraftFactory.tscn"),
		preload("res://source/match/units/AircraftFactory.gd"),
		[preload("res://source/match/units/Helicopter.tscn")],
	],
	2:
	[
		preload("res://source/match/units/Barracks.tscn"),
		preload("res://source/match/units/Barracks.gd"),
		[
			RiflemanScene,
			RiflemanScene,
			preload("res://source/match/units/AntiTankSoldier.tscn"),
		],
	],
	3:
	[
		preload("res://source/match/units/Airfield.tscn"),
		preload("res://source/match/units/Airfield.gd"),
		[
			preload("res://source/match/units/Fighter.tscn"),
			preload("res://source/match/units/StrikeFighter.tscn"),
			preload("res://source/match/units/StealthFighter.tscn"),
		],
	],
}

var _player = null
var _primary_structure_scene = null
var _secondary_structure_scene = null
var _number_of_pending_structure_resource_requests = {}
var _primary_unit_scenes = []
var _secondary_unit_scenes = []
var _pending_unit_scenes = {}
var _number_of_pending_unit_resource_requests = {}
var _battlegroup_under_forming = null
var _battlegroups = []

@onready var _ai = get_parent()


func setup(player):
	_player = player
	_primary_structure_scene = OFFENSIVE_STRUCTURES[_ai.primary_offensive_structure][0]
	_secondary_structure_scene = OFFENSIVE_STRUCTURES[_ai.secondary_offensive_structure][0]
	_primary_unit_scenes = OFFENSIVE_STRUCTURES[_ai.primary_offensive_structure][2]
	_secondary_unit_scenes = OFFENSIVE_STRUCTURES[_ai.secondary_offensive_structure][2]
	_setup_refresh_timer()
	_try_creating_new_battlegroup()
	_attach_current_battle_units()
	MatchSignals.unit_spawned.connect(_on_unit_spawned)
	_enforce_primary_structure_existence()


func provision(resources, metadata):
	if metadata == "primary_structure":
		_provision_structure(_primary_structure_scene, resources, metadata)
	elif metadata == "secondary_structure":
		_provision_structure(_secondary_structure_scene, resources, metadata)
	elif metadata == "primary_unit":
		_provision_unit(_pending_unit_scenes[metadata], _primary_structure(), resources, metadata)
	elif metadata == "secondary_unit":
		_provision_unit(_pending_unit_scenes[metadata], _secondary_structure(), resources, metadata)
	else:
		assert(false, "unexpected flow")


func _setup_refresh_timer():
	var timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_refresh_timer_timeout)
	timer.start(REFRESH_INTERVAL_S)


func _provision_structure(structure_scene, resources, metadata):
	assert(
		resources == Constants.Match.Units.CONSTRUCTION_COSTS[structure_scene.resource_path],
		"unexpected amount of resources"
	)
	var workers = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is Worker and unit.player == _player
	)
	_number_of_pending_structure_resource_requests[metadata] -= 1
	if workers.is_empty():
		return
	_construct_structure(structure_scene)


func _provision_unit(unit_scene, structure_producing_unit, resources, metadata):
	assert(
		resources == Constants.Match.Units.PRODUCTION_COSTS[unit_scene.resource_path],
		"unexpected amount of resources"
	)
	if structure_producing_unit == null:
		return
	_number_of_pending_unit_resource_requests[metadata] -= 1
	structure_producing_unit.production_queue.produce(unit_scene, true)


func _try_creating_new_battlegroup():
	if not _battlegroups.is_empty():
		_enforce_secondary_structure_existence()
	if _battlegroups.size() == _ai.expected_number_of_battlegroups:
		var primary_structure = _primary_structure()
		if primary_structure != null:
			primary_structure.production_queue.cancel_all()
		_battlegroup_under_forming = null
		return false
	var adversary_players = get_tree().get_nodes_in_group("players").filter(
		func(player): return player != _player
	)
	adversary_players.shuffle()
	var battlegroup = AutoAttackingBattlegroup.new(
		_ai.expected_number_of_units_in_battlegroup, adversary_players
	)
	_battlegroups.append(battlegroup)
	battlegroup.tree_exited.connect(_on_battlegroup_died.bind(battlegroup))
	add_child(battlegroup)
	_battlegroup_under_forming = battlegroup
	return true


func _attach_current_battle_units():
	var battle_units = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit.player == _player and _is_battle_unit(unit)
	)
	for battle_unit in battle_units:
		_on_unit_spawned(battle_unit)


func _construct_structure(structure_scene):
	var construction_cost = Constants.Match.Units.CONSTRUCTION_COSTS[structure_scene.resource_path]
	assert(
		_player.has_resources(construction_cost),
		"player should have enough resources at this point"
	)
	# TODO: introduce actual algorithm which takes enemy positions into account
	var ccs = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is CommandCenter and unit.player == _player
	)
	var workers = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is Worker and unit.player == _player
	)
	var unit_to_spawn = structure_scene.instantiate()
	var reference_position_for_placement = (
		ccs[0].global_position if not ccs.is_empty() else workers[0].global_position
	)
	var placement_position = Utils.Match.Unit.Placement.find_valid_position_radially(
		reference_position_for_placement,
		unit_to_spawn.radius + Constants.Match.Units.EMPTY_SPACE_RADIUS_SURROUNDING_STRUCTURE_M,
		find_parent("Match").navigation.get_navigation_map_rid_by_domain(
			unit_to_spawn.movement_domain
		),
		get_tree()
	)
	var target_transform = Transform3D(Basis(), placement_position).looking_at(
		placement_position + Vector3(-1, 0, 1), Vector3.UP
	)
	_player.subtract_resources(construction_cost)
	MatchSignals.setup_and_spawn_unit.emit(unit_to_spawn, target_transform, _player)
	_enforce_primary_units_production.call_deferred()


func _enforce_primary_structure_existence():
	_enforce_structure_existence(
		_primary_structure(), _primary_structure_scene, "primary_structure"
	)


func _enforce_secondary_structure_existence():
	_enforce_structure_existence(
		_secondary_structure(), _secondary_structure_scene, "secondary_structure"
	)


func _enforce_structure_existence(structure, structure_scene, type):
	if structure == null and _number_of_pending_structure_resource_requests.get(type, 0) == 0:
		_number_of_pending_structure_resource_requests[type] = (
			_number_of_pending_structure_resource_requests.get(type, 0) + 1
		)
		resources_required.emit(
			Constants.Match.Units.CONSTRUCTION_COSTS[structure_scene.resource_path], type
		)


func _enforce_primary_units_production():
	_enforce_units_production(_primary_structure(), _primary_unit_scenes, "primary_unit")


func _enforce_secondary_units_production():
	_enforce_units_production(_secondary_structure(), _secondary_unit_scenes, "secondary_unit")


func _enforce_units_production(structure, unit_scenes, type):
	if structure == null or not structure.is_constructed() or not _is_units_production_allowed():
		return
	var number_of_pending_units = structure.production_queue.size()
	if number_of_pending_units + _number_of_pending_unit_resource_requests.get(type, 0) == 0:
		_number_of_pending_unit_resource_requests[type] = (
			_number_of_pending_unit_resource_requests.get(type, 0) + 1
		)
		var unit_scene = unit_scenes.pick_random()
		_pending_unit_scenes[type] = unit_scene
		resources_required.emit(
			Constants.Match.Units.PRODUCTION_COSTS[unit_scene.resource_path], type
		)


func _primary_structure():
	return _structure_of_kind(_ai.primary_offensive_structure)


func _secondary_structure():
	return _structure_of_kind(_ai.secondary_offensive_structure)


func _structure_of_kind(kind):
	var structure_script = OFFENSIVE_STRUCTURES[kind][1]
	var structures = get_tree().get_nodes_in_group("units").filter(
		func(unit): return is_instance_of(unit, structure_script) and unit.player == _player
	)
	return structures[0] if not structures.is_empty() else null


func _is_battle_unit(unit):
	return unit is Tank or unit is Helicopter or unit is Fighter


func _is_units_production_allowed():
	var primary_structure = _primary_structure()
	var secondary_structure = _secondary_structure()
	return (
		_number_of_additional_units_required()
		> (
			Utils.Arr.sum(_number_of_pending_unit_resource_requests.values())
			+ (
				primary_structure.production_queue.size()
				if primary_structure != null and primary_structure.is_constructed()
				else 0
			)
			+ (
				secondary_structure.production_queue.size()
				if secondary_structure != null and secondary_structure.is_constructed()
				else 0
			)
		)
	)


func _number_of_additional_units_required():
	if _battlegroup_under_forming == null:
		return 0
	return (
		_ai.expected_number_of_battlegroups * _ai.expected_number_of_units_in_battlegroup
		- (_battlegroups.size() - 1) * _ai.expected_number_of_units_in_battlegroup
		- _battlegroup_under_forming.size()
	)


func _on_unit_spawned(unit):
	if unit.player != _player:
		return
	if _is_battle_unit(unit):
		# TODO: check if this still happens after ensuring only own players should match
		# assert(_battlegroup_under_forming != null) # TODO: investigate how do we get here
		if _battlegroup_under_forming == null:
			return
		_battlegroup_under_forming.attach_unit(unit)
		if _battlegroup_under_forming.size() == _ai.expected_number_of_units_in_battlegroup:
			_try_creating_new_battlegroup()
		_enforce_primary_units_production()
		_enforce_secondary_units_production()


func _on_battlegroup_died(battlegroup):
	if not is_inside_tree():
		return
	_battlegroups.erase(battlegroup)


func _on_refresh_timer_timeout():
	_enforce_primary_structure_existence()
	# secondary structure existence is enforced only when a battlegroup is formed
	_enforce_primary_units_production()
	_enforce_secondary_units_production()
