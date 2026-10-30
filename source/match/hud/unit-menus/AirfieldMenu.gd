extends GridContainer

const FactionUi = preload("res://source/match/hud/FactionUi.gd")
const FighterUnit = preload("res://source/match/units/Fighter.tscn")
const StrikeFighterUnit = preload("res://source/match/units/StrikeFighter.tscn")
const StealthFighterUnit = preload("res://source/match/units/StealthFighter.tscn")

var unit = null:
	set(value):
		unit = value
		_refresh()

@onready var _fighter_button = find_child("ProduceFighterButton")
@onready var _strike_fighter_button = find_child("ProduceStrikeFighterButton")
@onready var _stealth_fighter_button = find_child("ProduceStealthFighterButton")


func _ready():
	_refresh()


func _refresh():
	if not is_node_ready():
		return
	var faction = FactionUi.faction_of(unit)
	var costs = Constants.Match.Units.PRODUCTION_COSTS
	FactionUi.setup_button(_fighter_button, FighterUnit, faction, costs)
	FactionUi.setup_button(_strike_fighter_button, StrikeFighterUnit, faction, costs)
	FactionUi.setup_button(_stealth_fighter_button, StealthFighterUnit, faction, costs)


func _on_produce_fighter_button_pressed():
	unit.production_queue.produce(FighterUnit)


func _on_produce_strike_fighter_button_pressed():
	unit.production_queue.produce(StrikeFighterUnit)


func _on_produce_stealth_fighter_button_pressed():
	unit.production_queue.produce(StealthFighterUnit)
