# Phase 5 — Environment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the three arena obstacles: indestructible SteelBunker (45° ricochet mirror), destructible SandbagBarricade (3 HP, no bounce), and MudCrater (35% slowdown Area2D).

**Architecture:** Each obstacle is a standalone scene under `scenes/environment/`. SteelBunker is pure scene (StaticBody2D + CollisionPolygon2D + procedural polygons). SandbagBarricade adds a self-contained script for HP, hit feedback, crack state, and destruction particles. MudCrater adds a script that toggles `speed_multiplier` on any body that has that property.

**Tech Stack:** Godot 4.7 GDScript, strict static typing, zero external assets.

**Spec:** `docs/superpowers/specs/2026-11-08-phase5-environment-design.md`

## Global Constraints

- Strict static typing on every `var`, parameter, and return type.
- No external assets: all visuals are `Polygon2D` / `Line2D` / `CPUParticles2D`.
- Layer values are bitmasks: Layer 3 (`Environment`) = `4`; Layer 6 (`TerrainHazard`) = `32`; Layer 1 + 2 = `3`.
- SteelBunker is in group `"bouncy_surface"` and has no `take_damage` method.
- SandbagBarricade is in group `"destructible_cover"` and must NOT be in `"bouncy_surface"`.
- MudCrater collision mask must be `3` so bullets (Layers 4 and 5) never interact.
- Folder is not a git repo: "one task = one commit" is replaced by "one task = ledger entry + harness run".
- Do not create files outside §2 of `TODO_TrenchArmorSurvival.md`; `tests/` is temporary and deleted before completion.

## Review Focus

1. Sandbag must not bounce player bullets: `player_bullet.gd` checks `take_damage` first, and the sandbag must stay out of `"bouncy_surface"`.
2. Sandbag must be destroyed on exactly the 3rd hit from either player or enemy bullets, and ignore further hits while dying.
3. SteelBunker must reflect a player bullet off its 45° face (velocity turns vertical), turn it orange, and survive.
4. MudCrater must not block or alter bullets; its mask excludes bullet layers 4 and 5.
5. MudCrater must slow both Player and BaseEnemy (both expose `speed_multiplier`) and restore `1.0` on exit.

---

### Task 1: SteelBunker + verification harness (T-021)

**Files:**
- Create: `scenes/environment/steel_bunker.tscn`
- Create: `tests/phase5_check.gd`
- Create: `tests/phase5_check.tscn`

**Interfaces:**
- Produces: scene root `StaticBody2D`, `collision_layer = 4`, `collision_mask = 0`, group `"bouncy_surface"`, child `CollisionPolygon2D`, visual node `Visual`.
- Produces: harness entry scene `res://tests/phase5_check.tscn` whose script prints `PHASE5_CHECK: PASS (N checks)` and exits 0 on success, exit 1 on failure.

- [ ] **Step 1: Write the harness with the bunker test**

`tests/phase5_check.gd` starts with a `_ready()` runner (collect failures, print PASS/FAIL, `get_tree().quit(0/1)`), `_check(condition, label)`, `_approx(a, b, eps)`, and `_physics_ticks(count)`. Initial `_run_all()` calls only `_test_bunker()`.

Bunker assertions:
- `ResourceLoader.exists("res://scenes/environment/steel_bunker.tscn")`
- instantiated root `is StaticBody2D`
- `collision_layer == 4`, `collision_mask == 0`
- `is_in_group("bouncy_surface")`
- no `take_damage` method
- `get_node_or_null("CollisionPolygon2D") != null`
- bounce integration: place bunker at `(400, 300)`, spawn `player_bullet.tscn` with `direction = Vector2.RIGHT` at `(100, 300)`, run up to 60 physics frames, then assert bullet still valid, `bounce_count == 1`, `is_ricochet == true`, and `absf(bullet.velocity.x) < 50.0`.

- [ ] **Step 2: Run harness to verify it fails**

Run:
```
godot --headless --path . res://tests/phase5_check.tscn
```
Expected: FAIL, the bunker scene does not exist.

- [ ] **Step 3: Create `scenes/environment/steel_bunker.tscn`**

