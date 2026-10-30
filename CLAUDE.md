# Desert Command

A C&C Generals-style RTS with modern real-world weapons, **USA vs Russia**.
Fork of [Open RTS](https://github.com/lampe-games/godot-open-rts) (Godot 4.3, MIT).

## Ground rules

- Engine: **Godot 4.3**. Renderer: **GL Compatibility** (target: laptops with Intel UHD graphics).
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

## Plan

### Phase 1 - Performance
- Switch `project.godot` to the GL Compatibility renderer (desktop and mobile).
- Keep settings cheap for Intel UHD: no MSAA, modest shadow sizes.

### Phase 2 - Factions
- Add `faction` (`"usa"` / `"russia"`) to `source/data-model/PlayerSettings.gd` and
  `source/match/players/Player.gd`; set it in `Match._create_players_from_settings`.
- Add a faction picker per player slot in `source/main-menu/Play.tscn`.
- AI slots default to the opposite faction of the human player.

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

### Phase 4 - UI
- Faction unit names in production tooltips (`hud/unit-menus/*.gd`, via `tr()`).
- New faction icons (rendered with `source/utils/IconRenderBooth`).
- Rename resources A/B to **Supplies** / **Fuel**; replace crystal models with supply crates
  and fuel drums.

### Phase 5 - Desert look
- Sand terrain and Generals-like lighting (warm sun, hazy sky, soft fog).

## Status

- [x] Phase 1 - Performance
- [ ] Phase 2 - Factions
- [ ] Phase 3 - Models
- [ ] Phase 4 - UI
- [ ] Phase 5 - Desert look
