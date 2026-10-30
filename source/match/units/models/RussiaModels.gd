# Russia faction models, built in code. Forward is -Z, up is +Y, 1 unit ~ 4-5 m in game scale.
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


## KamAZ-5350: 6x6, cab-over with sloped upper face, canvas-covered cargo bed.
static func worker():
	var root = Node3D.new()
	var b = K.builder()
	b.box(K.xf(Vector3(0, 0.2, 0.02)), Vector3(0.48, 0.08, 1.36), P.DARK)
	for z in [-0.46, 0.24, 0.46]:
		for x in [-0.3, 0.3]:
			b.wheel(Vector3(x, 0.14, z), 0.14, 0.1, P.RUBBER, P.RU_GREEN_DARK)
	# cab
	b.box(K.xf(Vector3(0, 0.36, -0.5)), Vector3(0.64, 0.24, 0.38), P.RU_GREEN)
	b.tapered_box(
		K.xf(Vector3(0, 0.48, -0.5)),
		Vector2(0.64, 0.38),
		Vector2(0.6, 0.3),
		0.18,
		P.RU_GREEN,
		Vector2(0, 0.04)
	)
	b.box(K.xf(Vector3(0, 0.56, -0.665), Vector3(-12, 0, 0)), Vector3(0.54, 0.12, 0.02), P.GLASS)
	b.box(K.xf(Vector3(0, 0.33, -0.692)), Vector3(0.4, 0.1, 0.01), P.DARK)  # grille
	for x in [-0.322, 0.322]:
		b.box(K.xf(Vector3(x, 0.55, -0.52)), Vector3(0.01, 0.1, 0.18), P.GLASS)
		b.box(K.xf(Vector3(x, 0.36, -0.5)), Vector3(0.012, 0.07, 0.28), TEAM)
	b.box(K.xf(Vector3(0, 0.24, -0.71)), Vector3(0.68, 0.07, 0.05), P.DARK)  # bumper
	b.box(K.xf(Vector3(0, 0.665, -0.5)), Vector3(0.36, 0.01, 0.2), TEAM)
	b.cylinder(K.xf(Vector3(-0.28, 0.6, -0.28)), 0.025, 0.025, 0.3, P.DARK, 6)
	b.wheel(Vector3(0, 0.5, -0.26), 0.12, 0.05, P.RUBBER, P.RU_GREEN_DARK)  # spare wheel
	# cargo bed with canvas tarp
	b.box(K.xf(Vector3(0, 0.3, 0.24)), Vector3(0.64, 0.08, 0.92), P.RU_GREEN_DARK)
	b.box(K.xf(Vector3(0, 0.44, 0.24)), Vector3(0.62, 0.2, 0.9), P.RU_GREEN)
	b.tapered_box(
		K.xf(Vector3(0, 0.54, 0.24)), Vector2(0.62, 0.9), Vector2(0.4, 0.88), 0.14, P.RU_TARP
	)
	b.box(K.xf(Vector3(0, 0.62, 0.24)), Vector3(0.4, 0.02, 0.2), TEAM)
	root.add_child(K.mesh_node("Body", b))
	return root


