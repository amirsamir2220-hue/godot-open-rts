# Renders faction unit models to PNG icons with a transparent background.
#
# Run (needs a GPU / OpenGL context, not --headless):
#   godot res://source/utils/IconRenderBooth.tscn
#   godot res://source/utils/IconRenderBooth.tscn -- out_dir=/tmp/icons size=512 types=Tank,Worker
# Icons are written to `<out_dir>/<faction>/<Type>.png` (default: res://assets/ui/icons);
# faction-neutral models (resources) go to `<out_dir>/neutral/`.
extends Node3D

const FactionModels = preload("res://source/match/units/models/FactionModels.gd")

const TYPES = [
	"Worker",
	"Tank",
	"Helicopter",
	"Drone",
	"CommandCenter",
	"VehicleFactory",
	"AircraftFactory",
	"AntiGroundTurret",
	"AntiAirTurret",
]
const NEUTRAL_TYPES = ["ResourceA", "ResourceB"]
const VIEW_DIRECTION = Vector3(-1.0, 0.9, -1.0)  # from the front-left, like the match camera
const SUPERSAMPLING = 2

@export var output_dir = "res://assets/ui/icons"
@export var icon_size = 128
@export var team_color = Color("d9c38a")

@onready var _viewport = $SubViewport
@onready var _camera = $SubViewport/Camera3D
@onready var _stage = $SubViewport/Stage


func _ready():
	var args = _parse_args()
	output_dir = args.get("out_dir", output_dir)
	icon_size = int(args.get("size", icon_size))
	var types = args["types"].split(",") if args.has("types") else TYPES
	await render_all(types, Constants.Faction.ALL)
	if not args.has("types"):
		await render_all(NEUTRAL_TYPES, [FactionModels.NEUTRAL])
	get_tree().quit()


func render_all(types, factions):
	for faction in factions:
		DirAccess.make_dir_recursive_absolute(output_dir.path_join(faction))
		for type in types:
			var image = await render(type, faction)
			if image == null:
				continue
			var path = output_dir.path_join(faction).path_join("{0}.png".format([type]))
			image.save_png(path)
			print("icon saved: ", path)


func render(type, faction):
	var model = FactionModels.build(type, faction)
	if model == null:
		return null
	_viewport.size = Vector2i(icon_size, icon_size) * SUPERSAMPLING
	_stage.add_child(model)
	var team_material = StandardMaterial3D.new()
	team_material.albedo_color = team_color
	team_material.roughness = 0.55
	FactionModels.apply_team_color(model, team_material)
	_frame(model)
	for _i in range(3):
		await RenderingServer.frame_post_draw
	var image = _viewport.get_texture().get_image()
	image.resize(icon_size, icon_size, Image.INTERPOLATE_LANCZOS)
	_stage.remove_child(model)
	model.free()
	return image


func _frame(model):
	var aabb = _model_aabb(model)
	var center = aabb.get_center()
	var direction = VIEW_DIRECTION.normalized()
	_camera.look_at_from_position(center + direction * 20.0, center, Vector3.UP)
	# fit the AABB corners into the orthographic view
	var extent = 0.0
	for i in range(8):
		var corner = _camera.global_transform.affine_inverse() * aabb.get_endpoint(i)
		extent = max(extent, abs(corner.x), abs(corner.y))
	_camera.size = extent * 2.0 * 1.08


func _model_aabb(model):
	var aabb = null
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var node_aabb = node.global_transform * node.get_aabb()
		aabb = node_aabb if aabb == null else aabb.merge(node_aabb)
	return aabb if aabb != null else AABB(Vector3(-1, 0, -1), Vector3(2, 1, 2))


func _parse_args():
	var args = {}
	for arg in OS.get_cmdline_user_args():
		var key_value = arg.split("=", true, 1)
		args[key_value[0]] = key_value[1] if key_value.size() > 1 else ""
	return args