Node tree:
```
StaticBody2D (name="SteelBunker", groups=["bouncy_surface"], collision_layer=4, collision_mask=0)
├── CollisionPolygon2D (polygon = [(-48,48), (48,48), (48,-48)])
└── Visual (Polygon2D, color = #6E7478, polygon = same as collision)
    ├── Border (Line2D, closed, width 3, color = #36393F, points = same polygon + first point)
    └── Rivets (Node2D)
        ├── Rivet1 (Polygon2D, circle approx radius 3 at (30, 10))
        ├── Rivet2 (Polygon2D, circle approx radius 3 at (30, 30))
        └── Rivet3 (Polygon2D, circle approx radius 3 at (10, 30))
```
The 45° hypotenuse runs from `(48,-48)` to `(-48,48)` and faces the upper-left, so a bullet travelling right at local `y = 0` hits it at `x = 0`.

- [ ] **Step 4: Run harness to verify bunker passes**

Expected: bunker checks PASS. Sandbag/Mud checks do not exist yet.

- [ ] **Step 5: Ledger**

Append to `docs/superpowers/plans/2026-11-08-phase5-environment.progress.md`:
`Task 1: complete (tests: phase5_check bunker checks → PASS)`.

---

### Task 2: SandbagBarricade (T-022)

**Files:**
- Create: `scenes/environment/sandbag_barricade.tscn`
- Create: `scripts/environment/sandbag_barricade.gd`
- Modify: `tests/phase5_check.gd`

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: `class_name SandbagBarricade extends StaticBody2D`, `const MAX_HP: int = 3`, `var hp: int`, `take_damage(amount: int, _is_ricochet: bool = false) -> void`.
- Scene nodes: `CollisionShape2D`, `Visual` (`Node2D`), `Visual/Crack` (`Line2D`, initially `visible = false`).

- [ ] **Step 1: Add the sandbag test**

Add `_test_sandbag()` and call it from `_run_all()`.

Assertions:
- scene exists; root `is StaticBody2D`; `collision_layer == 4`; `collision_mask == 0`
- in group `"destructible_cover"`; NOT in `"bouncy_surface"`
- has `take_damage`; `hp == 3`
- after `take_damage(1, false)` twice: `hp == 1`, still valid, `Visual/Crack.visible == true`
- after third `take_damage(1, false)`: `_alive == false`, `visual.visible == false`; after one `process_frame`: `CollisionShape2D.disabled == true`; after 0.6 s: node freed
- fresh sandbag + player bullet: bullet is consumed, sandbag `hp == 2`, and no `EventBus.bullet_ricocheted` was emitted

- [ ] **Step 2: Run harness to verify it fails**

Expected: FAIL, `sandbag_barricade.tscn` does not exist.

- [ ] **Step 3: Create `scripts/environment/sandbag_barricade.gd`**

Implement:
```gdscript
class_name SandbagBarricade
extends StaticBody2D

const MAX_HP: int = 3

var hp: int = MAX_HP
var _alive: bool = true

@onready var visual: Node2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var crack_visual: Line2D = $Visual/Crack

func _ready() -> void:
	add_to_group("destructible_cover")
	collision_layer = 4
	collision_mask = 0
	hp = MAX_HP
	crack_visual.visible = false

func take_damage(amount: int, _is_ricochet: bool = false) -> void:
	if not _alive:
		return
	hp = maxi(0, hp - amount)
	_flash_and_shrink()
	crack_visual.visible = hp == 1
	if hp <= 0:
		_destroy()

func _flash_and_shrink() -> void:
	modulate = Color(8.0, 8.0, 8.0, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	visual.scale = Vector2.ONE * (1.0 - 0.08 * float(MAX_HP - hp))

func _destroy() -> void:
	_alive = false
	collision_shape.set_deferred("disabled", true)
	_spawn_debris_particles()
	visual.visible = false
	get_tree().create_timer(0.4).timeout.connect(queue_free)

func _spawn_debris_particles() -> void:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.amount = 12
	particles.lifetime = 0.35
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 90.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 120.0
	particles.gravity = Vector2(0.0, 300.0)
	particles.color = Color("#8B6F47")
	particles.emitting = true
	add_child(particles)
```

- [ ] **Step 4: Create `scenes/environment/sandbag_barricade.tscn`**

Node tree:
```
StaticBody2D (name="SandbagBarricade", collision_layer=4, collision_mask=0, script=sandbag_barricade.gd)
├── CollisionShape2D (RectangleShape2D 64x30)
└── Visual (Node2D)
    ├── Bag1 (Polygon2D, tan #8B6F47, rounded 64x12 at y=-9)
    ├── Bag2 (Polygon2D, tan #7A5F3C, rounded 60x12 at y=1)
    ├── Bag3 (Polygon2D, tan #8B6F47, rounded 64x12 at y=11)
    └── Crack (Line2D, width 2, color #2E241E, visible=false, crack polyline across the stack)
```
Do NOT add the `"bouncy_surface"` group.

