extends Control

const MatchSettings = preload("res://source/data-model/MatchSettings.gd")
const PlayerSettings = preload("res://source/data-model/PlayerSettings.gd")
const LoadingScene = preload("res://source/main-menu/Loading.tscn")

var _map_paths = []
# AI slots whose faction was picked by hand; others follow the human (opposite faction)
var _ai_slots_with_manual_faction = {}

@onready var _start_button = find_child("StartButton")
@onready var _map_list = find_child("MapList")
@onready var _map_details = find_child("MapDetailsLabel")
@onready var _mode_button = find_child("ModeOptionButton")
@onready var _mode_details = find_child("ModeDetailsLabel")
@onready var _difficulty_button = find_child("DifficultyOptionButton")


func _ready():
	_setup_map_list()
	_setup_mode_list()
	_setup_difficulty_list()
	_on_map_list_item_selected(0)
	var option_nodes = find_child("GridContainer").find_children("OptionButton*")
	for option_node_id in range(option_nodes.size()):
		option_nodes[option_node_id].item_selected.connect(_on_player_selected.bind(option_node_id))
	var faction_nodes = _get_faction_nodes()
	for faction_node_id in range(faction_nodes.size()):
		faction_nodes[faction_node_id].item_selected.connect(
			_on_faction_selected.bind(faction_node_id)
		)
	_refresh_faction_pickers()


func _get_option_nodes():
	return find_child("GridContainer").find_children("OptionButton*")


func _get_faction_nodes():
	return find_child("GridContainer").find_children("FactionButton*")


func _get_human_faction():
	var option_nodes = _get_option_nodes()
	var faction_nodes = _get_faction_nodes()
	for node_id in range(option_nodes.size()):
		if option_nodes[node_id].selected == Constants.PlayerType.HUMAN:
			return Constants.Faction.ALL[faction_nodes[node_id].selected]
	return null


func _refresh_faction_pickers():
	var option_nodes = _get_option_nodes()
	var faction_nodes = _get_faction_nodes()
	var human_faction = _get_human_faction()
	for node_id in range(option_nodes.size()):
		var controller = option_nodes[node_id].selected
		faction_nodes[node_id].disabled = controller == Constants.PlayerType.NONE
		if (
			controller == Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI
			and human_faction != null
			and not node_id in _ai_slots_with_manual_faction
		):
			faction_nodes[node_id].selected = Constants.Faction.ALL.find(
				Constants.Faction.opposite(human_faction)
			)


func _setup_map_list():
	var maps = Utils.Dict.items(Constants.Match.MAPS)
	maps.sort_custom(func(map_a, map_b): return map_a[1]["players"] < map_b[1]["players"])
	_map_paths = maps.map(func(map): return map[0])
	_map_list.clear()
	for map_path in _map_paths:
		_map_list.add_item(Constants.Match.MAPS[map_path]["name"])
	_map_list.select(0)


func _setup_mode_list():
	_mode_button.clear()
	for mode in Constants.GameMode.ALL:
		_mode_button.add_item(tr(Constants.GameMode.NAMES[mode]))
	_mode_button.select(0)
	_mode_button.item_selected.connect(_on_mode_selected)
	_on_mode_selected(0)


func _setup_difficulty_list():
	_difficulty_button.clear()
	for difficulty in Constants.AiDifficulty.ALL:
		_difficulty_button.add_item(tr(Constants.AiDifficulty.NAMES[difficulty]))
	_difficulty_button.select(Constants.AiDifficulty.ALL.find(Constants.AiDifficulty.DEFAULT))


func _is_sandbox():
	return _get_selected_mode() == Constants.GameMode.SANDBOX


## Start needs 2+ players, or (sandbox) a human player.
func _update_start_button():
	var controllers = _get_option_nodes().map(func(option_node): return option_node.selected)
	if _is_sandbox():
		_start_button.disabled = not Constants.PlayerType.HUMAN in controllers
	else:
		_start_button.disabled = (
			controllers.filter(func(c): return c != Constants.PlayerType.NONE).size() < 2
		)


func _get_selected_mode():
	return Constants.GameMode.ALL[_mode_button.selected]


