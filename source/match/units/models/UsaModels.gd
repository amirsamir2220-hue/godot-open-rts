# USA faction models, built in code. Forward is -Z, up is +Y, 1 unit ~ 4-5 m in game scale.
const K = preload("res://source/match/units/models/ModelKit.gd")
const P = K.Palette
const TEAM = K.TEAM


static func builders():
	return {
		"Worker": func(): return worker(),
		"Tank": func(): return tank(),
		"Helicopter": func(): return helicopter(),
		"Drone": func(): return drone(),
		"CommandCenter": func(): return command_center(),
		"VehicleFactory": func(): return vehicle_factory(),
		"AircraftFactory": func(): return aircraft_factory(),
		"AntiGroundTurret": func(): return anti_ground_turret(),
		"AntiAirTurret": func(): return anti_air_turret(),
	}


## HEMTT M977: 8x8, flat-nosed cab, cargo bed with supply crates.
static func worker():
	var root = Node3D.new()
	var b = K.builder()
	b.box(K.xf(Vector3(0, 0.2, 0.02)), Vector3(0.5, 0.08, 1.36), P.DARK)  # chassis
	for z in [-0.5, -0.3, 0.26, 0.47]:
		for x in [-0.3, 0.3]:
			b.wheel(Vector3(x, 0.13, z), 0.13, 0.1, P.RUBBER, P.US_TAN_DARK)
	# cab
	b.box(K.xf(Vector3(0, 0.42, -0.5)), Vector3(0.66, 0.38, 0.38), P.US_TAN)
	b.box(K.xf(Vector3(0, 0.5, -0.692)), Vector3(0.56, 0.14, 0.02), P.GLASS)
	for x in [-0.332, 0.332]:
		b.box(K.xf(Vector3(x, 0.5, -0.52)), Vector3(0.01, 0.12, 0.2), P.GLASS)
		b.box(K.xf(Vector3(x, 0.36, -0.5)), Vector3(0.012, 0.07, 0.3), TEAM)
	b.box(K.xf(Vector3(0, 0.27, -0.7)), Vector3(0.68, 0.08, 0.04), P.DARK)  # bumper
	b.box(K.xf(Vector3(0, 0.62, -0.5)), Vector3(0.5, 0.02, 0.3), TEAM)  # roof marker
	b.cylinder(K.xf(Vector3(0.28, 0.62, -0.28)), 0.025, 0.025, 0.3, P.DARK, 6)  # exhaust
	# cargo bed with supply crates
	b.box(K.xf(Vector3(0, 0.3, 0.24)), Vector3(0.66, 0.08, 0.94), P.US_TAN_DARK)
	for x in [-0.325, 0.325]:
		b.box(K.xf(Vector3(x, 0.38, 0.24)), Vector3(0.02, 0.1, 0.94), P.US_TAN)
	b.box(K.xf(Vector3(0, 0.44, 0.04)), Vector3(0.5, 0.2, 0.3), P.WOOD)
	b.box(K.xf(Vector3(0, 0.44, 0.42)), Vector3(0.5, 0.2, 0.3), P.WOOD)
	b.box(K.xf(Vector3(0, 0.6, 0.23)), Vector3(0.4, 0.12, 0.26), P.US_OLIVE)
	# loader crane at the rear
	b.box(K.xf(Vector3(0.22, 0.5, 0.66), Vector3(30, 0, 0)), Vector3(0.06, 0.06, 0.3), P.YELLOW)
	root.add_child(K.mesh_node("Body", b))
	return root


