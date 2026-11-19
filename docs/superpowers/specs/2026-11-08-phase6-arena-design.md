# Phase 6 — Arena & Wave Director Design (T-024..T-027)

Status: approved for implementation.
Scope: `scenes/arena.tscn` + `scripts/arena/arena_controller.gd`, `scripts/arena/camera_shake.gd`, `scripts/arena/wave_director.gd`, T-027 shake wiring verification.

## Intent

Build the playable arena and its two arena-level systems:
1. A 1280×720 arena with perimeter walls, four 80px gates, four 45° steel bunkers, three sandbag barricades, three mud craters, the player at center, and a camera at `(640,360)`.
2. A camera shake controller that listens to `EventBus.camera_shake_requested` and applies a decaying random offset.
3. A time-based wave director that spawns Scout / Artillery / Dreadnought at random gates using `GameManager.time_survived`.
4. Confirm the enemy-destroyed shake `(5.0, 0.2)` is emitted exactly once (already implemented in T-007).

## Goals

### Arena (`scenes/arena.tscn`, `arena_controller.gd`)
- Root `Node2D` named `Arena`, script `arena_controller.gd`.
- `Background`: `Polygon2D` covering `(0,0)-(1280,720)`, color `#4A3B32`, `z_index = -100`.
- `Camera2D` at `(640,360)`, `camera_shake.gd` attached.
- `PerimeterWalls`: 8 `StaticBody2D` segments, each `collision_layer = 4` (Layer 3), `collision_mask = 0`, group `"bouncy_surface"`, with a `CollisionShape2D` and `Polygon2D` visual. Wall thickness 20, gate opening 80:
  - Top: `x 0..600` and `680..1280` at `y 0..20`.
  - Bottom: same at `y 700..720`.
  - Left: `y 0..320` and `400..720` at `x 0..20`.
  - Right: same at `x 1260..1280`.
- `SpawnGates`: 4 `Marker2D` in group `"spawn_gate"` at `(640,-40)`, `(640,760)`, `(-40,360)`, `(1340,360)`.
- `Player`: instance of `res://scenes/player/player.tscn` at center `(640,360)`.
- `Obstacles`:
  - 4 SteelBunker instances at `(320,180)` rot `0°`, `(960,180)` rot `90°`, `(960,540)` rot `180°`, `(320,540)` rot `270°`.
  - 3 SandbagBarricade instances at `(520,300)`, `(760,300)`, `(560,460)`.
  - 3 MudCrater instances at `(400,360)`, `(880,360)`, `(640,200)`.
- `Enemies`: empty `Node2D` container.
- `WaveDirector`: `Node` with `wave_director.gd`, child `SpawnTimer` (`Timer`, `wait_time = 3.0`, `autostart = false`).
- `arena_controller.gd`:
  - `const PLAYER_SPAWN: Vector2 = Vector2(640,360)`.
  - `_ready()` moves the first node in group `"player"` to `PLAYER_SPAWN`.
  - `reset_arena() -> void`: `GameManager.reset_run()`, `get_tree().paused = false`, `Engine.time_scale = 1.0`, and call `reset()` on `WaveDirector` if present. T-034 uses this.

### Camera shake (`camera_shake.gd`)
- `extends Camera2D`.
- `const MAX_OFFSET: float = 32.0`.
- State: `_intensity`, `_duration`, `_elapsed`, `_active`.
- `_ready()` connects `EventBus.camera_shake_requested`.
- New request replaces the active shake only if `intensity >= _intensity`; otherwise ignored.
- `_process(delta)`: linear falloff `1 - elapsed/duration`; `offset = random_unit * intensity * falloff`; when `elapsed >= duration`, `offset = Vector2.ZERO`, `_active = false`, `_intensity = 0.0`.

### Wave director (`wave_director.gd`)
- `extends Node`.
- `spawn_interval(t: float) -> float`: `maxf(0.8, 3.0 - 0.15 * floorf(t / 15.0))`.
- `pick_enemy_type(t: float, roll: float) -> String`:
  - `t < 45` → Scout.
  - `45 <= t < 90` → `roll < 0.70` Scout else Artillery.
  - `t >= 90` → `roll < 0.50` Scout, `roll < 0.85` Artillery, else Dreadnought.
- `spawn_enemy(scene_path: String) -> Node2D`: instantiate, place at a random gate marker from group `"spawn_gate"`, add to the arena's `Enemies` container.
- `_on_spawn_timer_timeout()`: only while `GameManager.state == PLAYING`; `t = GameManager.time_survived`; spawn; restart timer with `spawn_interval(t)`.
- `reset()`: stop the timer, then start it with `spawn_interval(0.0)` if state is PLAYING.
- State handling: on `game_state_changed`, entering `PLAYING` from non-`PAUSED` resets; entering `PAUSED`/`GAME_OVER` stops; resuming from `PAUSED` restarts with the current interval.

### T-027
- `VFXManager._on_enemy_destroyed` already emits `EventBus.camera_shake_requested.emit(5.0, 0.2)`.
- No new connection. Verification: one `enemy_destroyed` emission produces exactly one `(5.0, 0.2)` shake.

## Approaches Considered

1. **Perimeter walls:** 8 `StaticBody2D` segments with `RectangleShape2D` + `Polygon2D` (selected) vs. 4 `CollisionPolygon2D` loops vs. CSG. Segments keep the 80px gates exact and the collision simple.
2. **Bunker symmetry:** pinwheel rotations `0/90/180/270` (selected) vs. mirrored pair. Pinwheel gives 90° rotational symmetry and varied ricochet angles.
3. **Wave time source:** `GameManager.time_survived` (selected) vs. a private elapsed timer. `time_survived` already advances only while `PLAYING` and is reset by `reset_run()`.
4. **Camera shake channel:** `Camera2D.offset` (selected) vs. moving `position`. `offset` keeps the base camera position at `(640,360)`.
5. **Spawn point lookup:** the `"spawn_gate"` group (selected) vs. hard node paths. Group lookup avoids fragile paths across arena nodes.

## Review Focus

1. All four gates admit all three enemy types; the 80px opening is not blocked by walls, bunkers, or sandbags.
2. The center spawn `(640,360)` is clear of sandbags and mud, and the player is not stuck inside geometry.
3. Wave interval boundaries at `t = 14.9, 15, 30, 75, 300` and probability boundaries at `0.49/0.50/0.69/0.70/0.84/0.85`.
4. Wave spawning is stopped while `MENU`, `PAUSED`, or `GAME_OVER`, and restarted on a new run.
5. Camera shake returns exactly to `(0,0)`, ignores weaker requests, and `enemy_destroyed` emits one shake only.
