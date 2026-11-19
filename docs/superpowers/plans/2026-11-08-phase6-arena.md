# Phase 6 — Arena & Wave Director Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the playable 1280×720 arena with gated perimeter walls, bunkers, sandbags, mud craters, player spawn, camera shake, and the time-based wave director.

**Architecture:** `scenes/arena.tscn` owns the layout and instances Phase 2-5 scenes. `scripts/arena/arena_controller.gd` snaps the player to center and exposes `reset_arena()`. `scripts/arena/camera_shake.gd` listens to `EventBus.camera_shake_requested` and offsets the arena `Camera2D`. `scripts/arena/wave_director.gd` reads `GameManager.time_survived`, selects an enemy type, and spawns it at a random gate marker in group `"spawn_gate"` under `Arena/Enemies`.

**Tech Stack:** Godot 4.7 GDScript, strict static typing, zero external assets.

**Spec:** `docs/superpowers/specs/2026-11-08-phase6-arena-design.md`

## Global Constraints

- Strict static typing on every `var`, parameter, and return type.
- No external assets: `Polygon2D` / `Line2D` / `CPUParticles2D` only.
- Layer 3 (`Environment`) = `4`; enemy layer 2 = `2`.
- Wall segments are in group `"bouncy_surface"` so player bullets ricochet.
- Gate markers are in group `"spawn_gate"`.
- Wave timing uses `GameManager.time_survived`; no private clock.
- Filter spawn gates to markers owned by this arena (`arena.is_ancestor_of(gate)`), so multiple arenas in a harness cannot cross-spawn.
- Folder is not a git repo: "one task = one commit" becomes "one task = ledger entry + harness run".
- Temporary harness under `tests/` is deleted before completion.

---

### Task 1: Arena layout + arena controller (T-024)

**Files:**
- Create: `scenes/arena.tscn`
- Create: `scripts/arena/arena_controller.gd`
- Create: `tests/phase6_check.gd`
- Create: `tests/phase6_check.tscn`

**Interfaces:**
- Produces: arena root `Node2D` name `Arena`, script `arena_controller.gd`.
- Produces: `ArenaController.PLAYER_SPAWN: Vector2 = Vector2(640.0, 360.0)`, `reset_arena() -> void`.
- Produces: node names used by later tasks and the harness: `Background`, `PerimeterWalls`, `Obstacles`, `Player`, `SpawnGates`, `Enemies`, `WaveDirector`, `Camera2D`.

- [ ] **Step 1: Write the harness skeleton with arena assertions**

`tests/phase6_check.gd` starts with a `_ready()` runner (collect failures, print `PHASE6_CHECK: PASS/FAIL`, `get_tree().quit(0/1)`), `_check(condition, label)`, `_approx(a, b, eps)`, `_physics_ticks(count)`, and a `_load_arena()` helper storing the instance in `_arena`.

Arena assertions:
- `ResourceLoader.exists("res://scenes/arena.tscn")`.
- root is `Node2D` and has script `arena_controller.gd`.
- `Background` is `Polygon2D`, `z_index == -100`, color `Color("#4A3B32")`, and its polygon bounds cover `Rect2(0, 0, 1280, 720)`.
- `Camera2D` child at `(640, 360)`.
- `PerimeterWalls` has exactly 8 children; every child is `StaticBody2D`, `collision_layer == 4`, `collision_mask == 0`, `is_in_group("bouncy_surface")`, and has a `CollisionShape2D` with `RectangleShape2D`.
- Gate openings (no wall rect intersects these `Rect2`s; `Rect2.intersects` without borders):
  - top `Rect2(600, 0, 80, 20)`, bottom `Rect2(600, 700, 80, 20)`,
  - left `Rect2(0, 320, 20, 80)`, right `Rect2(1260, 320, 20, 80)`.
  Wall rect = `Rect2(global_position - size / 2.0, size)`.
- `SpawnGates` has exactly 4 `Marker2D` in group `"spawn_gate"` at `(640,-40)`, `(640,760)`, `(-40,360)`, `(1340,360)`.
- `Player` exists at `(640, 360)` and is in group `"player"`.
- `Obstacles` children:
  - 4 bunkers: `BunkerNW (320,180) rot 0`, `BunkerNE (960,180) rot PI/2`, `BunkerSE (960,540) rot PI`, `BunkerSW (320,540) rot 3PI/2`; each `is_in_group("bouncy_surface")`.
  - 3 sandbags: `SandbagA (520,300)`, `SandbagB (760,300)`, `SandbagC (560,460)`; each in group `"destructible_cover"`.
  - 3 mud craters: `MudA (400,360)`, `MudB (880,360)`, `MudC (640,200)`; each `is Area2D`.