## M1A2 Abrams: angular wide turret, long gun, bustle rack.
static func tank():
	var root = Node3D.new()
	var b = K.builder()
	for side in [-1, 1]:
		var x = side * 0.47
		b.box(K.xf(Vector3(x, 0.15, 0)), Vector3(0.26, 0.24, 1.76), P.DARK)
		b.cylinder(K.xf(Vector3(x, 0.15, -0.88), Vector3(0, 0, 90)), 0.12, 0.12, 0.26, P.DARK)
		b.cylinder(K.xf(Vector3(x, 0.15, 0.88), Vector3(0, 0, 90)), 0.12, 0.12, 0.26, P.DARK)
		b.box(K.xf(Vector3(side * 0.5, 0.26, -0.08)), Vector3(0.28, 0.14, 1.66), P.US_TAN_DARK)
	b.tapered_box(
		K.xf(Vector3(0, 0.2, 0)),
		Vector2(0.9, 1.96),
		Vector2(1.16, 1.7),
		0.24,
		P.US_TAN,
		Vector2(0, 0.1)
	)
	b.box(K.xf(Vector3(0, 0.45, 0.68)), Vector3(0.9, 0.03, 0.42), P.US_TAN_DARK)  # engine deck
	b.box(K.xf(Vector3(0, 0.3, 0.97)), Vector3(0.9, 0.16, 0.04), P.DARK)  # exhaust grille
	root.add_child(K.mesh_node("Body", b))

	var turret = K.add(root, K.pivot("Turret", K.xf(Vector3(0, 0.44, 0.05))))
	var t = K.builder()
	t.tapered_box(
		K.xf(Vector3(0, 0, -0.04)),
		Vector2(0.96, 1.2),
		Vector2(0.78, 0.86),
		0.22,
		P.US_TAN,
		Vector2(0, 0.13)
	)
	t.box(K.xf(Vector3(0, 0.1, 0.66)), Vector3(0.82, 0.13, 0.22), P.US_TAN_DARK)  # bustle rack
	t.box(K.xf(Vector3(0, 0.225, 0.2)), Vector3(0.5, 0.01, 0.3), TEAM)
	for side in [-1, 1]:
		t.box(K.xf(Vector3(side * 0.412, 0.1, 0.66)), Vector3(0.01, 0.06, 0.2), TEAM)
	t.box(K.xf(Vector3(0, 0.1, -0.64)), Vector3(0.22, 0.14, 0.12), P.US_TAN_DARK)  # mantlet
	t.cylinder(K.xf(Vector3(0, 0.1, -1.18), Vector3(90, 0, 0)), 0.034, 0.034, 1.0, P.GUNMETAL, 6)
	t.cylinder(K.xf(Vector3(0, 0.1, -0.98), Vector3(90, 0, 0)), 0.05, 0.05, 0.16, P.US_TAN_DARK, 6)
	t.cylinder(K.xf(Vector3(0.22, 0.27, 0.08)), 0.09, 0.08, 0.08, P.US_TAN_DARK)  # cupola
	t.box(K.xf(Vector3(0.22, 0.34, 0.06)), Vector3(0.08, 0.07, 0.14), P.DARK)  # CROWS
	t.cylinder(K.xf(Vector3(0.22, 0.35, -0.08), Vector3(90, 0, 0)), 0.012, 0.012, 0.18, P.DARK, 4)
	t.box(K.xf(Vector3(-0.26, 0.26, -0.28)), Vector3(0.13, 0.08, 0.14), P.US_TAN_DARK)  # GPS sight
	t.cylinder(K.xf(Vector3(-0.32, 0.45, 0.5)), 0.006, 0.006, 0.5, P.DARK, 4)  # antennas
	t.cylinder(K.xf(Vector3(0.32, 0.4, 0.55)), 0.006, 0.006, 0.4, P.DARK, 4)
	turret.add_child(K.mesh_node("Mesh", t))
	turret.add_child(K.marker("ProjectileOrigin", Vector3(0, 0.1, -1.7)))
	return root