## T-90M: rounded cast turret with Relikt ERA brow, long gun, rear fuel drums.
static func tank():
	var root = Node3D.new()
	var b = K.builder()
	for side in [-1, 1]:
		var x = side * 0.46
		b.box(K.xf(Vector3(x, 0.14, 0)), Vector3(0.26, 0.22, 1.7), P.DARK)
		b.cylinder(K.xf(Vector3(x, 0.14, -0.85), Vector3(0, 0, 90)), 0.11, 0.11, 0.26, P.DARK)
		b.cylinder(K.xf(Vector3(x, 0.14, 0.85), Vector3(0, 0, 90)), 0.11, 0.11, 0.26, P.DARK)
		b.box(K.xf(Vector3(side * 0.5, 0.24, -0.1)), Vector3(0.24, 0.12, 1.5), P.RU_GREEN_DARK)
		for i in range(5):
			b.box(
				K.xf(Vector3(side * 0.625, 0.24, -0.7 + i * 0.3)),
				Vector3(0.012, 0.1, 0.26),
				P.RU_GREEN
			)
	b.tapered_box(
		K.xf(Vector3(0, 0.19, 0.02)),
		Vector2(0.88, 1.88),
		Vector2(1.08, 1.58),
		0.2,
		P.RU_GREEN,
		Vector2(0, 0.14)
	)
	# glacis ERA
	b.tapered_box(
		K.xf(Vector3(0, 0.3, -0.72), Vector3(-62, 0, 0)),
		Vector2(0.92, 0.06),
		Vector2(0.88, 0.06),
		0.3,
		P.RU_GREEN_DARK
	)
	b.box(K.xf(Vector3(0, 0.41, 0.66)), Vector3(0.86, 0.03, 0.4), P.RU_GREEN_DARK)
	for x in [-0.24, 0.24]:  # external fuel drums
		b.cylinder(
			K.xf(Vector3(x, 0.4, 0.92), Vector3(0, 0, 90)), 0.1, 0.1, 0.4, P.RU_GREEN_DARK, 8
		)
	root.add_child(K.mesh_node("Body", b))

	var turret = K.add(root, K.pivot("Turret", K.xf(Vector3(0, 0.39, -0.02))))
	var t = K.builder()
	t.cylinder(K.xf(Vector3(0, 0.11, 0.02)), 0.53, 0.4, 0.22, P.RU_GREEN, 10, false)
	t.box(K.xf(Vector3(0, 0.12, 0.5)), Vector3(0.62, 0.17, 0.24), P.RU_GREEN)  # bustle
	for side in [-1, 1]:
		t.tapered_box(
			K.xf(Vector3(side * 0.27, 0.0, -0.36), Vector3(0, side * 22, 0)),
			Vector2(0.36, 0.24),
			Vector2(0.32, 0.12),
			0.22,
			P.RU_GREEN_DARK,
			Vector2(0, 0.05)
		)
		t.box(K.xf(Vector3(side * 0.312, 0.12, 0.5)), Vector3(0.01, 0.06, 0.2), TEAM)
	t.box(K.xf(Vector3(0, 0.225, 0.12)), Vector3(0.36, 0.01, 0.3), TEAM)
	t.box(K.xf(Vector3(0, 0.12, -0.5)), Vector3(0.18, 0.12, 0.1), P.RU_GREEN_DARK)  # mantlet
	t.cylinder(K.xf(Vector3(0, 0.12, -1.06), Vector3(90, 0, 0)), 0.032, 0.03, 1.04, P.GUNMETAL, 6)
	t.cylinder(K.xf(Vector3(0, 0.12, -0.92), Vector3(90, 0, 0)), 0.048, 0.048, 0.14, P.RU_GREEN, 6)
	t.dome(K.xf(Vector3(0.18, 0.22, 0.0)), 0.09, P.RU_GREEN_DARK, 2, 8)  # commander sight
	t.box(K.xf(Vector3(-0.2, 0.26, -0.12)), Vector3(0.12, 0.1, 0.12), P.RU_GREEN_DARK)  # Sosna-U
	t.cylinder(K.xf(Vector3(0.18, 0.33, -0.1), Vector3(90, 0, 0)), 0.012, 0.012, 0.22, P.DARK, 4)
	t.cylinder(K.xf(Vector3(-0.28, 0.45, 0.45)), 0.006, 0.006, 0.5, P.DARK, 4)
	turret.add_child(K.mesh_node("Mesh", t))
	turret.add_child(K.marker("ProjectileOrigin", Vector3(0, 0.12, -1.6)))
	return root


