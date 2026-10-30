extends GridContainer

const FactionUi = preload("res://source/match/hud/FactionUi.gd")
const HelicopterUnit = preload("res://source/match/units/Helicopter.tscn")
const DroneUnit = preload("res://source/match/units/Drone.tscn")

var unit = null:
	set(value):
		unit = value
		_refresh()

@onready var _helicopter_button = find_child("ProduceHelicopterButton")
@onready var _drone_button = find_child("ProduceDroneButton")


func _ready():
	_refresh()


func _refresh():
	if not is_node_ready():
		return
	var faction = FactionUi.faction_of(unit)
	var costs = Constants.Match.Units.PRODUCTION_COSTS
	FactionUi.setup_button(_helicopter_button, HelicopterUnit, faction, costs)
	FactionUi.setup_button(_drone_button, DroneUnit, faction, costs)


func _on_produce_helicopter_button_pressed():
	unit.production_queue.produce(HelicopterUnit)


func _on_produce_drone_button_pressed():
	unit.production_queue.produce(DroneUnit)