## AH-64 Apache: narrow body, stepped tandem canopy, stub wings, 4-blade rotor.
static func helicopter():
	var root = Node3D.new()
	var b = K.builder()
	var body = P.US_OLIVE
	# fuselage (tapered boxes rotated so their "height" runs along Z)
	b.tapered_box(
		K.xf(Vector3(0, 0.18, 0.32), Vector3(-90, 0, 0)),
		Vector2(0.32, 0.34),
		Vector2(0.3, 0.3),
		0.66,
		body
	)
	b.tapered_box(
		K.xf(Vector3(0, 0.17, -0.34), Vector3(-90, 0, 0)),
		Vector2(0.3, 0.3),
		Vector2(0.14, 0.16),
		0.46,
		body
	)
	b.box(K.xf(Vector3(0, 0.33, -0.6)), Vector3(0.18, 0.09, 0.22), P.GLASS)  # gunner
	b.box(K.xf(Vector3(0, 0.39, -0.37)), Vector3(0.21, 0.12, 0.24), P.GLASS)  # pilot
	b.box(K.xf(Vector3(0, 0.12, -0.83)), Vector3(0.12, 0.11, 0.1), P.DARK)  # TADS
	b.cylinder(K.xf(Vector3(0, 0.0, -0.58), Vector3(90, 0, 0)), 0.015, 0.015, 0.24, P.DARK, 4)
	for side in [-1, 1]:
		b.box(K.xf(Vector3(side * 0.21, 0.36, 0.08)), Vector3(0.13, 0.14, 0.46), body)  # engines
		b.box(K.xf(Vector3(side * 0.215, 0.36, 0.08)), Vector3(0.135, 0.04, 0.3), TEAM)
		b.box(K.xf(Vector3(side * 0.42, 0.14, -0.04)), Vector3(0.08, 0.09, 0.26), P.DARK)  # Hellfires
		b.cylinder(
			K.xf(Vector3(side * 0.28, 0.15, -0.04), Vector3(90, 0, 0)),
			0.055,
			0.055,
			0.26,
			P.DARK,
			6
		)
		b.wheel(Vector3(side * 0.18, -0.06, -0.3), 0.05, 0.04, P.RUBBER, P.METAL, 6)
	b.box(K.xf(Vector3(0, 0.21, -0.04)), Vector3(0.94, 0.03, 0.17), body)  # stub wings
	# tail
	b.tapered_box(
		K.xf(Vector3(0, 0.22, 0.32), Vector3(90, 0, 0)),
		Vector2(0.18, 0.2),
		Vector2(0.07, 0.1),
		0.86,
		body
	)
	b.tapered_box(
		K.xf(Vector3(0, 0.2, 1.14)),
		Vector2(0.03, 0.24),
		Vector2(0.03, 0.14),
		0.34,
		body,
		Vector2(0, 0.07)
	)
	b.box(K.xf(Vector3(0.016, 0.38, 1.2)), Vector3(0.004, 0.1, 0.1), TEAM)
	b.box(K.xf(Vector3(0, 0.22, 1.1)), Vector3(0.38, 0.02, 0.1), body)
	b.wheel(Vector3(0, 0.06, 1.08), 0.035, 0.03, P.RUBBER, P.METAL, 6)
	b.cylinder(K.xf(Vector3(0, 0.47, -0.05)), 0.03, 0.03, 0.1, P.METAL, 6)  # mast
	root.add_child(K.mesh_node("Body", b))
	root.add_child(K.marker("ProjectileOrigin", Vector3(0, 0.12, -0.6)))

	var rotor = K.add(root, K.pivot("Rotor", K.xf(Vector3(0, 0.53, -0.05))))
	var r = K.builder()
	r.cylinder(K.xf(), 0.06, 0.05, 0.05, P.METAL, 6)
	for angle in [0, 90, 180, 270]:
		r.box(
			K.xf(Vector3(0, 0, 0), Vector3(0, angle, 0)) * K.xf(Vector3(0, 0, -0.46)),
			Vector3(0.06, 0.012, 0.86),
			P.DARK
		)
	rotor.add_child(K.mesh_node("Mesh", r))

	var tail_rotor = K.add(
		root, K.spinner("TailRotor", K.xf(Vector3(0.05, 0.42, 1.2)), Vector3.RIGHT, 1600.0)
	)
	var tr = K.builder()
	for angle in [0, 55, 180, 235]:
		tr.box(
			K.xf(Vector3.ZERO, Vector3(angle, 0, 0)) * K.xf(Vector3(0, 0.09, 0)),
			Vector3(0.01, 0.18, 0.03),
			P.DARK
		)
	tail_rotor.add_child(K.mesh_node("Mesh", tr))
	return root