- `Enemies` is an empty `Node2D`.
- `WaveDirector` exists as `Node`.
- Center spawn is clear: `Player` not inside any sandbag/bunker/mud global rect/circle. Check distance from `(640,360)` to each sandbag > 60, to each bunker > 60, to each mud > 80.
- Gate entry: for each of the 4 gate markers and each of the 3 enemy scenes, instantiate the enemy at the marker under `Arena/Enemies`, run `_ENTRY_TICKS[type]` physics ticks (scout 45, artillery 60, dreadnought 90), assert the enemy is still valid and its global position is inside `Rect2(30, 30, 1220, 660)`, then free it. Wait one frame between runs.

- [ ] **Step 2: Run harness to verify it fails**

Run:
```
godot --headless --path . res://tests/phase6_check.tscn
```
Expected: FAIL, `arena.tscn` does not exist.

- [ ] **Step 3: Create `scripts/arena/arena_controller.gd`**

```gdscript
class_name ArenaController
extends Node2D

const PLAYER_SPAWN: Vector2 = Vector2(640.0, 360.0)

func _ready() -> void:
	_snap_player_to_spawn()

func _snap_player_to_spawn() -> void:
	var player: Node2D = get_node_or_null("Player") as Node2D
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		player.global_position = PLAYER_SPAWN

func reset_arena() -> void:
	GameManager.reset_run()
	get_tree().paused = false
	Engine.time_scale = 1.0
	var director: Node = get_node_or_null("WaveDirector")
	if director != null and director.has_method("reset"):
		director.call("reset")
```

- [ ] **Step 4: Create `scenes/arena.tscn`**

Node tree (wall rect sizes; wall visual `Polygon2D` matches the rect, color `#2B2320`):
```
Arena (Node2D, script arena_controller.gd)
├── Background (Polygon2D, z_index=-100, color #4A3B32, polygon (0,0)(1280,0)(1280,720)(0,720))
├── PerimeterWalls (Node2D, 8 StaticBody2D children, groups=["bouncy_surface"], layer 4, mask 0)
│   ├── WallTopLeft    position (300,10)    Rect 600×20
│   ├── WallTopRight   position (980,10)    Rect 600×20
│   ├── WallBottomLeft position (300,710)   Rect 600×20
│   ├── WallBottomRight position (980,710)  Rect 600×20
│   ├── WallLeftTop    position (10,160)    Rect 20×320
│   ├── WallLeftBottom position (10,560)    Rect 20×320
│   ├── WallRightTop   position (1270,160)  Rect 20×320
│   └── WallRightBottom position (1270,560) Rect 20×320
├── SpawnGates (Node2D)
│   ├── GateTop    (Marker2D, group spawn_gate, (640,-40))
│   ├── GateBottom (Marker2D, group spawn_gate, (640,760))
│   ├── GateLeft   (Marker2D, group spawn_gate, (-40,360))
│   └── GateRight  (Marker2D, group spawn_gate, (1340,360))
├── Obstacles (Node2D)
│   ├── BunkerNW (steel_bunker.tscn, (320,180), rotation 0)
│   ├── BunkerNE (steel_bunker.tscn, (960,180), rotation 1.5707964)
│   ├── BunkerSE (steel_bunker.tscn, (960,540), rotation 3.1415927)
│   ├── BunkerSW (steel_bunker.tscn, (320,540), rotation 4.712389)
│   ├── SandbagA (sandbag_barricade.tscn, (520,300))
│   ├── SandbagB (sandbag_barricade.tscn, (760,300))
│   ├── SandbagC (sandbag_barricade.tscn, (560,460))
│   ├── MudA (mud_crater.tscn, (400,360))
│   ├── MudB (mud_crater.tscn, (880,360))
│   └── MudC (mud_crater.tscn, (640,200))
├── Enemies (Node2D)
├── Player (player.tscn, (640,360))
├── Camera2D (position (640,360))
└── WaveDirector (Node)
    └── SpawnTimer (Timer, wait_time 3.0, autostart false)
```
No `camera_shake.gd` or `wave_director.gd` reference yet (Tasks 2 and 3 add them).