## Ka-52 Alligator: side-by-side cockpit, coaxial rotors, twin tail fins.
static func helicopter():
	var root = Node3D.new()
	var b = K.builder()
	var body = P.RU_HELI
	b.tapered_box(
		K.xf(Vector3(0, 0.18, 0.3), Vector3(-90, 0, 0)),
		Vector2(0.38, 0.36),
		Vector2(0.36, 0.32),
		0.64,
		body
	)
	b.tapered_box(
		K.xf(Vector3(0, 0.17, -0.34), Vector3(-90, 0, 0)),
		Vector2(0.36, 0.32),
		Vector2(0.18, 0.16),
		0.42,
		body
	)
	b.tapered_box(
		K.xf(Vector3(0, 0.29, -0.5)),
		Vector2(0.32, 0.34),
		Vector2(0.22, 0.2),
		0.12,
		P.GLASS,
		Vector2(0, 0.04)
	)
	b.dome(
		K.xf(Vector3(0, 0.16, -0.76), Vector3.ZERO, Vector3(1, 0.9, 1.2)), 0.08, P.DARK, 2, 8, true
	)
	b.dome(K.xf(Vector3(0, 0.05, -0.5)), 0.06, P.DARK, 2, 6, true)  # chin sensor ball
	for side in [-1, 1]:
		b.box(K.xf(Vector3(side * 0.22, 0.38, 0.06)), Vector3(0.13, 0.13, 0.42), body)
		b.box(K.xf(Vector3(side * 0.225, 0.38, 0.06)), Vector3(0.135, 0.04, 0.28), TEAM)
		b.cylinder(
			K.xf(Vector3(side * 0.26, 0.14, 0.0), Vector3(90, 0, 0)), 0.05, 0.05, 0.24, P.DARK, 6
		)
		b.box(K.xf(Vector3(side * 0.42, 0.14, 0.0)), Vector3(0.07, 0.08, 0.26), P.DARK)  # Vikhr
		b.wheel(Vector3(side * 0.16, -0.06, -0.4), 0.05, 0.04, P.RUBBER, P.METAL, 6)
		b.wheel(Vector3(side * 0.16, -0.06, 0.22), 0.05, 0.04, P.RUBBER, P.METAL, 6)
		# H-tail fins
		b.tapered_box(
			K.xf(Vector3(side * 0.25, 0.14, 1.0)),
			Vector2(0.03, 0.18),
			Vector2(0.03, 0.12),
			0.26,
			body,
			Vector2(0, 0.04)
		)
		b.box(K.xf(Vector3(side * 0.266, 0.28, 1.02)), Vector3(0.004, 0.08, 0.1), TEAM)
	b.box(K.xf(Vector3(0, 0.22, 0.0)), Vector3(0.92, 0.03, 0.19), body)
	b.tapered_box(
		K.xf(Vector3(0, 0.22, 0.3), Vector3(90, 0, 0)),
		Vector2(0.2, 0.22),
		Vector2(0.08, 0.12),
		0.78,
		body
	)
	b.box(K.xf(Vector3(0, 0.22, 1.0)), Vector3(0.52, 0.02, 0.12), body)
	b.cylinder(K.xf(Vector3(0, 0.5, 0.0)), 0.035, 0.035, 0.2, P.METAL, 6)  # mast
	root.add_child(K.mesh_node("Body", b))
	root.add_child(K.marker("ProjectileOrigin", Vector3(0, 0.1, -0.55)))

	var blades = func(count):
		var r = K.builder()
		r.cylinder(K.xf(), 0.06, 0.06, 0.04, P.METAL, 6)
		for i in range(count):
			r.box(
				K.xf(Vector3.ZERO, Vector3(0, i * 360.0 / count, 0)) * K.xf(Vector3(0, 0, -0.44)),
				Vector3(0.06, 0.012, 0.82),
				P.DARK
			)
		return r
	var rotor = K.add(root, K.pivot("Rotor", K.xf(Vector3(0, 0.6, 0.0))))
	rotor.add_child(K.mesh_node("Mesh", blades.call(3)))
	var lower = K.add(
		root, K.spinner("RotorLower", K.xf(Vector3(0, 0.49, 0.0)), Vector3.UP, -800.0)
	)
	lower.add_child(K.mesh_node("Mesh", blades.call(3)))
	return root


