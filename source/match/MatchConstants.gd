const OWNED_PLAYER_CIRCLE_COLOR = Color.GREEN
const ADVERSARY_PLAYER_CIRCLE_COLOR = Color.RED
const RESOURCE_CIRCLE_COLOR = Color.YELLOW
const DEFAULT_CIRCLE_COLOR = Color.WHITE
const MAPS = {
	"res://source/match/maps/PlainAndSimple.tscn":
	{
		"name": "Plain & Simple",
		"players": 4,
		"size": Vector2i(50, 50),
	},
	"res://source/match/maps/BigArena.tscn":
	{
		"name": "Big Arena",
		"players": 8,
		"size": Vector2i(100, 100),
	},
}


class Navigation:
	enum Domain { AIR, TERRAIN }

	const DOMAIN_TO_GROUP_MAPPING = {
		Domain.AIR: "air_navigation_input",
		Domain.TERRAIN: "terrain_navigation_input",
	}


class Air:
	const Y = 1.5
	const PLANE = Plane(Vector3.UP, Y)

	class Navmesh:
		const CELL_SIZE = 0.4
		const CELL_HEIGHT = 0.4
		const MAX_AGENT_RADIUS = 0.8


class Terrain:
	const PLANE = Plane(Vector3.UP, 0)

	class Navmesh:
		const CELL_SIZE = 0.25
		const CELL_HEIGHT = 0.25
		const MAX_AGENT_RADIUS = 1.0  # max radius of movable units


class Resources:
	# A = Supplies (crates), B = Fuel (drums); internal names stay resource_a / resource_b
	class A:
		const COLOR = Color("d1a54f")
		const COLLECTING_TIME_S = 1.0

	class B:
		const COLOR = Color("e2622a")
		const COLLECTING_TIME_S = 2.0