## RQ-7 Shadow: high wing, twin booms, inverted-V tail, pusher prop.
static func drone():
	var root = Node3D.new()
	var b = K.builder()
	var c = P.US_GRAY
	b.tapered_box(
		K.xf(Vector3(0, 0.1, 0.18), Vector3(-90, 0, 0)),
		Vector2(0.12, 0.12),
		Vector2(0.09, 0.08),
		0.52,
		c
	)
	b.box(K.xf(Vector3(0, 0.165, -0.06)), Vector3(1.2, 0.02, 0.13), c)
	for side in [-1, 1]:
		b.box(K.xf(Vector3(side * 0.54, 0.168, -0.06)), Vector3(0.1, 0.022, 0.135), TEAM)
		b.box(K.xf(Vector3(side * 0.16, 0.15, 0.3)), Vector3(0.025, 0.025, 0.66), c)
		b.box(
			K.xf(Vector3(side * 0.09, 0.2, 0.6), Vector3(0, 0, -side * 35)),
			Vector3(0.2, 0.012, 0.09),
			c
		)
	b.dome(K.xf(Vector3(0, 0.04, -0.28)), 0.04, P.DARK, 2, 6, true)  # sensor ball
	root.add_child(K.mesh_node("Body", b))
	var prop = K.add(root, K.spinner("Propeller", K.xf(Vector3(0, 0.1, 0.2)), Vector3.BACK, 2000.0))
	var p = K.builder()
	p.box(K.xf(), Vector3(0.28, 0.03, 0.01), P.DARK)
	prop.add_child(K.mesh_node("Mesh", p))
	return root


## Command HQ: sand concrete block, comms mast and dish, Hesco barriers.
static func command_center():
	var root = Node3D.new()
	var b = K.builder()
	var wall = P.US_BUILDING
	b.box(K.xf(Vector3(0, 0.03, 0)), Vector3(3.6, 0.06, 3.6), P.CONCRETE_DARK)
	b.box(K.xf(Vector3(0.1, 0.5, 0.3)), Vector3(2.6, 0.9, 1.8), wall)
	b.box(K.xf(Vector3(0.1, 0.97, 0.3)), Vector3(2.7, 0.06, 1.9), P.CONCRETE)  # roof slab
	b.box(K.xf(Vector3(-0.2, 0.32, -0.9)), Vector3(1.5, 0.54, 0.6), wall)  # front wing
	b.box(K.xf(Vector3(-0.2, 0.61, -0.9)), Vector3(1.6, 0.05, 0.7), P.CONCRETE)
	b.box(K.xf(Vector3(-0.2, 0.22, -1.205)), Vector3(0.4, 0.34, 0.02), P.DARK)  # door
	for i in range(5):
		var z = -0.45 + i * 0.38
		b.box(K.xf(Vector3(1.405, 0.62, z)), Vector3(0.02, 0.16, 0.22), P.GLASS)
		b.box(K.xf(Vector3(-1.205, 0.62, z)), Vector3(0.02, 0.16, 0.22), P.GLASS)
	b.box(K.xf(Vector3(0.1, 1.005, -0.5)), Vector3(2.5, 0.01, 0.16), TEAM)  # roof stripe
	b.box(K.xf(Vector3(0.9, 1.08, -0.2)), Vector3(0.3, 0.16, 0.24), P.METAL)  # AC units
	b.box(K.xf(Vector3(0.9, 1.08, 0.2)), Vector3(0.3, 0.16, 0.24), P.METAL)
	# comms mast
	b.tapered_box(
		K.xf(Vector3(-0.8, 1.0, 0.85)), Vector2(0.22, 0.22), Vector2(0.04, 0.04), 0.95, P.METAL
	)
	b.cylinder(K.xf(Vector3(-0.8, 1.6, 0.85)), 0.008, 0.008, 1.2, P.DARK, 4)
	# satellite dish
	b.cylinder(K.xf(Vector3(-0.6, 1.08, -0.1)), 0.03, 0.03, 0.16, P.METAL, 6)
	b.dome(
		K.xf(Vector3(-0.6, 1.2, -0.1), Vector3(-130, 0, 0), Vector3(1, 0.35, 1)),
		0.22,
		P.WHITE,
		2,
		8
	)
	# flag pole with team flag
	b.cylinder(K.xf(Vector3(-1.5, 0.75, -1.5)), 0.015, 0.015, 1.5, P.METAL, 4)
	b.box(K.xf(Vector3(-1.32, 1.36, -1.5)), Vector3(0.34, 0.2, 0.01), TEAM)
	# Hesco barriers along the front
	for i in range(6):
		b.box(K.xf(Vector3(0.35 + i * 0.25, 0.14, -1.55)), Vector3(0.22, 0.24, 0.22), P.SANDBAG)
	root.add_child(K.mesh_node("Body", b))
	return root