## Orlan-10: conventional layout, high straight wing, nose propeller.
static func drone():
	var root = Node3D.new()
	var b = K.builder()
	var c = P.RU_GRAY
	b.tapered_box(
		K.xf(Vector3(0, 0.1, -0.2), Vector3(90, 0, 0)),
		Vector2(0.11, 0.12),
		Vector2(0.04, 0.05),
		0.6,
		c
	)
	b.tapered_box(
		K.xf(Vector3(0, 0.1, -0.2), Vector3(-90, 0, 0)),
		Vector2(0.11, 0.12),
		Vector2(0.07, 0.08),
		0.12,
		c
	)
	for side in [-1, 1]:
		b.box(
			K.xf(Vector3(side * 0.31, 0.17, -0.12), Vector3(0, 0, side * 4)),
			Vector3(0.62, 0.02, 0.12),
			c
		)
		b.box(
			K.xf(Vector3(side * 0.56, 0.19, -0.12), Vector3(0, 0, side * 4)),
			Vector3(0.1, 0.022, 0.125),
			TEAM
		)
	b.box(K.xf(Vector3(0, 0.11, 0.38)), Vector3(0.36, 0.015, 0.08), c)  # stabilizer
	b.tapered_box(
		K.xf(Vector3(0, 0.11, 0.38)),
		Vector2(0.015, 0.12),
		Vector2(0.015, 0.06),
		0.14,
		TEAM,
		Vector2(0, 0.03)
	)
	b.dome(K.xf(Vector3(0, 0.04, -0.12)), 0.035, P.DARK, 2, 6, true)
	root.add_child(K.mesh_node("Body", b))
	var prop = K.add(
		root, K.spinner("Propeller", K.xf(Vector3(0, 0.1, -0.34)), Vector3.FORWARD, 2000.0)
	)
	var p = K.builder()
	p.box(K.xf(), Vector3(0.26, 0.03, 0.01), P.DARK)
	p.cylinder(K.xf(Vector3.ZERO, Vector3(90, 0, 0)), 0.02, 0.0, 0.04, P.DARK, 6)
	prop.add_child(K.mesh_node("Mesh", p))
	return root