class Units:
	const PRODUCTION_COSTS = {
		"res://source/match/units/Humvee.tscn":
		{
			"resource_a": 2,
			"resource_b": 1,
		},
		"res://source/match/units/Rifleman.tscn":
		{
			"resource_a": 1,
			"resource_b": 0,
		},
		"res://source/match/units/AntiTankSoldier.tscn":
		{
			"resource_a": 2,
			"resource_b": 0,
		},
		"res://source/match/units/Fighter.tscn":
		{
			"resource_a": 2,
			"resource_b": 4,
		},
		"res://source/match/units/StrikeFighter.tscn":
		{
			"resource_a": 3,
			"resource_b": 5,
		},
		"res://source/match/units/StealthFighter.tscn":
		{
			"resource_a": 4,
			"resource_b": 6,
		},
		"res://source/match/units/Worker.tscn":
		{
			"resource_a": 2,
			"resource_b": 0,
		},
		"res://source/match/units/Helicopter.tscn":
		{
			"resource_a": 1,
			"resource_b": 3,
		},
		"res://source/match/units/Drone.tscn":
		{
			"resource_a": 2,
			"resource_b": 0,
		},
		"res://source/match/units/Tank.tscn":
		{
			"resource_a": 3,
			"resource_b": 1,
		},
	}
	const PRODUCTION_TIMES = {
		"res://source/match/units/Humvee.tscn": 4.0,
		"res://source/match/units/Rifleman.tscn": 2.5,
		"res://source/match/units/AntiTankSoldier.tscn": 3.5,
		"res://source/match/units/Fighter.tscn": 8.0,
		"res://source/match/units/StrikeFighter.tscn": 10.0,
		"res://source/match/units/StealthFighter.tscn": 12.0,
		"res://source/match/units/Worker.tscn": 3.0,
		"res://source/match/units/Helicopter.tscn": 6.0,
		"res://source/match/units/Drone.tscn": 3.0,
		"res://source/match/units/Tank.tscn": 6.0,
	}
	const PRODUCTION_QUEUE_LIMIT = 5
	const STRUCTURE_BLUEPRINTS = {
		"res://source/match/units/Barracks.tscn":
		"res://source/match/units/structure-geometries/VehicleFactory.tscn",
		"res://source/match/units/Airfield.tscn":
		"res://source/match/units/structure-geometries/AircraftFactory.tscn",
		"res://source/match/units/CommandCenter.tscn":
		"res://source/match/units/structure-geometries/CommandCenter.tscn",
		"res://source/match/units/VehicleFactory.tscn":
		"res://source/match/units/structure-geometries/VehicleFactory.tscn",
		"res://source/match/units/AircraftFactory.tscn":
		"res://source/match/units/structure-geometries/AircraftFactory.tscn",
		"res://source/match/units/AntiGroundTurret.tscn":
		"res://source/match/units/structure-geometries/AntiGroundTurret.tscn",
		"res://source/match/units/AntiAirTurret.tscn":
		"res://source/match/units/structure-geometries/AntiAirTurret.tscn",
	}
	const CONSTRUCTION_COSTS = {
		"res://source/match/units/Barracks.tscn":
		{
			"resource_a": 4,
			"resource_b": 0,
		},
		"res://source/match/units/Airfield.tscn":
		{
			"resource_a": 6,
			"resource_b": 6,
		},
		"res://source/match/units/CommandCenter.tscn":
		{
			"resource_a": 8,
			"resource_b": 8,
		},
		"res://source/match/units/VehicleFactory.tscn":
		{
			"resource_a": 6,
			"resource_b": 0,
		},
		"res://source/match/units/AircraftFactory.tscn":
		{
			"resource_a": 4,
			"resource_b": 4,
		},
		"res://source/match/units/AntiGroundTurret.tscn":
		{
			"resource_a": 2,
			"resource_b": 2,
		},
		"res://source/match/units/AntiAirTurret.tscn":
		{
			"resource_a": 2,
			"resource_b": 2,
		},
	}
	const DEFAULT_PROPERTIES = {
		"res://source/match/units/Humvee.tscn":
		{
			"sight_range": 9.0,
			"hp": 7,
			"hp_max": 7,
			"attack_damage": 1,
			"attack_interval": 0.4,
			"attack_range": 4.5,
			"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
		},
		"res://source/match/units/Rifleman.tscn":
		{
			"sight_range": 6.0,
			"hp": 3,
			"hp_max": 3,
			"attack_damage": 1,
			"attack_interval": 0.8,
			"attack_range": 4.0,
			"attack_domains": [Navigation.Domain.TERRAIN],
		},
		"res://source/match/units/AntiTankSoldier.tscn":
		{
			"sight_range": 6.0,
			"hp": 3,
			"hp_max": 3,
			"attack_damage": 3,
			"attack_interval": 2.0,
			"attack_range": 5.0,
			"attack_domains": [Navigation.Domain.TERRAIN],
		},
		"res://source/match/units/Fighter.tscn":
		{
			"sight_range": 10.0,
			"hp": 8,
			"hp_max": 8,
			"attack_damage": 2,
			"attack_interval": 0.8,
			"attack_range": 6.0,
			"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
		},
		"res://source/match/units/StrikeFighter.tscn":
		{
			"sight_range": 10.0,
			"hp": 12,
			"hp_max": 12,
			"attack_damage": 3,
			"attack_interval": 1.0,
			"attack_range": 6.0,
			"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
		},
		"res://source/match/units/StealthFighter.tscn":
		{
			"sight_range": 12.0,
			"hp": 10,
			"hp_max": 10,
			"attack_damage": 4,
			"attack_interval": 1.2,
			"attack_range": 7.0,
			"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
		},
		"res://source/match/units/Barracks.tscn":
		{
			"sight_range": 8.0,
			"hp": 14,
			"hp_max": 14,
		},
		"res://source/match/units/Airfield.tscn":
		{
			"sight_range": 10.0,
			"hp": 18,
			"hp_max": 18,
		},
		"res://source/match/units/Drone.tscn":
		{
			"sight_range": 10.0,
			"hp": 6,
			"hp_max": 6,
		},
		"res://source/match/units/Worker.tscn":
		{
			"sight_range": 5.0,
			"hp": 6,
			"hp_max": 6,
			"resources_max": 2,
		},
		"res://source/match/units/Helicopter.tscn":
		{
			"sight_range": 8.0,
			"hp": 10,
			"hp_max": 10,
			"attack_damage": 1,
			"attack_interval": 1.0,
			"attack_range": 5.0,
			"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
		},
		"res://source/match/units/Tank.tscn":
		{
			"sight_range": 8.0,
			"hp": 10,
			"hp_max": 10,
			"attack_damage": 2,
			"attack_interval": 0.75,
			"attack_range": 5.0,
			"attack_domains": [Navigation.Domain.TERRAIN],
		},
		"res://source/match/units/CommandCenter.tscn":
		{
			"sight_range": 10.0,
			"hp": 20,
			"hp_max": 20,
		},
		"res://source/match/units/VehicleFactory.tscn":
		{
			"sight_range": 8.0,
			"hp": 16,
			"hp_max": 16,
		},
		"res://source/match/units/AircraftFactory.tscn":
		{
			"sight_range": 8.0,
			"hp": 16,
			"hp_max": 16,
		},
		"res://source/match/units/AntiGroundTurret.tscn":
		{
			"sight_range": 8.0,
			"hp": 8,
			"hp_max": 8,
			"attack_damage": 2,
			"attack_interval": 1.0,
			"attack_range": 8.0,
			"attack_domains": [Navigation.Domain.TERRAIN],
		},
		"res://source/match/units/AntiAirTurret.tscn":
		{
			"sight_range": 8.0,
			"hp": 8,
			"hp_max": 8,
			"attack_damage": 2,
			"attack_interval": 0.75,
			"attack_range": 8.0,
			"attack_domains": [Navigation.Domain.AIR],
		},
	}
	const PROJECTILES = {
		"res://source/match/units/Humvee.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/Rifleman.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/AntiTankSoldier.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/Fighter.tscn": "res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/StrikeFighter.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/StealthFighter.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/Helicopter.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/Tank.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/AntiGroundTurret.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/AntiAirTurret.tscn":
		"res://source/match/units/projectiles/Rocket.tscn"
	}
	const ADHERENCE_MARGIN_M = 0.3  # TODO: try lowering while fixing a 'push' problem
	const NEW_RESOURCE_SEARCH_RADIUS_M = 30
	const MOVING_UNIT_RADIUS_MAX_M = 1.0
	const EMPTY_SPACE_RADIUS_SURROUNDING_STRUCTURE_M = MOVING_UNIT_RADIUS_MAX_M * 2.5
	const STRUCTURE_CONSTRUCTING_SPEED = 0.3  # progress [0.0..1.0] per second


class VoiceNarrator:
	enum Events {
		UNIT_LOST,
	}

	const EVENT_TO_ASSET_MAPPING = {
		Events.UNIT_LOST: preload("res://assets/voice/english/unit_lost.ogg"),
	}
