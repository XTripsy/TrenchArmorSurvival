# Phase 5 — Environment Design (T-021..T-023)

Status: approved for implementation.
Scope: `steel_bunker.tscn`, `sandbag_barricade.tscn` + `sandbag_barricade.gd`, `mud_crater.tscn` + `mud_crater.gd`.

## Intent

Implement the three static arena obstacles specified in TAD §5.4 and GDD §5.2:
1. Steel Bunker (T-021): Indestructible 45° angled metallic barricade that reflects player bullets and acts as cover.
2. Sandbag Barricade (T-022): Destructible cover that absorbs bullets (no bounce), loses HP on hit, shows visual damage (flash + shrink + crack), and is destroyed on the 3rd hit.
3. Mud Crater (T-023): Terrain hazard Area2D that slows player and enemies by 35% (`speed_multiplier = 0.65`) while inside, restoring to 1.0 on exit. Bullets pass through unaffected.

## Goals

- `scenes/environment/steel_bunker.tscn`:
  - `StaticBody2D`, collision_layer = 4 (Layer 3: Environment), collision_mask = 0.
  - In group `"bouncy_surface"` so `player_bullet.gd` bounces off it.
  - Procedural visuals: 96×96 wedge at 45° angle with darker steel border and rivet details. No external assets.
  - Indestructible (no `take_damage` method).
- `scenes/environment/sandbag_barricade.tscn` + `scripts/environment/sandbag_barricade.gd`:
  - `StaticBody2D`, collision_layer = 4 (Layer 3: Environment), collision_mask = 0.
  - In group `"destructible_cover"`. MUST NOT be in `"bouncy_surface"`.
  - HP = 3.
  - `take_damage(amount: int, _is_ricochet: bool = false) -> void`:
    - Decrements HP.
    - Flashes white for 0.1s via Tween.
    - Shrinks visually by ~8% per hit (`scale *= 0.92`).
    - At HP == 1, enables visible crack polygon/line.
    - When HP <= 0, disables collisions, spawns one-shot debris/dust particles, and `queue_free()`.
- `scenes/environment/mud_crater.tscn` + `scripts/environment/mud_crater.gd`:
  - `Area2D`, collision_layer = 32 (Layer 6: TerrainHazard), collision_mask = 3 (Layer 1: Player + Layer 2: Enemy), `z_index = -1`.
  - Bullets (Layers 4 & 5) do not mask Layer 6 and do not interact.
  - Shape: circular / organic dark mud polygon (~80px radius), collision circle radius 80.
  - `body_entered(body: Node2D)`: if `body.get("speed_multiplier") != null`, set `body.speed_multiplier = 0.65`.
  - `body_exited(body: Node2D)`: if `body.get("speed_multiplier") != null`, set `body.speed_multiplier = 1.0`.

## Approaches Considered

1. **Bunker shape:**
   - Option A (Selected): Right-triangle wedge with a 45° hypotenuse face (`Vector2(0,0)`, `Vector2(96,0)`, `Vector2(0,96)` or symmetric wedge centered). Direct 45° ricochet surface, clean physics reflection.
   - Option B: Rotated square. Redundant corners, clunkier placement in quadrant layout.
   - Option C: Hexagonal block. Complex collision normals, fewer predictable ricochet angles.

2. **Sandbag visual degradation:**
   - Option A (Selected): Flash + progressive scale shrinking (`0.92^n`) + crack lines on final HP + CPUParticles2D dust/fabric on death. Fully procedural, zero assets, satisfies TAD §5.4 "white flash and slight shrinking/cracking".
   - Option B: Multiple pre-drawn sprite stages. Violates zero-asset rule.

3. **Mud overlap handling:**
   - Option A (Selected): Literal TAD implementation — entered = 0.65, exited = 1.0. T-024 places 3 non-overlapping craters.
   - Option B: Overlap reference counter. Adds state complexity not requested by spec.

## Contracts

### `steel_bunker.tscn`
```text
StaticBody2D (groups=["bouncy_surface"], collision_layer=4, collision_mask=0)
  ├── CollisionPolygon2D (polygon: [(-48,48), (48,48), (48,-48)])
  └── Visual (Polygon2D, color=#6E7478)
        ├── Border (Line2D, color=#36393F, width=3)
        └── Rivets (Polygon2D x3, color=#B0B5B9)
```

### `sandbag_barricade.gd`
```gdscript
class_name SandbagBarricade
extends StaticBody2D

const MAX_HP: int = 3
var hp: int = MAX_HP
var _alive: bool = true

@onready var visual: Node2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var crack_visual: Node2D = $Visual/Crack

func _ready() -> void:
	add_to_group("destructible_cover")
	collision_layer = 4 # Layer 3: Environment
	collision_mask = 0
	hp = MAX_HP
	if crack_visual != null:
		crack_visual.visible = false

func take_damage(amount: int, _is_ricochet: bool = false) -> void:
	if not _alive:
		return
	hp = maxi(0, hp - amount)
	_flash_and_shrink()
	if hp == 1 and crack_visual != null:
		crack_visual.visible = true
	if hp <= 0:
		_destroy()

func _flash_and_shrink() -> void:
	modulate = Color(8.0, 8.0, 8.0, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	if visual != null:
		visual.scale = Vector2.ONE * (1.0 - 0.08 * float(MAX_HP - hp))

func _destroy() -> void:
	_alive = false
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	_spawn_debris_particles()
	visual.visible = false
	# Keep the root alive briefly so the debris particles can finish.
	get_tree().create_timer(0.4).timeout.connect(queue_free)
```

### `mud_crater.gd`
```gdscript
class_name MudCrater
extends Area2D

const SLOWDOWN_MULTIPLIER: float = 0.65

func _ready() -> void:
	collision_layer = 32 # Layer 6: TerrainHazard
	collision_mask = 3  # Layers 1 (Player) + 2 (Enemy)
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

## Review Focus

1. Sandbag must NOT bounce player bullets: `player_bullet.gd` checks `take_damage` first, but sandbag must not belong to `bouncy_surface` group.
2. Sandbag destruction on exact 3rd hit from either player bullet or enemy bullet.
3. Steel bunker reflects player bullet, causes ricochet sound/sparks, turns bullet orange, and remains indestructible.
4. Mud crater does not block or destroy bullets (bullet mask does not include layer 6).
5. Mud crater slows both Player and BaseEnemy (Scout, Artillery, Dreadnought) and restores speed on exit.
