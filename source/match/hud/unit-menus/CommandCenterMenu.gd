extends GridContainer

const FactionUi = preload("res://source/match/hud/FactionUi.gd")
const WorkerUnit = preload("res://source/match/units/Worker.tscn")

var unit = null:
	set(value):
		unit = value
		_refresh()

@onready var _worker_button = find_child("ProduceWorkerButton")


func _ready():
	_refresh()


func _refresh():
	if not is_node_ready():
		return
	var faction = FactionUi.faction_of(unit)
	var costs = Constants.Match.Units.PRODUCTION_COSTS
	FactionUi.setup_button(_worker_button, WorkerUnit, faction, costs)


func _on_produce_worker_button_pressed():
	unit.production_queue.produce(WorkerUnit)