- [ ] **Step 5: Run harness to verify sandbag passes**

Expected: sandbag checks PASS.

- [ ] **Step 6: Ledger**

`Task 2: complete (tests: phase5_check sandbag checks → PASS)`.

---

### Task 3: MudCrater (T-023)

**Files:**
- Create: `scenes/environment/mud_crater.tscn`
- Create: `scripts/environment/mud_crater.gd`
- Modify: `tests/phase5_check.gd`

**Interfaces:**
- Consumes: nothing from Tasks 1–2.
- Produces: `class_name MudCrater extends Area2D`, `const SLOWDOWN_MULTIPLIER: float = 0.65`, signal handlers `_on_body_entered(body: Node2D)` and `_on_body_exited(body: Node2D)`.

- [ ] **Step 1: Add the mud test**

Add `_test_mud()` and call it from `_run_all()`. Add an inner `FakeTank extends StaticBody2D` with `var speed_multiplier: float = 1.0`, `collision_layer = 1`, `collision_mask = 0`, and a 36×36 `RectangleShape2D`.

Assertions:
- scene exists; root `is Area2D`; `collision_layer == 32`; `collision_mask == 3`; `z_index == -1`
- `CollisionShape2D.shape is CircleShape2D` with radius `80.0`
- fake tank outside at 240 px: `speed_multiplier == 1.0`
- fake tank at crater center: `speed_multiplier == 0.65`
- fake tank back outside: `speed_multiplier == 1.0`
- player bullet spawned over the crater: still valid after 2 ticks and `velocity.length() == 650.0`

- [ ] **Step 2: Run harness to verify it fails**

Expected: FAIL, `mud_crater.tscn` does not exist.

- [ ] **Step 3: Create `scripts/environment/mud_crater.gd`**

Implement:
```gdscript
class_name MudCrater
extends Area2D

const SLOWDOWN_MULTIPLIER: float = 0.65

func _ready() -> void:
	collision_layer = 32
	collision_mask = 3
	z_index = -1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.get("speed_multiplier") != null:
		body.set("speed_multiplier", SLOWDOWN_MULTIPLIER)

func _on_body_exited(body: Node2D) -> void:
	if body.get("speed_multiplier") != null:
		body.set("speed_multiplier", 1.0)
```

- [ ] **Step 4: Create `scenes/environment/mud_crater.tscn`**

Node tree:
```
Area2D (name="MudCrater", collision_layer=32, collision_mask=3, z_index=-1, script=mud_crater.gd)
├── CollisionShape2D (CircleShape2D radius 80)
└── Visual (Polygon2D, color #2E241E, irregular 12-point polygon radius 70-90)
    └── Rim (Line2D, closed, width 3, color #1E1813, same polygon)
```

- [ ] **Step 5: Run harness to verify mud passes**

Expected: all Phase 5 checks PASS.

- [ ] **Step 6: Ledger**

`Task 3: complete (tests: phase5_check mud checks → PASS)`.

---

### Task 4: Full verification and documentation

**Files:**
- Delete: `tests/phase5_check.gd`, `tests/phase5_check.tscn` (and `tests/` if empty)
- Modify: `TODO_TrenchArmorSurvival.md`
- Modify: `docs/superpowers/plans/2026-11-08-phase5-environment.progress.md`

- [ ] **Step 1: Run the full harness one final time**

Run:
```
godot --headless --path . res://tests/phase5_check.tscn
```
Expected: `PHASE5_CHECK: PASS (N checks)`, exit 0.

- [ ] **Step 2: Delete the harness**

Remove `tests/`. Expected: `tests/` does not exist.

- [ ] **Step 3: Run headless editor validation**

Run:
```
godot --headless --path . --editor --quit
```
Expected: exit 0, no `ERROR`, `Parse Error`, or `WARNING` lines.

- [ ] **Step 4: Update `TODO_TrenchArmorSurvival.md`**

- Mark T-021, T-022, T-023 `[x]`.
- Snapshot → `2026-11-08 · Engine 4.7.2.stable.steam.ed1daf0bf · Next: Phase 6 (T-024..T-027)`.
- Add table row for Phase 5 with harness evidence.
- Add "Phase 5 — Environment" summary and verification evidence.
- Add Phase 5 rulings.
- Add links to Phase 5 plan, ledger, and spec.

- [ ] **Step 5: Final ledger entry**

Record the full harness result, editor validation result, and harness removal.