- [ ] **Step 5: Run harness to verify arena passes**

Expected: arena checks PASS; camera/wave checks do not exist yet. Exit 0.

- [ ] **Step 6: Ledger**

Append to `docs/superpowers/plans/2026-11-08-phase6-arena.progress.md`:
`Task 1: complete (tests: phase6_check arena checks → PASS)`.

---

### Task 2: Camera shake (T-025)

**Files:**
- Create: `scripts/arena/camera_shake.gd`
- Modify: `scenes/arena.tscn` (attach script to `Camera2D`)
- Modify: `tests/phase6_check.gd`

**Interfaces:**
- Consumes: `EventBus.camera_shake_requested(intensity: float, duration: float)`.
- Produces: `class_name CameraShake extends Camera2D`, `const MAX_OFFSET: float = 32.0`, `var _intensity: float`, `var _duration: float`, `var _elapsed: float`, `var _active: bool`, `_on_camera_shake_requested(intensity: float, duration: float) -> void`.

- [ ] **Step 1: Add the camera shake test**

Add `_test_camera_shake()` and call it from `_run_all()`. Requires `_arena`.

Assertions:
- `Arena/Camera2D` has a script and `has_method("_on_camera_shake_requested")`.
- Emit `EventBus.camera_shake_requested.emit(10.0, 0.5)`; after 2 process frames, `camera.offset.length() > 0.5`.
- Emit `EventBus.camera_shake_requested.emit(1.0, 10.0)` while active; assert `float(camera.get("_intensity")) == 10.0` (weaker request ignored).
- Emit `EventBus.camera_shake_requested.emit(20.0, 0.2)`; assert `_intensity == 20.0` (stronger request replaces).
- Wait `0.35` s real time; assert `camera.offset.is_equal_approx(Vector2.ZERO)` and `_active == false`.

- [ ] **Step 2: Run harness to verify it fails**

Expected: FAIL, camera has no script.

- [ ] **Step 3: Create `scripts/arena/camera_shake.gd`**

```gdscript
class_name CameraShake
extends Camera2D

const MAX_OFFSET: float = 32.0

var _intensity: float = 0.0
var _duration: float = 0.0
var _elapsed: float = 0.0
var _active: bool = false

func _ready() -> void:
	offset = Vector2.ZERO
	EventBus.camera_shake_requested.connect(_on_camera_shake_requested)

func _on_camera_shake_requested(intensity: float, duration: float) -> void:
	if intensity < _intensity or duration <= 0.0:
		return
	_intensity = minf(intensity, MAX_OFFSET)
	_duration = duration
	_elapsed = 0.0
	_active = true

func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	if _elapsed >= _duration:
		offset = Vector2.ZERO
		_intensity = 0.0
		_duration = 0.0
		_elapsed = 0.0
		_active = false
		return
	var falloff: float = 1.0 - (_elapsed / _duration)
	var direction: Vector2 = Vector2.from_angle(randf() * TAU)
	offset = direction * _intensity * falloff
```

- [ ] **Step 4: Attach the script to `Camera2D` in `scenes/arena.tscn`**

Add `[ext_resource type="Script" path="res://scripts/arena/camera_shake.gd" ...]` and `script = ExtResource(...)` on the `Camera2D` node.

- [ ] **Step 5: Run harness to verify camera passes**

Expected: camera checks PASS.

- [ ] **Step 6: Ledger**

`Task 2: complete (tests: phase6_check camera shake checks → PASS)`.

---

### Task 3: Wave director (T-026)

**Files:**
- Create: `scripts/arena/wave_director.gd`
- Modify: `scenes/arena.tscn` (attach script to `WaveDirector`)
- Modify: `tests/phase6_check.gd`

**Interfaces:**
- Consumes: `GameManager.time_survived`, `GameManager.state`, `GameManager.State`, `EventBus.game_state_changed(new_state: int)`.
- Produces: `class_name WaveDirector extends Node`.
  - `const ENEMY_SCENES: Dictionary = { "scout": "...", "artillery": "...", "dreadnought": "..." }`
  - `spawn_interval(t: float) -> float`
  - `pick_enemy_type(t: float, roll: float) -> String`
  - `spawn_enemy(scene_path: String) -> Node2D`
  - `spawn_wave() -> Node2D`
  - `reset() -> void`
  - `_on_spawn_timer_timeout() -> void`, `_on_game_state_changed(new_state: int) -> void`

