# Faction-aware UI helpers: unit display names, tooltips and icons.
#
# Display names are translation keys "<FACTION>_<KEY>" (e.g. "USA_TANK" -> "M1A2 Abrams");
# descriptions are shared ("TANK_DESCRIPTION"). Icons are rendered by
# source/utils/IconRenderBooth.tscn into res://assets/ui/icons/<faction>/<Type>.png.
const ICONS_DIR = "res://assets/ui/icons"
const NEUTRAL = "neutral"

const TEXT_KEYS = {
	"Worker": "WORKER",
	"Tank": "TANK",
	"Helicopter": "HELICOPTER",
	"Drone": "DRONE",
	"CommandCenter": "CC",
	"VehicleFactory": "VEHICLE_FACTORY",
	"AircraftFactory": "AIRCRAFT_FACTORY",
	"AntiGroundTurret": "AG_TURRET",
	"AntiAirTurret": "AA_TURRET",
	"Humvee": "HUMVEE",
	"Rifleman": "RIFLEMAN",
	"AntiTankSoldier": "AT_SOLDIER",
	"Fighter": "FIGHTER",
	"StrikeFighter": "STRIKE_FIGHTER",
	"StealthFighter": "STEALTH_FIGHTER",
	"Barracks": "BARRACKS",
	"Airfield": "AIRFIELD",
}

static var _icon_cache = {}


static func unit_type(unit_scene_or_path):
	var path = (
		unit_scene_or_path if unit_scene_or_path is String else unit_scene_or_path.resource_path
	)
	return path.get_file().get_basename()


static func faction_of(unit):
	if unit != null and is_instance_valid(unit) and unit.player != null:
		var faction = unit.player.get("faction")
		if faction != null:
			return faction
	return Constants.Faction.DEFAULT


static func unit_name(type, faction):
	return TranslationServer.translate("{0}_{1}".format([faction.to_upper(), TEXT_KEYS[type]]))


static func unit_description(type):
	return TranslationServer.translate("{0}_DESCRIPTION".format([TEXT_KEYS[type]]))


static func icon(type, faction):
	var path = ICONS_DIR.path_join(faction).path_join("{0}.png".format([type]))
	if not path in _icon_cache:
		_icon_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _icon_cache[path]


## "<name> - <description>\n<hp> HP[, <dps> DPS]\nSupplies: <a>, Fuel: <b>"
static func tooltip(unit_scene, faction, costs_table):
	var type = unit_type(unit_scene)
	var properties = Constants.Match.Units.DEFAULT_PROPERTIES[unit_scene.resource_path]
	var costs = costs_table[unit_scene.resource_path]
	var stats = "{0} HP".format([properties["hp_max"]])
	if properties.has("attack_damage"):
		var dps = float(properties["attack_damage"]) / float(properties["attack_interval"])
		stats += ", {0} DPS".format([snapped(dps, 0.1)])
	return (
		"{0} - {1}\n{2}\n{3}: {4}, {5}: {6}"
		. format(
			[
				unit_name(type, faction),
				unit_description(type),
				stats,
				TranslationServer.translate("RESOURCE_A"),
				costs["resource_a"],
				TranslationServer.translate("RESOURCE_B"),
				costs["resource_b"],
			]
		)
	)


## Turns a production/construction button into an icon button with a faction tooltip.
static func setup_button(button, unit_scene, faction, costs_table):
	button.tooltip_text = tooltip(unit_scene, faction, costs_table)
	var texture = icon(unit_type(unit_scene), faction)
	if texture != null:
		button.icon = texture
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.text = ""
		button.custom_minimum_size = Vector2(48, 48)