## Command HQ: sloped-wall concrete bunker block, radar mast with spinning radar.
static func command_center():
	var root = Node3D.new()
	var b = K.builder()
	var wall = P.RU_BUILDING
	b.box(K.xf(Vector3(0, 0.03, 0)), Vector3(3.6, 0.06, 3.6), P.CONCRETE_DARK)
	b.tapered_box(K.xf(Vector3(0.1, 0.06, 0.3)), Vector2(2.8, 2.1), Vector2(2.4, 1.7), 0.84, wall)
	b.box(K.xf(Vector3(0.1, 0.92, 0.3)), Vector3(2.44, 0.05, 1.74), P.CONCRETE_DARK)
	# tower
	b.tapered_box(K.xf(Vector3(-0.5, 0.94, 0.5)), Vector2(1.1, 1.0), Vector2(0.9, 0.8), 0.36, wall)
	for i in range(4):
		b.box(K.xf(Vector3(-0.5 - 0.3 + i * 0.2, 1.16, 0.095)), Vector3(0.12, 0.1, 0.01), P.GLASS)
	b.box(K.xf(Vector3(0.1, 0.27, -0.83)), Vector3(0.5, 0.36, 0.2), P.DARK)  # entrance
	b.box(K.xf(Vector3(0.1, 0.5, -0.86)), Vector3(0.7, 0.06, 0.26), P.CONCRETE)
	b.box(K.xf(Vector3(0.7, 0.945, -0.4)), Vector3(0.9, 0.01, 0.14), TEAM)
	b.tapered_box(
		K.xf(Vector3(1.0, 0.94, 0.75)), Vector2(0.2, 0.2), Vector2(0.05, 0.05), 0.9, P.METAL
	)
	b.cylinder(K.xf(Vector3(-0.2, 1.6, 0.8)), 0.008, 0.008, 1.0, P.DARK, 4)
	b.cylinder(K.xf(Vector3(-1.5, 0.75, -1.5)), 0.015, 0.015, 1.5, P.METAL, 4)
	b.box(K.xf(Vector3(-1.32, 1.36, -1.5)), Vector3(0.34, 0.2, 0.01), TEAM)
	for i in range(5):  # concrete blocks
		b.box(K.xf(Vector3(0.6 + i * 0.22, 0.12, -1.5)), Vector3(0.18, 0.2, 0.3), P.CONCRETE)
	root.add_child(K.mesh_node("Body", b))
	var radar = K.add(root, K.spinner("Radar", K.xf(Vector3(1.0, 1.86, 0.75)), Vector3.UP, 90.0))
	var r = K.builder()
	r.box(K.xf(Vector3(0, 0.08, 0), Vector3(-15, 0, 0)), Vector3(0.5, 0.16, 0.03), P.WHITE)
	r.box(K.xf(Vector3(0, 0.0, 0.03)), Vector3(0.04, 0.06, 0.06), P.METAL)
	radar.add_child(K.mesh_node("Mesh", r))
	return root


## War factory: concrete hall with a sawtooth roof and a brick chimney.
static func vehicle_factory():
	var root = Node3D.new()
	var b = K.builder()
	b.box(K.xf(Vector3(0, 0.03, 0)), Vector3(2.9, 0.06, 2.9), P.CONCRETE_DARK)
	b.box(K.xf(Vector3(-0.2, 0.39, 0.1)), Vector3(2.1, 0.66, 2.2), P.RU_BUILDING)
	for i in range(3):  # sawtooth roof
		var z = -0.65 + i * 0.73
		b.tapered_box(
			K.xf(Vector3(-0.2, 0.72, z), Vector3(0, 90, 0)),
			Vector2(0.72, 2.1),
			Vector2(0.02, 2.1),
			0.3,
			P.CONCRETE,
			Vector2(-0.35, 0)
		)
		b.box(
			K.xf(Vector3(-0.2, 0.86, z - 0.355), Vector3(0, 0, 0)),
			Vector3(2.0, 0.24, 0.01),
			P.GLASS
		)
	b.box(K.xf(Vector3(-0.2, 0.36, -1.0)), Vector3(1.2, 0.6, 0.02), P.DARK)  # door
	b.box(K.xf(Vector3(-0.2, 0.68, -1.01)), Vector3(1.3, 0.06, 0.02), TEAM)
	b.tapered_box(
		K.xf(Vector3(-0.2, 0.06, -1.24)), Vector2(1.2, 0.5), Vector2(1.2, 0.1), 0.04, P.ASPHALT
	)
	b.cylinder(K.xf(Vector3(1.05, 0.8, 0.9)), 0.13, 0.1, 1.5, P.RED, 8)  # chimney
	b.cylinder(K.xf(Vector3(1.05, 1.3, 0.9)), 0.111, 0.111, 0.1, P.WHITE, 8, true, false)
	b.box(K.xf(Vector3(1.1, 0.25, -0.5)), Vector3(0.5, 0.4, 0.6), P.RU_GREEN_DARK)  # transformer
	b.box(K.xf(Vector3(1.1, 0.455, -0.5)), Vector3(0.3, 0.01, 0.3), TEAM)
	root.add_child(K.mesh_node("Body", b))
	return root


