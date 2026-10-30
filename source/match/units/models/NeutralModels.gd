# Faction-neutral models: resource deposits (supply crates, fuel drums).
const K = preload("res://source/match/units/models/ModelKit.gd")
const P = K.Palette

const CRATE_DARK = Color("6e5232")
const DRUM_RED = Color("9c3f2a")
const DRUM_OLIVE = Color("525b37")
const DRUM_BLUE = Color("3e5466")


static func builders():
	return {
		"ResourceA": func(): return supply_crates(),
		"ResourceB": func(): return fuel_drums(),
	}


## Supplies: two pallets of wooden crates, ammo boxes and a tarp-covered stack.
static func supply_crates():
	var root = Node3D.new()
	var b = K.builder()
	for pallet in [Vector3(-0.22, 0, 0.12), Vector3(0.32, 0, -0.22)]:
		b.box(K.xf(pallet + Vector3(0, 0.03, 0)), Vector3(0.56, 0.06, 0.46), CRATE_DARK)
	# pallet 1: 2x2 crates + one on top
	for x in [-0.12, 0.12]:
		for z in [-0.1, 0.1]:
			_crate(b, Vector3(-0.22 + x, 0.06, 0.12 + z), Vector3(0.23, 0.2, 0.19), 0.0)
	_crate(b, Vector3(-0.2, 0.26, 0.12), Vector3(0.26, 0.18, 0.2), 12.0)
	# pallet 2: tarp-covered stack strapped down
	b.tapered_box(
		K.xf(Vector3(0.32, 0.06, -0.22)), Vector2(0.5, 0.4), Vector2(0.42, 0.32), 0.3, P.US_OLIVE
	)
	for x in [0.2, 0.44]:
		b.box(K.xf(Vector3(x, 0.21, -0.22)), Vector3(0.025, 0.31, 0.41), P.DARK)
	# loose ammo boxes
	b.box(K.xf(Vector3(0.36, 0.05, 0.28), Vector3(0, 25, 0)), Vector3(0.22, 0.1, 0.12), DRUM_OLIVE)
	b.box(K.xf(Vector3(0.36, 0.15, 0.28), Vector3(0, 15, 0)), Vector3(0.22, 0.1, 0.12), DRUM_OLIVE)
	b.box(K.xf(Vector3(-0.42, 0.05, -0.3), Vector3(0, -30, 0)), Vector3(0.2, 0.1, 0.12), DRUM_OLIVE)
	root.add_child(K.mesh_node("Body", b))
	return root


## Fuel: a cluster of 200 l drums (some lying), a jerrycan pile and a hand pump.
static func fuel_drums():
	var root = Node3D.new()
	var b = K.builder()
	var standing = [
		[Vector3(-0.2, 0, -0.16), DRUM_RED],
		[Vector3(0.08, 0, -0.22), DRUM_RED],
		[Vector3(-0.06, 0, 0.08), DRUM_OLIVE],
		[Vector3(0.22, 0, 0.04), DRUM_RED],
		[Vector3(-0.32, 0, 0.12), DRUM_BLUE],
		[Vector3(0.04, 0, 0.34), DRUM_RED],
	]
	for drum in standing:
		_drum(b, drum[0], drum[1])
	b.cylinder(
		K.xf(Vector3(0.38, 0.12, -0.32), Vector3(0, 30, 90)), 0.12, 0.12, 0.34, DRUM_OLIVE, 10
	)
	b.cylinder(
		K.xf(Vector3(0.38, 0.12, -0.32), Vector3(0, 30, 90), Vector3(1.04, 0.2, 1.04)),
		0.12,
		0.12,
		0.34,
		P.DARK,
		10,
		true,
		false
	)
	for i in range(3):  # jerrycans
		b.box(
			K.xf(Vector3(-0.36 + i * 0.1, 0.09, 0.38), Vector3(0, 10, 0)),
			Vector3(0.08, 0.18, 0.13),
			DRUM_OLIVE
		)
	b.cylinder(K.xf(Vector3(-0.06, 0.48, 0.08)), 0.012, 0.012, 0.14, P.METAL, 4)  # hand pump
	b.box(K.xf(Vector3(-0.03, 0.55, 0.08)), Vector3(0.08, 0.02, 0.02), P.METAL)
	root.add_child(K.mesh_node("Body", b))
	return root


static func _crate(b, base, size, yaw):
	b.box(K.xf(base + Vector3(0, size.y * 0.5, 0), Vector3(0, yaw, 0)), size, P.WOOD)
	b.box(  # dark band
		K.xf(base + Vector3(0, size.y * 0.5, 0), Vector3(0, yaw, 0)),
		Vector3(size.x + 0.006, size.y * 0.18, size.z + 0.006),
		CRATE_DARK
	)


static func _drum(b, base, color):
	b.cylinder(K.xf(base + Vector3(0, 0.18, 0)), 0.12, 0.12, 0.36, color, 10)
	for y in [0.12, 0.24]:  # rolling hoops
		b.cylinder(K.xf(base + Vector3(0, y, 0)), 0.124, 0.124, 0.015, P.DARK, 10, true, false)
	b.cylinder(K.xf(base + Vector3(0.05, 0.365, 0.02)), 0.02, 0.02, 0.012, P.DARK, 6)