func _on_mode_selected(index):
	var mode = Constants.GameMode.ALL[index]
	var starting_resources = Constants.GameMode.STARTING_RESOURCES[mode]
	_mode_details.text = tr(Constants.GameMode.NAMES[mode] + "_DESCRIPTION").format(
		[starting_resources["resource_a"], starting_resources["resource_b"]]
	)
	_difficulty_button.disabled = mode == Constants.GameMode.SANDBOX
	_update_start_button()


func _create_match_settings():
	var match_settings = MatchSettings.new()
	match_settings.mode = _get_selected_mode()
	match_settings.ai_difficulty = Constants.AiDifficulty.ALL[_difficulty_button.selected]

	var option_nodes = _get_option_nodes()
	var faction_nodes = _get_faction_nodes()
	var spawn_index_offset = 0
	for option_node_id in range(option_nodes.size()):
		var player_controller = option_nodes[option_node_id].selected
		if _is_sandbox() and player_controller != Constants.PlayerType.HUMAN:
			player_controller = Constants.PlayerType.NONE  # playing alone: AI slots are ignored
		if player_controller != Constants.PlayerType.NONE:
			var player_settings = PlayerSettings.new()
			player_settings.controller = player_controller
			player_settings.color = Constants.Player.COLORS[option_node_id]
			player_settings.faction = Constants.Faction.ALL[faction_nodes[option_node_id].selected]
			player_settings.spawn_index_offset = spawn_index_offset
			match_settings.players.append(player_settings)
			spawn_index_offset = 0
		else:
			spawn_index_offset += 1

	match_settings.visible_player = -1
	for player_id in range(match_settings.players.size()):
		var player = match_settings.players[player_id]
		if player.controller == Constants.PlayerType.HUMAN:
			match_settings.visible_player = player_id
	if match_settings.visible_player == -1:
		match_settings.visibility = match_settings.Visibility.ALL_PLAYERS

	return match_settings


func _get_selected_map_path():
	return _map_paths[_map_list.get_selected_items()[0]]


func _on_start_button_pressed():
	hide()
	var new_scene = LoadingScene.instantiate()
	new_scene.match_settings = _create_match_settings()
	new_scene.map_path = _get_selected_map_path()
	get_parent().add_child(new_scene)
	get_tree().current_scene = new_scene
	queue_free()


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://source/main-menu/Main.tscn")


func _align_player_controls_visibility_to_map(map):
	var option_nodes = _get_option_nodes()
	var faction_nodes = _get_faction_nodes()
	var label_nodes = find_child("GridContainer").find_children("Label*")
	assert(option_nodes.size() == label_nodes.size())
	assert(option_nodes.size() == faction_nodes.size())
	for node_id in range(option_nodes.size()):
		option_nodes[node_id].visible = node_id < map["players"]
		faction_nodes[node_id].visible = node_id < map["players"]
		label_nodes[node_id].visible = node_id < map["players"]


func _on_player_selected(selected_option_id, selected_player_id):
	_ai_slots_with_manual_faction.erase(selected_player_id)
	if selected_option_id == Constants.PlayerType.HUMAN:
		var option_nodes = find_child("GridContainer").find_children("OptionButton*")
		for option_node_id in range(option_nodes.size()):
			if (
				option_node_id != selected_player_id
				and option_nodes[option_node_id].selected == Constants.PlayerType.HUMAN
			):
				option_nodes[option_node_id].selected = (Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI)
	_update_start_button()
	_refresh_faction_pickers()


func _on_faction_selected(_selected_faction_id, selected_player_id):
	var controller = _get_option_nodes()[selected_player_id].selected
	if controller == Constants.PlayerType.HUMAN:
		_ai_slots_with_manual_faction.clear()
	elif controller == Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI:
		_ai_slots_with_manual_faction[selected_player_id] = true
	_refresh_faction_pickers()


func _on_map_list_item_selected(index):
	var map = Constants.Match.MAPS[_map_paths[index]]
	_map_details.text = "[u]Players:[/u] {0}\n[u]Size:[/u] {1}x{2}".format(
		[map["players"], map["size"].x, map["size"].y]
	)
	_align_player_controls_visibility_to_map(map)
