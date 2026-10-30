extends GridContainer

const FactionUi = preload("res://source/match/hud/FactionUi.gd")
const RiflemanUnit = preload("res://source/match/units/Rifleman.tscn")
const AntiTankSoldierUnit = preload("res://source/match/units/AntiTankSoldier.tscn")

var unit = null:
	set(value):
		unit = value
		_refresh()

@onready var _rifleman_button = find_child("ProduceRiflemanButton")
@onready var _anti_tank_soldier_button = find_child("ProduceAntiTankSoldierButton")


func _ready():
	_refresh()


func _refresh():
	if not is_node_ready():
		return
	var faction = FactionUi.faction_of(unit)
	var costs = Constants.Match.Units.PRODUCTION_COSTS
	FactionUi.setup_button(_rifleman_button, RiflemanUnit, faction, costs)
	FactionUi.setup_button(_anti_tank_soldier_button, AntiTankSoldierUnit, faction, costs)


func _on_produce_rifleman_button_pressed():
	unit.production_queue.produce(RiflemanUnit)


func _on_produce_anti_tank_soldier_button_pressed():
	unit.production_queue.produce(AntiTankSoldierUnit)