## War factory: arched hangar with a big door and a side workshop.
static func vehicle_factory():
	var root = Node3D.new()
	var b = K.builder()
	b.box(K.xf(Vector3(0, 0.03, 0)), Vector3(2.9, 0.06, 2.9), P.CONCRETE_DARK)
	b.box(K.xf(Vector3(-0.25, 0.3, 0.1)), Vector3(1.9, 0.5, 2.3), P.US_TAN)
	b.cylinder(
		K.xf(Vector3(-0.25, 0.55, 0.1), Vector3(90, 0, 0), Vector3(0.95, 1, 0.5)),
		1.0,
		1.0,
		2.3,
		P.US_TAN_DARK,
		12
	)
	b.box(K.xf(Vector3(-0.25, 0.42, -1.06)), Vector3(1.3, 0.72, 0.02), P.DARK)  # door
	b.box(K.xf(Vector3(-0.25, 0.86, -1.07)), Vector3(1.4, 0.08, 0.02), TEAM)
	b.tapered_box(
		K.xf(Vector3(-0.25, 0.06, -1.3)), Vector2(1.3, 0.5), Vector2(1.3, 0.1), 0.04, P.ASPHALT
	)
	b.box(K.xf(Vector3(1.05, 0.32, 0.5)), Vector3(0.7, 0.56, 1.1), P.US_BUILDING)  # workshop
	b.box(K.xf(Vector3(1.05, 0.61, 0.5)), Vector3(0.76, 0.04, 1.16), P.CONCRETE)
	b.box(K.xf(Vector3(1.05, 0.63, 0.5)), Vector3(0.7, 0.01, 0.12), TEAM)
	b.cylinder(K.xf(Vector3(1.2, 0.95, 0.85)), 0.06, 0.06, 0.7, P.METAL, 6)  # stack
	b.box(K.xf(Vector3(1.05, 0.3, -0.5)), Vector3(0.5, 0.5, 0.5), P.WOOD)  # parts crates
	root.add_child(K.mesh_node("Body", b))
	return root


## Helipad: square pad with H marking, small control tower, windsock.
static func aircraft_factory():
	var root = Node3D.new()
	var b = K.builder()
	b.box(K.xf(Vector3(0, 0.04, 0)), Vector3(2.8, 0.08, 2.8), P.CONCRETE_DARK)
	b.cylinder(K.xf(Vector3(-0.15, 0.085, 0.15)), 1.0, 1.0, 0.01, P.YELLOW, 16, false)
	b.cylinder(K.xf(Vector3(-0.15, 0.09, 0.15)), 0.92, 0.92, 0.01, P.ASPHALT, 16, false)
	for x in [-0.4, 0.1]:
		b.box(K.xf(Vector3(x, 0.1, 0.15)), Vector3(0.14, 0.01, 0.9), P.WHITE)
	b.box(K.xf(Vector3(-0.15, 0.1, 0.15)), Vector3(0.5, 0.01, 0.14), P.WHITE)
	for corner in [Vector3(-1.3, 0, -1.3), Vector3(1.3, 0, 1.3), Vector3(-1.3, 0, 1.3)]:
		b.box(K.xf(corner + Vector3(0, 0.12, 0)), Vector3(0.12, 0.08, 0.12), TEAM)
	# control tower
	b.box(K.xf(Vector3(1.1, 0.45, -1.1)), Vector3(0.4, 0.8, 0.4), P.US_BUILDING)
	b.box(K.xf(Vector3(1.1, 0.95, -1.1)), Vector3(0.5, 0.2, 0.5), P.GLASS)
	b.box(K.xf(Vector3(1.1, 1.07, -1.1)), Vector3(0.56, 0.04, 0.56), TEAM)
	# fuel bladder and windsock
	b.box(K.xf(Vector3(1.15, 0.14, 0.6)), Vector3(0.36, 0.14, 0.7), P.US_OLIVE)
	b.cylinder(K.xf(Vector3(-1.2, 0.5, -1.0)), 0.012, 0.012, 1.0, P.METAL, 4)
	b.cylinder(K.xf(Vector3(-1.08, 0.95, -1.0), Vector3(0, 0, 80)), 0.05, 0.025, 0.24, P.ORANGE, 6)
	root.add_child(K.mesh_node("Body", b))
	return root