## Helipad: round concrete pad with H marking, earth-covered bunker and radio mast.
static func aircraft_factory():
	var root = Node3D.new()
	var b = K.builder()
	b.cylinder(K.xf(Vector3(-0.15, 0.05, 0.15)), 1.35, 1.3, 0.1, P.CONCRETE_DARK, 12, false)
	b.cylinder(K.xf(Vector3(-0.15, 0.105, 0.15)), 0.95, 0.95, 0.01, P.WHITE, 12, false)
	b.cylinder(K.xf(Vector3(-0.15, 0.11, 0.15)), 0.88, 0.88, 0.01, P.ASPHALT, 12, false)
	for x in [-0.4, 0.1]:
		b.box(K.xf(Vector3(x, 0.12, 0.15)), Vector3(0.14, 0.01, 0.9), P.WHITE)
	b.box(K.xf(Vector3(-0.15, 0.12, 0.15)), Vector3(0.5, 0.01, 0.14), P.WHITE)
	for angle in [45, 165, 285]:
		b.box(
			K.xf(Vector3(-0.15, 0.13, 0.15), Vector3(0, angle, 0)) * K.xf(Vector3(0, 0, 1.2)),
			Vector3(0.14, 0.06, 0.14),
			TEAM
		)
	b.tapered_box(
		K.xf(Vector3(1.05, 0, -1.0)), Vector2(0.9, 0.8), Vector2(0.5, 0.4), 0.45, P.SANDBAG
	)  # bunker
	b.box(K.xf(Vector3(1.05, 0.2, -1.4)), Vector3(0.24, 0.24, 0.02), P.DARK)
	b.box(K.xf(Vector3(1.05, 0.455, -1.0)), Vector3(0.4, 0.01, 0.3), TEAM)
	b.tapered_box(
		K.xf(Vector3(-1.15, 0, 1.15)), Vector2(0.14, 0.14), Vector2(0.03, 0.03), 1.4, P.RED
	)
	b.cylinder(K.xf(Vector3(-1.15, 1.0, 1.15)), 0.06, 0.06, 0.06, P.WHITE, 6)
	for i in range(4):  # fuel drums
		b.cylinder(
			K.xf(Vector3(1.1 + (i % 2) * 0.18, 0.12, 0.6 + (i / 2) * 0.18)),
			0.08,
			0.08,
			0.22,
			P.RU_GREEN,
			8
		)
	root.add_child(K.mesh_node("Body", b))
	return root


## Kornet post: concrete barriers and a Kornet launcher with its guidance unit on a tripod.
static func anti_ground_turret():
	var root = Node3D.new()
	var b = K.builder()
	b.box(K.xf(Vector3(0, 0.02, 0)), Vector3(1.1, 0.04, 1.1), P.CONCRETE_DARK)
	for angle in [-50, 0, 50]:  # jersey barriers in an arc in front
		b.tapered_box(
			K.xf(Vector3(0, 0, 0), Vector3(0, angle, 0)) * K.xf(Vector3(0, 0.04, -0.4)),
			Vector2(0.36, 0.14),
			Vector2(0.34, 0.05),
			0.16,
			P.CONCRETE_DARK
		)
	for angle in [0, 120, 240]:
		b.cylinder(
			(
				K.xf(Vector3(0, 0.13, 0), Vector3(0, angle, 0))
				* K.xf(Vector3(0, 0, 0.06), Vector3(20, 0, 0))
			),
			0.01,
			0.01,
			0.26,
			P.DARK,
			4
		)
	b.box(K.xf(Vector3(0.3, 0.1, 0.3)), Vector3(0.26, 0.12, 0.18), P.RU_GREEN_DARK)  # missile crates
	root.add_child(K.mesh_node("Body", b))

	var turret = K.add(root, K.pivot("Turret", K.xf(Vector3(0, 0.28, 0))))
	var t = K.builder()
	t.box(K.xf(Vector3(0.0, -0.01, 0.06)), Vector3(0.14, 0.1, 0.16), P.RU_GREEN)  # guidance unit
	t.box(K.xf(Vector3(0.0, -0.01, -0.025)), Vector3(0.1, 0.06, 0.01), P.GLASS)
	t.cylinder(K.xf(Vector3(0, 0.08, -0.06), Vector3(90, 0, 0)), 0.06, 0.06, 0.72, P.RU_GREEN, 8)
	t.cylinder(K.xf(Vector3(0, 0.08, 0.2), Vector3(90, 0, 0)), 0.063, 0.063, 0.06, TEAM, 8)
	t.box(K.xf(Vector3(0.09, 0.0, 0.04)), Vector3(0.06, 0.08, 0.1), P.DARK)  # thermal sight
	turret.add_child(K.mesh_node("Mesh", t))
	turret.add_child(K.marker("ProjectileOrigin", Vector3(0, 0.08, -0.44)))
	return root


