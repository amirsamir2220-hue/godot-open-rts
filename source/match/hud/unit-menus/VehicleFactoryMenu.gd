extends GridContainer

const FactionUi = preload("res://source/match/hud/FactionUi.gd")
const TankUnit = preload("res://source/match/units/Tank.tscn")

var unit = null:
	set(value):
		unit = value
		_refresh()

@onready var _tank_button = find_child("ProduceTankButton")


func _ready():
	_refresh()


func _refresh():
	if not is_node_ready():
		return
	var faction = FactionUi.faction_of(unit)
	var costs = Constants.Match.Units.PRODUCTION_COSTS
	FactionUi.setup_button(_tank_button, TankUnit, faction, costs)


func _on_produce_tank_button_pressed():
	unit.production_queue.produce(TankUnit)