## Javelin post: sandbag ring with a Javelin on a tripod.
static func anti_ground_turret():
	var root = Node3D.new()
	var b = K.builder()
	K.sandbag_ring(b, 0.46, 10, 2)
	for angle in [0, 120, 240]:
		b.cylinder(
			(
				K.xf(Vector3(0, 0.12, 0), Vector3(0, angle, 0))
				* K.xf(Vector3(0, 0, 0.06), Vector3(20, 0, 0))
			),
			0.01,
			0.01,
			0.26,
			P.DARK,
			4
		)
	root.add_child(K.mesh_node("Body", b))

	var turret = K.add(root, K.pivot("Turret", K.xf(Vector3(0, 0.27, 0))))
	var t = K.builder()
	t.box(K.xf(Vector3(0.06, 0.02, 0.04)), Vector3(0.12, 0.1, 0.14), P.US_JAVELIN)  # CLU
	t.box(K.xf(Vector3(0.06, 0.02, -0.035)), Vector3(0.08, 0.06, 0.01), P.GLASS)
	t.cylinder(
		K.xf(Vector3(-0.04, 0.03, -0.05), Vector3(90, 0, 0)), 0.055, 0.055, 0.62, P.US_JAVELIN, 8
	)
	t.cylinder(K.xf(Vector3(-0.04, 0.03, 0.12), Vector3(90, 0, 0)), 0.058, 0.058, 0.06, TEAM, 8)
	turret.add_child(K.mesh_node("Mesh", t))
	turret.add_child(K.marker("ProjectileOrigin", Vector3(-0.04, 0.03, -0.38)))
	return root


## Patriot battery: launcher trailer with four elevated canisters and a radar panel.
static func anti_air_turret():
	var root = Node3D.new()
	var b = K.builder()
	b.box(K.xf(Vector3(0, 0.03, 0)), Vector3(1.1, 0.06, 1.1), P.CONCRETE_DARK)
	b.box(K.xf(Vector3(0, 0.16, 0.05)), Vector3(0.6, 0.12, 0.9), P.US_TAN_DARK)
	for z in [0.3, 0.42]:
		for x in [-0.32, 0.32]:
			b.wheel(Vector3(x, 0.1, z), 0.09, 0.06, P.RUBBER, P.METAL, 6)
	for x in [-0.32, 0.32]:
		b.box(K.xf(Vector3(x, 0.1, -0.35)), Vector3(0.04, 0.16, 0.04), P.DARK)  # outriggers
	b.box(K.xf(Vector3(0.38, 0.32, 0.42), Vector3(-15, 0, 0)), Vector3(0.22, 0.3, 0.03), P.US_TAN)
	b.box(K.xf(Vector3(0.38, 0.32, 0.405), Vector3(-15, 0, 0)), Vector3(0.18, 0.26, 0.01), P.DARK)
	root.add_child(K.mesh_node("Body", b))

	var turret = K.add(root, K.pivot("Turret", K.xf(Vector3(0, 0.24, 0.1))))
	var t = K.builder()
	t.box(K.xf(Vector3(0, 0.03, 0)), Vector3(0.3, 0.06, 0.3), P.US_TAN_DARK)
	var launcher = K.xf(Vector3(0, 0.08, 0.1), Vector3(35, 0, 0))
	t.push(launcher)
	t.box(K.xf(Vector3(0, 0.15, -0.3)), Vector3(0.46, 0.34, 0.84), P.US_TAN)
	for x in [-0.232, 0.232]:
		t.box(K.xf(Vector3(x, 0.15, -0.3)), Vector3(0.01, 0.08, 0.6), TEAM)
	for x in [-0.11, 0.11]:
		for y in [0.07, 0.23]:
			t.cylinder(K.xf(Vector3(x, y, -0.721), Vector3(90, 0, 0)), 0.07, 0.07, 0.01, P.DARK, 8)
	t.pop()
	turret.add_child(K.mesh_node("Mesh", t))
	turret.add_child(K.marker("ProjectileOrigin", launcher * Vector3(0.11, 0.23, -0.76)))
	return root