## Pantsir: turret with twin 30 mm guns, missile packs either side and a spinning radar.
static func anti_air_turret():
	var root = Node3D.new()
	var b = K.builder()
	b.box(K.xf(Vector3(0, 0.03, 0)), Vector3(1.1, 0.06, 1.1), P.CONCRETE_DARK)
	b.box(K.xf(Vector3(0, 0.13, 0)), Vector3(0.7, 0.14, 0.7), P.RU_GREEN_DARK)
	for angle in [45, 135, 225, 315]:  # stabilizer jacks
		b.box(
			K.xf(Vector3(0, 0.08, 0), Vector3(0, angle, 0)) * K.xf(Vector3(0, 0, 0.42)),
			Vector3(0.06, 0.1, 0.12),
			P.DARK
		)
	root.add_child(K.mesh_node("Body", b))

	var turret = K.add(root, K.pivot("Turret", K.xf(Vector3(0, 0.2, 0))))
	var t = K.builder()
	t.box(K.xf(Vector3(0, 0.12, 0.04)), Vector3(0.34, 0.22, 0.44), P.RU_GREEN)
	t.box(K.xf(Vector3(0, 0.12, 0.262)), Vector3(0.2, 0.1, 0.01), TEAM)
	t.box(K.xf(Vector3(0, 0.12, -0.19)), Vector3(0.18, 0.12, 0.04), P.DARK)  # tracking radar
	var launcher = K.xf(Vector3(0, 0.14, 0.0), Vector3(25, 0, 0))
	t.push(launcher)
	for side in [-1, 1]:
		for row in range(2):
			for col in range(3):
				t.cylinder(
					K.xf(
						Vector3(side * (0.22 + col * 0.055), 0.03 + row * 0.055, -0.04),
						Vector3(90, 0, 0)
					),
					0.026,
					0.026,
					0.5,
					P.RU_GREEN_DARK,
					6
				)
		t.cylinder(
			K.xf(Vector3(side * 0.13, -0.06, -0.3), Vector3(90, 0, 0)),
			0.016,
			0.016,
			0.4,
			P.GUNMETAL,
			4
		)
		t.box(K.xf(Vector3(side * 0.13, -0.06, -0.06)), Vector3(0.06, 0.07, 0.14), P.RU_GREEN_DARK)
	t.pop()
	turret.add_child(K.mesh_node("Mesh", t))
	var radar = K.add(turret, K.spinner("Radar", K.xf(Vector3(0, 0.25, 0.12)), Vector3.UP, 180.0))
	var r = K.builder()
	r.cylinder(K.xf(Vector3(0, 0.02, 0)), 0.02, 0.02, 0.04, P.METAL, 6)
	r.box(K.xf(Vector3(0, 0.1, 0), Vector3(-10, 0, 0)), Vector3(0.3, 0.12, 0.025), P.RU_GREEN_DARK)
	radar.add_child(K.mesh_node("Mesh", r))
	turret.add_child(K.marker("ProjectileOrigin", launcher * Vector3(0.275, 0.085, -0.3)))
	return root
