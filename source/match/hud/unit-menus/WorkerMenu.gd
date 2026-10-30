extends GridContainer

const FactionUi = preload("res://source/match/hud/FactionUi.gd")
const CommandCenterUnit = preload("res://source/match/units/CommandCenter.tscn")
const VehicleFactoryUnit = preload("res://source/match/units/VehicleFactory.tscn")
const AircraftFactoryUnit = preload("res://source/match/units/AircraftFactory.tscn")
const AntiGroundTurretUnit = preload("res://source/match/units/AntiGroundTurret.tscn")
const AntiAirTurretUnit = preload("res://source/match/units/AntiAirTurret.tscn")

var unit = null:
	set(value):
		unit = value
		_refresh()

@onready var _ag_turret_button = find_child("PlaceAntiGroundTurretButton")
@onready var _aa_turret_button = find_child("PlaceAntiAirTurretButton")
@onready var _cc_button = find_child("PlaceCommandCenterButton")
@onready var _vehicle_factory_button = find_child("PlaceVehicleFactoryButton")
@onready var _aircraft_factory_button = find_child("PlaceAircraftFactoryButton")


func _ready():
	_refresh()


func _refresh():
	if not is_node_ready():
		return
	var faction = FactionUi.faction_of(unit)
	var costs = Constants.Match.Units.CONSTRUCTION_COSTS
	FactionUi.setup_button(_ag_turret_button, AntiGroundTurretUnit, faction, costs)
	FactionUi.setup_button(_aa_turret_button, AntiAirTurretUnit, faction, costs)
	FactionUi.setup_button(_cc_button, CommandCenterUnit, faction, costs)
	FactionUi.setup_button(_vehicle_factory_button, VehicleFactoryUnit, faction, costs)
	FactionUi.setup_button(_aircraft_factory_button, AircraftFactoryUnit, faction, costs)


func _on_place_command_center_button_pressed():
	MatchSignals.place_structure.emit(CommandCenterUnit)


func _on_place_vehicle_factory_button_pressed():
	MatchSignals.place_structure.emit(VehicleFactoryUnit)


func _on_place_aircraft_factory_button_pressed():
	MatchSignals.place_structure.emit(AircraftFactoryUnit)


func _on_place_anti_ground_turret_button_pressed():
	MatchSignals.place_structure.emit(AntiGroundTurretUnit)


func _on_place_anti_air_turret_button_pressed():
	MatchSignals.place_structure.emit(AntiAirTurretUnit)