- [ ] **Step 1: Add the wave director tests**

Add `_test_wave_director()` and call it from `_run_all()`. Requires `_arena`.

Assertions:
- `WaveDirector` has script and `has_method("spawn_interval")`.
- `spawn_interval`: `t=0 → 3.0`; `14.9 → 3.0`; `15 → 2.85`; `30 → 2.7`; `45 → 2.55`; `75 → 2.25`; `300 → 0.8` (clamped).
- `pick_enemy_type`:
  - `t=0, roll=0.99 → "scout"`
  - `t=44.9, roll=0.99 → "scout"`
  - `t=60, roll=0.69 → "scout"`, `0.70 → "artillery"`, `0.99 → "artillery"`
  - `t=90, roll=0.49 → "scout"`, `0.50 → "artillery"`, `0.84 → "artillery"`, `0.85 → "dreadnought"`
- Type → scene path mapping exists for all three keys and each path `ResourceLoader.exists`.
- State gating:
  - `GameManager.change_state(GameManager.State.MENU)`; capture `Enemies` count; call `spawn_wave()`; count unchanged.
  - `GameManager.change_state(GameManager.State.PLAYING)`; call `spawn_wave()`; count +1; spawned child's global position equals one of the 4 gate positions.
  - `SpawnTimer.wait_time` after that call equals `spawn_interval(GameManager.time_survived)` (read time before/after within tolerance; set `GameManager.time_survived = 60.0` first, expect `2.4`).
  - `GameManager.change_state(GameManager.State.PAUSED)`; assert `SpawnTimer.is_stopped()`.
  - `GameManager.change_state(GameManager.State.PLAYING)`; assert `not SpawnTimer.is_stopped()`.
  - `director.call("reset")`; assert timer running and `wait_time == 3.0` (because `reset_run()` sets `time_survived = 0`, OR reset uses current time — if `time_survived` is nonzero, `spawn_interval(t)`).
  - Stop the timer and return state to `MENU` at the end.

- [ ] **Step 2: Run harness to verify it fails**

Expected: FAIL, `WaveDirector` has no script / no `spawn_interval`.

- [ ] **Step 3: Create `scripts/arena/wave_director.gd`**

```gdscript
class_name WaveDirector
extends Node

const ENEMY_SCENES: Dictionary = {
	"scout": "res://scenes/enemies/enemy_scout.tscn",
	"artillery": "res://scenes/enemies/enemy_artillery.tscn",
	"dreadnought": "res://scenes/enemies/enemy_dreadnought.tscn",
}
const MIN_INTERVAL: float = 0.8
const BASE_INTERVAL: float = 3.0
const INTERVAL_STEP: float = 0.15
const INTERVAL_PERIOD: float = 15.0
const SCOUT_ONLY_UNTIL: float = 45.0
const DREADNOUGHT_FROM: float = 90.0
const SCOUT_CUTOFF_MID: float = 0.70
const SCOUT_CUTOFF_LATE: float = 0.50
const ARTILLERY_CUTOFF_LATE: float = 0.85

var _arena: Node2D = null
var _enemies: Node2D = null
var _last_state: int = int(GameManager.State.MENU)

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	_arena = get_parent() as Node2D
	_enemies = _arena.get_node_or_null("Enemies") as Node2D
	_last_state = int(GameManager.state)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	EventBus.game_state_changed.connect(_on_game_state_changed)
	if GameManager.state == GameManager.State.PLAYING:
		spawn_timer.start(spawn_interval(GameManager.time_survived))

func spawn_interval(t: float) -> float:
	var steps: float = floorf(maxf(t, 0.0) / INTERVAL_PERIOD)
	return maxf(MIN_INTERVAL, BASE_INTERVAL - INTERVAL_STEP * steps)

func pick_enemy_type(t: float, roll: float) -> String:
	if t < SCOUT_ONLY_UNTIL:
		return "scout"
	if t < DREADNOUGHT_FROM:
		return "scout" if roll < SCOUT_CUTOFF_MID else "artillery"
	if roll < SCOUT_CUTOFF_LATE:
		return "scout"
	if roll < ARTILLERY_CUTOFF_LATE:
		return "artillery"
	return "dreadnought"

func spawn_enemy(scene_path: String) -> Node2D:
	if not ResourceLoader.exists(scene_path):
		return null
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		return null
	var enemy: Node2D = packed.instantiate() as Node2D
	if enemy == null:
		return null
	var container: Node2D = _enemies if _enemies != null else _arena
	container.add_child(enemy)
	enemy.global_position = _random_gate_position()
	return enemy

func spawn_wave() -> Node2D:
	if GameManager.state != GameManager.State.PLAYING:
		return null
	var t: float = GameManager.time_survived
	var type: String = pick_enemy_type(t, randf())
	return spawn_enemy(ENEMY_SCENES[type] as String)

func reset() -> void:
	spawn_timer.stop()
	if GameManager.state == GameManager.State.PLAYING:
		spawn_timer.start(spawn_interval(GameManager.time_survived))

func _random_gate_position() -> Vector2:
	var gates: Array[Node] = []
	if _arena == null:
		return Vector2.ZERO
	for node: Node in get_tree().get_nodes_in_group("spawn_gate"):
		if _arena.is_ancestor_of(node):
			gates.append(node)
	if gates.is_empty():
		return _arena.global_position
	var marker: Marker2D = gates.pick_random() as Marker2D
	return marker.global_position if marker != null else _arena.global_position

func _on_spawn_timer_timeout() -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	var t: float = GameManager.time_survived
	spawn_wave()
	spawn_timer.start(spawn_interval(t))

func _on_game_state_changed(new_state: int) -> void:
	var playing: int = int(GameManager.State.PLAYING)
	var paused: int = int(GameManager.State.PAUSED)
	if new_state == playing:
		if _last_state != paused:
			reset()
		else:
			spawn_timer.start(spawn_interval(GameManager.time_survived))
	else:
		spawn_timer.stop()
	_last_state = new_state
```

