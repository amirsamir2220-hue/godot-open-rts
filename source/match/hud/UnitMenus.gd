extends PanelContainer

const VehicleFactory = preload("res://source/match/units/VehicleFactory.gd")
const AircraftFactory = preload("res://source/match/units/AircraftFactory.gd")
const CommandCenter = preload("res://source/match/units/CommandCenter.gd")
const Worker = preload("res://source/match/units/Worker.gd")
const Barracks = preload("res://source/match/units/Barracks.gd")
const Airfield = preload("res://source/match/units/Airfield.gd")

@onready var _generic_menu = find_child("GenericMenu")
@onready var _command_center_menu = find_child("CommandCenterMenu")
@onready var _vehicle_factory_menu = find_child("VehicleFactoryMenu")
@onready var _aircraft_factory_menu = find_child("AircraftFactoryMenu")
@onready var _worker_menu = find_child("WorkerMenu")
@onready var _barracks_menu = find_child("BarracksMenu")
@onready var _airfield_menu = find_child("AirfieldMenu")


func _ready():
	_reset_menus()
	MatchSignals.unit_selected.connect(func(_unit): _reset_menus())
	MatchSignals.unit_deselected.connect(func(_unit): _reset_menus())
	MatchSignals.unit_died.connect(func(_unit): _reset_menus())


func _reset_menus():
	_hide_all_menus()
	if _try_showing_any_menu():
		show()
	else:
		hide()


func _hide_all_menus():
	_generic_menu.hide()
	_command_center_menu.hide()
	_vehicle_factory_menu.hide()
	_aircraft_factory_menu.hide()
	_worker_menu.hide()
	_barracks_menu.hide()
	_airfield_menu.hide()


func _try_showing_any_menu():
	var selected_controlled_units = get_tree().get_nodes_in_group("selected_units").filter(
		func(unit): return unit.is_in_group("controlled_units")
	)
	if selected_controlled_units.size() == 1:
		var unit = selected_controlled_units[0]
		for entry in [
			[CommandCenter, _command_center_menu],
			[VehicleFactory, _vehicle_factory_menu],
			[AircraftFactory, _aircraft_factory_menu],
			[Barracks, _barracks_menu],
			[Airfield, _airfield_menu],
		]:
			if is_instance_of(unit, entry[0]) and unit.is_constructed():
				entry[1].unit = unit
				entry[1].show()
				return true
	if selected_controlled_units.size() == 1 and selected_controlled_units[0] is Worker:
		_worker_menu.unit = selected_controlled_units[0]
		_worker_menu.show()
	if selected_controlled_units.size() > 0:
		_generic_menu.units = selected_controlled_units
		_generic_menu.show()
		return true
	return false
