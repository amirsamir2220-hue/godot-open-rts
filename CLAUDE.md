# Desert Command

A C&C Generals-style RTS with modern real-world weapons, **USA vs Russia**.
Visual and motion target: **C&C Generals Zero Hour** (unit look, motion feel, effects, lighting).
Fork of [Open RTS](https://github.com/lampe-games/godot-open-rts) (Godot 4.3, MIT).

## Ground rules

- Engine: **Godot 4.3**, and it must also run on **Godot 4.7** (the owner's editor). Renderer:
  **GL Compatibility** (target: laptops with Intel UHD graphics).
- Work in phases. After each phase the game must run with **no errors**, then commit and push.
- Keep the upstream architecture (units are `Area3D` + trait nodes, `Constants.Match.*` tables
  keyed by scene path). Prefer adding small helpers over rewriting systems.
- Formatting/lint: `make` runs `gdlint`, `gdformat --check` and `clang-format` for shaders.

## How to verify a phase

```bash
godot --headless --import            # (re)import assets, catches parse errors
godot --rendering-driver opengl3 --quit-after 600 res://tests/manual/TestPlayerVsAI.tscn
godot --rendering-driver opengl3 --quit-after 600 res://source/Main.tscn
```

Also run the other scenes in `tests/manual/`. Messages about leaked RIDs/buffers/shaders printed
*at exit* come from `--quit-after` and are expected; anything else (`SCRIPT ERROR`, `ERROR`
during the run) must be fixed.

## Renderer gotchas (Godot 4.3)

- Godot 4.3's shader preprocessor has **no `CURRENT_RENDERER`** define. Shaders that rebuild
  world positions from depth read the global shader uniform `depth_is_opengl` (declared in
  `project.godot`, set in `Globals.gd`): OpenGL/Compatibility depth is `<-1; 1>`, Vulkan is
  `<0; 1>` with reversed Z.
- Full-screen overlay quads (`fog`, `*_fog_of_war`) must use `depth_test_disabled`; at z=0 they
  sit mid-depth in OpenGL and were being hidden by the scene (half the screen had no fog of war).
- Use `RenderingServer.get_rendering_device() == null` to detect Compatibility at runtime.

## Navigation gotchas (Godot 4.3 -> 4.7)

- Never call `NavigationServer3D.map_force_update()`: on 4.7 it leaves the map stuck empty
  (every query returns `Vector3.ZERO`), and unit placement then loops forever (game freeze
  right after "Setting up a camera...").
- Do not query a map before its first sync: use `Utils.Match.wait_for_navigation_map()` or check
  `NavigationServer3D.map_get_iteration_id(map) > 0` (`Movement` skips path queries until then).
- Bake through `source/match/NavigationBaking.gd` (colliders + CPU-side primitive meshes) instead
  of `NavigationRegion3D.bake_navigation_mesh()`, which reads visual meshes back from the GPU.

## Code map (Desert Command additions)

- `source/match/units/models/` - code-built faction models: `ModelBuilder` (merged low-poly
  meshes), `ModelKit` (palette, materials, helpers), `UsaModels` / `RussiaModels`,
  `FactionModels` (registry, cache, team color, turret re-pointing, `MODEL_OVERRIDES`).
- `source/match/units/traits/ModelMotion.gd` - visual-only motion (hull slew, pitch/roll,
  turret tracking, heli/drone banking, recoil, muzzle flash). Added by `Unit` at runtime.
- `source/match/units/effects/DeathEffect.gd` - wreck + fireball + smoke on unit death.
- `source/utils/IconRenderBooth.tscn` - renders models to icons/previews (needs a GPU).
  Re-run it after changing a model: `godot res://source/utils/IconRenderBooth.tscn` writes
  `assets/ui/icons/<usa|russia|neutral>/<Type>.png`.
- `source/match/hud/FactionUi.gd` - faction unit names (`USA_TANK`, `RUSSIA_TANK`, ... in
  `assets/translations/match.csv`), tooltips and icons for HUD buttons.
- Desert look: `source/shaders/3d/sand_terrain.gdshader` via
  `match/resources/materials/terrain.material.tres` (used by every map), lighting/sky/haze in
  `source/match/Match.tscn` (warm sun, cool ambient fill, filmic tonemap, sandy height haze).
- Resources: `resource_a` = **Supplies** (crates), `resource_b` = **Fuel** (drums); internal
  names are unchanged, only display names/models/colors.
- `tests/manual/TestFactions.tscn` - both factions side by side, all 9 unit types.
- `source/match/decorations/DesertScatter.gd` - visual-only rocks/shrubs/pebbles (MultiMesh).
- Model shading: `ModelBuilder` bakes ambient occlusion into vertex colors (`AO_STRENGTH`).

## Plan

### Phase 1 - Performance
- Switch `project.godot` to the GL Compatibility renderer (desktop and mobile).
- Keep settings cheap for Intel UHD: no MSAA, modest shadow sizes.

### Phase 2 - Factions
- Add `faction` (`"usa"` / `"russia"`) to `source/data-model/PlayerSettings.gd` and
  `source/match/players/Player.gd`; set it in `Match._create_players_from_settings`.
- Add a faction picker per player slot in `source/main-menu/Play.tscn`.
- AI slots default to the opposite faction of the human player.

### Phase 2B - Game modes: Death Match (done early)
- `Constants.GameMode`: `normal` (start at 0) and `death_match` (Generals-style: everyone
  starts with a big pile of supplies/fuel and the AI fields a bigger army).
- Picked in the Play menu (`ModeOptionButton`), stored in `MatchSettings.mode`, applied in
  `Match._apply_game_mode`. Tune the amounts in `Constants.GameMode.STARTING_RESOURCES`.

### Phase 2C - Sandbox mode and AI difficulty (done)
- `sandbox` game mode: only the human player, 1000 supplies / 1000 fuel, no match end
  (`MatchEndHandler` removed). AI slots are ignored and Start works with just a human.
- `Constants.AiDifficulty` (Easy default / Normal / Hard), picked in the Play menu and stored in
  `MatchSettings.ai_difficulty`. Each level sets the AI's `start_delay_s`, `build_speed`
  (production + construction speed, `Player.build_speed`) and army size; Death Match adds
  `GameMode.AI_BONUS` on top. The human's `build_speed` is always 1.0.
- In-match "How to play" panel (`hud/ControlsHelp.gd`, H key or "?" button).
- Fog of war is see-through (`max_opacity` 0.8, explored areas lighter) so the map stays readable.

### Phase 3C - Realistic unit models (done)
- 11 realistic CC BY models from Sketchfab in `assets/models/realistic/<faction>/<Type>/`
  (credits: `assets/models/realistic/CREDITS.md`, also on the Credits screen). The USA drone
  and all buildings are still code-built.
- Offline prep (scripts kept outside the repo): parts split by height into `Turret*` /
  `Rotor*` nodes where the source merged them (Abrams turret, Apache rotor, T-90 gun),
  roles via node names (`Turret*`, `Rotor*`, `Prop*`, `Drop*`), textures <= 1024 px.
- `models/RealisticModels.gd` fits each file at build time (forward axis -> -Z, length in game
  units, ground/air/base mount), builds `Turret` / `Rotor` / `Propeller` pivots and
  `ProjectileOrigin`, adds coaxial blades to the Ka-52 and a team-color pennant to ground
  units. `FactionModels.build()` prefers it over the code-built model when the file exists.
- Sketchfab downloads need the owner's API token: keep it out of the repo (temporary file only).

### Phase 3D - Realistic buildings (next)
- Replace the code-built Command HQ, War factory, Helipad (and later new buildings) with
  realistic military structures (CC BY / CC0), same pipeline as Phase 3C.

### Phase 3E - New units: Humvee / jeep, infantry, fighter jets (next)
- Light vehicle: USA HMMWV (Humvee) / Russia GAZ Tigr - fast scout/raider with a machine gun,
  built at the War factory.
- Infantry: rifleman + anti-tank soldier per faction (squads of small units) from a Barracks.
- Fighter jets (owner's wish list): USA F-15, F-16, F-35 / Russia MiG-29, Su-35, Su-57, from an
  Airfield; strike runs against ground and air targets.
- Each new unit needs: scene + script (copying the closest existing unit), DEFAULT_PROPERTIES,
  costs/times, menu button + icon + names, AI support, realistic model.

### Phase 3 - Models
Low-poly models per faction for all 9 unit types:

| Unit             | USA                 | Russia               |
|------------------|---------------------|----------------------|
| Worker           | HEMTT supply truck  | KamAZ supply truck   |
| Tank             | M1A2 Abrams         | T-90M                |
| Helicopter       | AH-64 Apache        | Ka-52 Alligator      |
| Drone            | RQ-7 Shadow         | Orlan-10             |
| CommandCenter    | Command HQ          | Command HQ           |
| VehicleFactory   | War factory         | War factory          |
| AircraftFactory  | Helipad             | Helipad              |
| AntiGroundTurret | Javelin post        | Kornet post          |
| AntiAirTurret    | Patriot battery     | Pantsir              |

- Swap the model under each unit's `Geometry` node at runtime by the owner's faction.
- Keep nodes named `Rotor` and `ProjectileOrigin` (used by `Helicopter.gd` and projectiles).
- Turrets: re-point `RotationSynchronizer.remote_path` and the `RotateRandomly*`
  `node_to_rotate` to the new turret node.
- Re-apply the under-construction material after the swap.
- `Utils.Match.traverse_node_tree_and_replace_materials_matching_albedo` only handles
  `ArrayMesh` surface materials, so team-color parts need their own handling.
- Use faction models for structure placement blueprints too.
- **Art strategy (hybrid):** models are built in code now (original, faction-accurate
  silhouettes, merged meshes, vertex colors + one team-color surface for cheap draw calls).
  Each model sits behind one registry (`FactionModels.build(type, faction)`), so a better
  model (CC0 pack or a sourced/bought `.glb`) can replace any entry later without code changes,
  as long as it keeps the node names (`Rotor`, `ProjectileOrigin`, `Turret`).
- Split moving parts now (tank `Turret`, rotors, propellers, radar) so Phase 3B can animate them.

### Phase 3B - Motion (Generals-like feel)
- Tanks: turret tracks targets independently of the hull; hull accelerates/brakes and turns
  in place before driving; cannon recoil + muzzle flash.
- Trucks: acceleration, slight body roll/pitch on turns and stops.
- Helicopters: tilt forward when accelerating, bank in turns, hover bob, coaxial rotors on Ka-52.
- Drones: banked turns, spinning propellers.
- Turrets: smooth slewing to target instead of snapping; radar spin on Pantsir/Patriot.
- Deaths: unit wreck + simple explosion (full VFX comes in Phase 7).
- Pure visuals: movement speeds, ranges and timing of attacks stay unchanged.

### Phase 4 - UI
- Faction unit names in production tooltips (`hud/unit-menus/*.gd`, via `tr()`).
- New faction icons (rendered with `source/utils/IconRenderBooth`).
- Rename resources A/B to **Supplies** / **Fuel**; replace crystal models with supply crates
  and fuel drums.

### Phase 5 - Desert look
- Sand terrain and Generals-like lighting (warm sun, hazy sky, soft fog).

## Extra goal: switchable graphics quality (Low / Medium / High)

**Low** must stay exactly what Phases 1-5 deliver and keep running smoothly on Intel UHD.
**High** targets visuals on par with or above C&C Generals Zero Hour (detailed models,
explosion/smoke/dust effects, better lighting), ready for a stronger machine later.
Nothing in these phases may make Low slower or change gameplay.

Design rules:
- One source of truth: a `GraphicsQuality` enum + preset table (in `Constants`), stored in
  `Options` (`source/data-model/Options.gd`), default **Low**.
- Every visual feature reads the current preset and is **off at Low** unless it is free.
- Settings that can change at runtime apply immediately (signal from `Options`); the renderer
  switch (Compatibility vs Forward+) is written as a project-settings override and applied on
  restart. Low and Medium always use Compatibility; High may use Forward+.
- Model detail is chosen per preset (LOD / detail variants of the Phase 3 models), never by
  swapping unit scenes, so gameplay nodes (`Geometry`, `Rotor`, `ProjectileOrigin`, turret
  nodes) stay identical across presets.

### Phase 6 - Graphics settings menu
- `GraphicsQuality` presets (Low / Medium / High) in `Options`, saved with the other options.
- Graphics section in `main-menu/Options` (and reachable from the in-match menu): preset picker
  plus a "restart required" note when the renderer changes.
- A `GraphicsSettings` applier that sets per preset: render scale, MSAA/FXAA, shadow
  atlas size, shadow splits and distance, soft-shadow quality, environment toggles (fog, glow,
  SSAO on Forward+), particle budget, LOD bias.
- Low preset = current Phase 1-5 settings, byte-for-byte.

### Phase 7 - VFX
- Pooled, budgeted effects driven by the preset (Low: minimal/no particles, Medium: light,
  High: full):
  - Explosions: flash, fireball, debris, scorch decal; bigger variant for structure death.
  - Smoke: rocket/missile trails, burning damaged units/structures, wreck smoke.
  - Dust: tank/truck tracks dust, helicopter rotor downwash, impact dust.
  - Muzzle flashes and tracers; Patriot/Pantsir launch plumes.
- GPU particles on High (Forward+), CPU/simple particles or billboards on Low/Medium.
- Hook into existing events (projectile hit, `unit_died`, movement) without touching gameplay
  logic.

### Phase 8 - Model detail
- Higher-detail variants of every Phase 3 faction model (more silhouette parts, bevels,
  tracks/wheels, rotor hubs, antennas, crew hatches), selected per preset.
- Damage states (light/heavy damage meshes or decals) and wrecks on High.
- Animated details on Medium/High: tank tracks, turret recoil, rotor blur disc, radar spin.
- Keep node names and the team-color handling from Phase 3 so detail variants are drop-in.

### Phase 9 - High-end lighting and post-processing
- High preset only: Forward+ with SSAO, glow/bloom for explosions, volumetric dust fog,
  better shadow cascades, color grading towards the Generals desert palette, sun light shafts.
- Medium: tuned Compatibility look (FXAA, higher shadow resolution, light glow if affordable).
- Verify Low is unchanged after every phase (screenshots + frame timing on the test scenes).

## Status

- [x] Phase 1 - Performance
- [x] Phase 2 - Factions
- [x] Phase 2B - Game modes: Death Match
- [x] Phase 2C - Sandbox mode, AI difficulty, controls help
- [x] Phase 3 - Models
- [x] Phase 3B - Motion
- [x] Phase 3C - Realistic unit models
- [ ] Phase 3D - Realistic buildings
- [ ] Phase 3E - New units: Humvee/Tigr, infantry, fighter jets
- [x] Phase 4 - UI
- [x] Phase 5 - Desert look
- [ ] Phase 6 - Graphics settings menu
- [ ] Phase 7 - VFX
- [ ] Phase 8 - Model detail
- [ ] Phase 9 - High-end lighting and post-processing