- [ ] **Step 4: Attach the script to `WaveDirector` in `scenes/arena.tscn`**

Add `[ext_resource type="Script" path="res://scripts/arena/wave_director.gd" ...]` and `script = ExtResource(...)` on the `WaveDirector` node.

- [ ] **Step 5: Run harness to verify wave director passes**

Expected: wave checks PASS.

- [ ] **Step 6: Ledger**

`Task 3: complete (tests: phase6_check wave director checks → PASS)`.

---

### Task 4: T-027 shake verification, full verification, docs

**Files:**
- Modify: `tests/phase6_check.gd`
- Delete: `tests/` after verification
- Modify: `TODO_TrenchArmorSurvival.md`
- Modify: `docs/superpowers/plans/2026-11-08-phase6-arena.progress.md`

- [ ] **Step 1: Add the T-027 single-emission test**

Add `_test_enemy_destroyed_shake()` and call it from `_run_all()`.

Assertions:
- Count `EventBus.enemy_destroyed.get_connections()` whose callable object is `VFXManager` and method is `_on_enemy_destroyed` → exactly 1.
- Connect a capture to `EventBus.camera_shake_requested`; emit `EventBus.enemy_destroyed.emit(Vector2(100.0, 100.0), 100, false)`; wait 2 process frames; assert exactly 1 captured request and it equals `(5.0, 0.2)`; disconnect capture.
- Do not add a new connection to any script.

- [ ] **Step 2: Run the full harness**

Run:
```
godot --headless --path . res://tests/phase6_check.tscn
```
Expected: `PHASE6_CHECK: PASS (N checks)`, exit 0.

- [ ] **Step 3: Delete the harness**

Remove `tests/`. Expected: `tests/` does not exist.

- [ ] **Step 4: Run headless editor validation**

Run:
```
godot --headless --path . --editor --quit
```
Expected: exit 0, no `ERROR`, `Parse Error`, or `WARNING` lines.

- [ ] **Step 5: Update `TODO_TrenchArmorSurvival.md`**

- Mark T-024..T-027 `[x]`.
- Snapshot → `2026-11-08 · Engine 4.7.2.stable.steam.ed1daf0bf · Next: Phase 7 (T-028..)`.
- Add Phase 6 table row with harness evidence.
- Add "Phase 6 — Arena & Wave Director" summary.
- Add verification evidence, rulings, and links to Phase 6 spec/plan/ledger.

- [ ] **Step 6: Final ledger entry**

Record the full harness result, editor validation result, and harness removal.
