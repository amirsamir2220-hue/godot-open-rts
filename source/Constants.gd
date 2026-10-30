extends Node

enum PlayerType {
	NONE = 0,
	HUMAN = 1,
	SIMPLE_CLAIRVOYANT_AI = 2,
}


class Faction:
	const USA = "usa"
	const RUSSIA = "russia"
	const ALL = [USA, RUSSIA]
	const DEFAULT = USA
	const NAMES = {
		USA: "FACTION_USA",
		RUSSIA: "FACTION_RUSSIA",
	}

	static func opposite(faction):
		return RUSSIA if faction == USA else USA


class GameMode:
	const NORMAL = "normal"
	const DEATH_MATCH = "death_match"  # Generals-style: huge starting money, focus on fighting
	const SANDBOX = "sandbox"  # play alone: only the human player, lots of money, no match end
	const ALL = [NORMAL, DEATH_MATCH, SANDBOX]
	const NAMES = {
		NORMAL: "MODE_NORMAL",
		DEATH_MATCH: "MODE_DEATH_MATCH",
		SANDBOX: "MODE_SANDBOX",
	}
	const STARTING_RESOURCES = {
		NORMAL: {"resource_a": 0, "resource_b": 0},
		DEATH_MATCH: {"resource_a": 500, "resource_b": 500},
		SANDBOX: {"resource_a": 1000, "resource_b": 1000},
	}
	# added on top of the AI difficulty settings: a bigger army when money is not the limit
	const AI_BONUS = {
		NORMAL: {},
		DEATH_MATCH:
		{
			"expected_number_of_ag_turrets": 1,
			"expected_number_of_aa_turrets": 1,
			"expected_number_of_battlegroups": 1,
			"expected_number_of_units_in_battlegroup": 2,
		},
		SANDBOX: {},
	}


class AiDifficulty:
	const EASY = "easy"
	const NORMAL = "normal"
	const HARD = "hard"
	const ALL = [EASY, NORMAL, HARD]
	const DEFAULT = EASY
	const NAMES = {
		EASY: "DIFFICULTY_EASY",
		NORMAL: "DIFFICULTY_NORMAL",
		HARD: "DIFFICULTY_HARD",
	}
	# applied to every AI player; build_speed scales its production and construction;
	# secondary_offensive_structure: SimpleClairvoyantAI.OffensiveStructure
	# (0 war factory, 1 helipad, 2 barracks, 3 airfield)
	const SETTINGS = {
		EASY:
		{
			"secondary_offensive_structure": 2,
			"start_delay_s": 120.0,
			"build_speed": 0.5,
			"expected_number_of_ag_turrets": 1,
			"expected_number_of_aa_turrets": 1,
			"expected_number_of_battlegroups": 1,
			"expected_number_of_units_in_battlegroup": 3,
		},
		NORMAL:
		{
			"secondary_offensive_structure": 3,
			"start_delay_s": 45.0,
			"build_speed": 0.75,
			"expected_number_of_ag_turrets": 1,
			"expected_number_of_aa_turrets": 1,
			"expected_number_of_battlegroups": 2,
			"expected_number_of_units_in_battlegroup": 4,
		},
		HARD:
		{
			"secondary_offensive_structure": 3,
			"start_delay_s": 0.0,
			"build_speed": 1.0,
			"expected_number_of_ag_turrets": 2,
			"expected_number_of_aa_turrets": 2,
			"expected_number_of_battlegroups": 3,
			"expected_number_of_units_in_battlegroup": 6,
		},
	}


class Match:
	extends "res://source/match/MatchConstants.gd"

	class Player:
		const CONTROLLER_SCENES = {
			PlayerType.HUMAN: preload("res://source/match/players/human/Human.tscn"),
			PlayerType.SIMPLE_CLAIRVOYANT_AI:
			preload("res://source/match/players/simple-clairvoyant-ai/SimpleClairvoyantAI.tscn"),
		}


class Player:
	const COLORS = [
		Color("66b1ff"),
		Color("ff5c73"),
		Color("a5ff99"),
		Color("ed85ff"),
		Color("006400"),
		Color("bdb76b"),
		Color("000080"),
		Color("48d1cc"),
		# TODO: make sure the colors below are visually distinct from the ones above
		Color("ff0000"),
		Color("ffa500"),
		Color("ffff00"),
		Color("00ff00"),
		Color("00fa9a"),
		Color("0000ff"),
		Color("da70d6"),
		Color("d8bfd8"),
		Color("ff00ff"),
		Color("1e90ff"),
		Color("fa8072"),
		Color("2f4f4f"),
	]


# gdlint: ignore=class-variable-name
var OPTIONS_FILE_PATH:
	set(_value):
		pass
	get:
		return (
			"user://options.tres"
			if not FeatureFlags.save_user_files_in_tmp
			else "res://tmp/options.tres"
		)
