# Technical Architecture Document (TAD): Trench Armor Survival

## 1. Engine Standards & Project Configuration

### 1.1. Core Specifications
* **Engine Target:** Godot Engine 4.2+ (tested on `4.7.2.stable`).
* **Scripting Language:** GDScript 2.0 with **Strict Static Typing** required on every variable, parameter, and return type (e.g. `var move_speed: float = 220.0`, `func apply_damage(amount: int, is_ricochet: bool) -> void:`).
* **Rendering Method:** `Forward+` or `Compatibility` (2D Orthographic).
* **Zero-Asset Dependency (Procedural Fallback):** All primary visual objects must be built using `Polygon2D`, `Line2D`, `_draw()`, and `CPUParticles2D`, with Hex color codes matching the GDD. The game must be fully playable through code before any external image assets are added.

### 1.2. Project Settings (`project.godot`)
* **Viewport Dimensions:** Width $= 1280\text{ px}$, Height $= 720\text{ px}$.
* **Stretch Mode:** `canvas_items` | **Stretch Aspect:** `keep`.
* **Physics Ticks per Second:** $60\text{ Hz}$.
* **Input Map Definitions:**
  * `move_up`: Key `W`, Key `Up`
  * `move_down`: Key `S`, Key `Down`
  * `move_left`: Key `A`, Key `Left`
  * `move_right`: Key `D`, Key `Right`
  * `shoot`: Mouse Button `Left`
  * `pause`: Key `Escape`

---

## 2. Directory & File Structure (`res://`)

The OpenCode agent must follow the directory structure below and must not create files outside the specified paths:

```text
res://
├── project.godot
├── autoloads/
│   ├── event_bus.gd          # Global Signal Hub (Decoupled Communication)
│   ├── game_manager.gd       # State Machine, Phase Progression, Score, Timer, & Hit-Stop
│   ├── vfx_manager.gd        # Particle, Debris, Scorch Mark, & Floating Text Spawner
│   └── audio_manager.gd      # Procedural/Polyphonic SFX & BGM Controller
├── scenes/
│   ├── main_menu.tscn        # Title Screen & Blueprint UI
│   ├── arena.tscn            # Main Gameplay Level (Inner 1280x720 + Expanded 2560x1440)
│   ├── player/
│   │   ├── player.tscn       # Player Tank
│   │   └── tread_mark.tscn   # Tank Track Marks (Line2D)
│   ├── projectiles/
│   │   ├── player_bullet.tscn
│   │   └── enemy_bullet.tscn
│   ├── enemies/
│   │   ├── enemy_scout.tscn
│   │   ├── enemy_artillery.tscn
│   │   ├── enemy_dreadnought.tscn
│   │   ├── enemy_pillbox.tscn
│   │   └── boss_goliath.tscn
│   ├── environment/
│   │   ├── steel_bunker.tscn
│   │   ├── sandbag_barricade.tscn
│   │   ├── mud_crater.tscn
│   │   └── capture_zone.tscn
│   └── ui/
│       ├── hud.tscn
│       ├── pause_menu.tscn
│       ├── game_over_menu.tscn
│       └── floating_text.tscn
└── scripts/
    ├── arena/
    │   ├── arena_controller.gd
    │   ├── camera_shake.gd
    │   └── wave_director.gd
    ├── player/
    │   └── player.gd
    ├── projectiles/
    │   ├── player_bullet.gd
    │   └── enemy_bullet.gd
    ├── enemies/
    │   ├── base_enemy.gd     # Parent class for all enemies & boss
    │   ├── enemy_scout.gd
    │   ├── enemy_artillery.gd
    │   ├── enemy_dreadnought.gd
    │   ├── enemy_pillbox.gd
    │   └── boss_goliath.gd
    ├── environment/
    │   ├── sandbag_barricade.gd
    │   ├── mud_crater.gd
    │   └── capture_zone.gd
    └── ui/
        ├── main_menu.gd
        ├── hud.gd
        ├── pause_menu.gd
        ├── game_over_menu.gd
        └── floating_text.gd
```

---

## 3. Physics & Collision Matrix

The collision detection system uses 6 Physics Layers and Node Groups to distinguish bouncing surfaces, destructible covers, and ground zones.

### 3.1. Collision Layers Table

| Bit / Layer | Layer Name | Objects on This Layer | Collision Mask (Detects Layers) |
| :--- | :--- | :--- | :--- |
| **Layer 1** | `Player` | `Player` (`CharacterBody2D`) | $2, 3, 5, 6$ |
| **Layer 2** | `Enemy` | `EnemyScout`, `EnemyArtillery`, `EnemyDreadnought`, `EnemyPillbox`, `BossGoliath` | $1, 2, 3, 4, 6$ |
| **Layer 3** | `Environment` | Perimeter Walls, Expansion Barriers, `SteelBunker`, `SandbagBarricade` | No mask required (Static) |
| **Layer 4** | `PlayerBullet` | `PlayerBullet` (`CharacterBody2D`) | $2, 3$ *(Ignore Layer 1 = No Self-Damage)* |
| **Layer 5** | `EnemyBullet` | `EnemyBullet` (`CharacterBody2D`) | $1, 3$ |
| **Layer 6** | `TerrainHazard` | `MudCrater` (`Area2D`), `CaptureZone` (`Area2D`) | $1, 2$ |

### 3.2. Node Groups (Surface & Entity Tagging)
* `"player"`: Assigned to the `Player` root node so enemy AI and capture zones can quickly find the player via `get_tree().get_first_node_in_group("player")`.
* `"enemy"`: Assigned to all enemy units and boss nodes so `CaptureZone` can detect contested status cleanly.
* `"boss"`: Assigned to `BossGoliath` root node for HUD/minimap tracking.
* `"bouncy_surface"`: Assigned to Perimeter Walls, Expansion Barriers, and `SteelBunker`. Player bullets only bounce when the collided object belongs to this group.
* `"destructible_cover"`: Assigned to `SandbagBarricade`. Absorbs bullets without bouncing and loses HP when hit.
* `"capture_zone"`: Assigned to `CaptureZone` root nodes for HUD off-screen indicators and minimap rendering.

---

## 4. Core Architecture & Autoload Singletons

To prevent spaghetti code and fragile `get_node()` references, the architecture uses the **Event-Driven Singleton** pattern.

### 4.1. `EventBus.gd` (Global Signals)
Stores all cross-system signals:
```gdscript
signal player_damaged(current_hp: int, max_hp: int)
signal player_died()
signal enemy_destroyed(enemy_position: Vector2, base_score: int, was_ricochet: bool)
signal score_updated(new_score: int, ricochet_kills: int)
signal camera_shake_requested(intensity: float, duration: float)
signal bullet_ricocheted(impact_position: Vector2, impact_normal: Vector2)
signal game_state_changed(new_state: int)
signal phase_changed(new_phase: int)
signal threat_updated(current_threat: float, max_threat: float)
signal boss_spawned(boss_name: String, current_hp: int, max_hp: int)
signal boss_hp_changed(current_hp: int, max_hp: int)
signal boss_defeated(boss_position: Vector2, base_score: int)
signal map_expanded(new_bounds: Rect2)
signal capture_zone_updated(zone_id: int, progress: float, state_name: String)
signal capture_zone_captured(zone_id: int, captured_count: int, total_count: int)
signal sector_cleared(sector_num: int, bonus_score: int)
```

### 4.2. `GameManager.gd` (State, Progression & Time Controller)
* **Enums:**
  * `enum State { MENU, PLAYING, PAUSED, GAME_OVER }`
  * `enum Phase { SKIRMISH, BOSS, INVASION }`
* **Tracked Metrics:**
  * `score: int = 0`
  * `time_survived: float = 0.0`
  * `ricochet_kills: int = 0`
  * `current_phase: Phase = Phase.SKIRMISH`
  * `sector_index: int = 1`
  * `threat_progress: float = 0.0` (`0.0` to `100.0`)
  * `zones_captured: int = 0`
  * `zones_total: int = 3`
* **Score & Threat Progression Logic:**
  When receiving `enemy_destroyed(pos, base_score, was_ricochet)`:
  * If `was_ricochet == true`, award $\text{base\_score} \times 2$ points, increment `ricochet_kills += 1`, and call `VFXManager.spawn_floating_text(pos, "+%d RICOCHET!" % (base_score * 2))`.
  * If `false`, award normal $\text{base\_score}$.
  * During `Phase.SKIRMISH`, increment `threat_progress` based on enemy value (e.g., `10.0` for `100` score, `15.0` for `200`, `25.0` for `500`), clamp to `100.0`, emit `threat_updated`, and transition to `Phase.BOSS` when `threat_progress >= 100.0`.
* **Hit-Stop / Freeze-Frame System:**
  `trigger_hit_stop(duration: float = 0.05) -> void:` sets `Engine.time_scale = 0.05` and restores it to `1.0` via `get_tree().create_timer(duration, true, false, true).timeout` with a sequence guard.

### 4.3. `VFXManager.gd` (Procedural Juice Generator)
* `spawn_muzzle_flash(pos: Vector2, rot: float) -> void`
* `spawn_ricochet_sparks(pos: Vector2, normal: Vector2) -> void`
* `spawn_tank_explosion(pos: Vector2) -> void`
* `spawn_floating_text(pos: Vector2, text: String) -> void`
* Auto-subscribes to `bullet_ricocheted` and `enemy_destroyed`.

### 4.4. `AudioManager.gd` (Procedural / Pool Audio)
Manages an 8-voice pool of `AudioStreamPlayer` nodes using `AudioStreamGenerator` procedural synthesis (`play_cannon()`, `play_enemy_cannon()`, `play_ricochet()`, `play_explosion()`, `play_hit()`, `play_engine(moving: bool)`, `stop_engine()`, `start_bgm()`, `stop_bgm()`).

---

## 5. Entity Specifications & Node Hierarchies

### 5.1. Player Tank (`res://scenes/player/player.tscn`)
* **Root Node:** `PlayerTank` (`CharacterBody2D`) — Group: `"player"`, Layer: $1$, Mask: $2, 3, 5, 6$, `MOTION_MODE_FLOATING`.
* **Key Variables & Methods (`player.gd`):**
  * `const MAX_HP: int = 3`, `const BASE_SPEED: float = 220.0`, `const TURN_SPEED: float = 10.0`, `const FIRE_COOLDOWN: float = 0.45`, `const RECOIL_FORCE: float = 40.0`, `const IFRAME_DURATION: float = 1.2`.
  * `var hp: int = MAX_HP`
  * `var speed_multiplier: float = 1.0`
  * `func heal(amount: int) -> void`: Restores `hp = mini(MAX_HP, hp + amount)` and emits `EventBus.player_damaged.emit(hp, MAX_HP)` so HUD shield icons update immediately.

### 5.2. Player Bullet (`res://scenes/projectiles/player_bullet.tscn`)
* **Root Node:** `PlayerBullet` (`CharacterBody2D`) — Layer: $4$, Mask: $2, 3$, `SPEED = 650.0`, `MAX_BOUNCES = 1`.
* Calls `collider.call("take_damage", 1, is_ricochet)` on damageable targets; bounces once on `"bouncy_surface"`, turns `#FF5500`, and emits `EventBus.bullet_ricocheted`.

### 5.3. Enemy Architecture (`BaseEnemy`, Subclasses & Boss)
All enemies inherit from `scripts/enemies/base_enemy.gd` (`CharacterBody2D`, Group: `"enemy"`, Layer: $2$, Mask: $1, 2, 3, 4, 6$).
* **`BaseEnemy` Properties:** `@export var max_hp: int = 1`, `@export var move_speed: float = 150.0`, `@export var base_score: int = 100`, `var speed_multiplier: float = 1.0`.
* **Standard Subclasses:**
  1. **`enemy_scout.gd`:** $\text{HP} = 1$, $\text{Speed} = 250.0$, $\text{Score} = 100$. Chases player, deals $1\text{ damage}$ on contact, then calls `die(false)`.
  2. **`enemy_artillery.gd`:** $\text{HP} = 1$, $\text{Speed} = 110.0$, $\text{Score} = 200$. Stops at $\le 350.0\text{ px}$ and fires `enemy_bullet.tscn` ($400\text{ px/s}$) every $2.5\text{ s}$.
  3. **`enemy_dreadnought.gd`:** $\text{HP} = 2$, $\text{Speed} = 70.0$, $\text{Score} = 500$, fires every $3.5\text{ s}$ ($350\text{ px/s}$). Instant kill when `from_ricochet == true`.
  4. **`enemy_pillbox.gd` (Invasion Defender):** $\text{HP} = 3$, $\text{Speed} = 0.0$, $\text{Score} = 300$. Stationary turret guarding Capture Zones in the expanded arena; aims at player and fires `enemy_bullet.tscn` ($400\text{ px/s}$) every $2.2\text{ s}$.
* **Boss Entity (`boss_goliath.gd`):**
  * Inherits `BaseEnemy`, added to group `"boss"`, scaled `~2.4x`, `base_score = 1500`.
  * `max_hp = 16 + 4 * (GameManager.sector_index - 1)`.
  * Overrides `take_damage(amount: int, from_ricochet: bool) -> void`: deals `2` damage if `from_ricochet == true`, else `1` damage; emits `EventBus.boss_hp_changed.emit(hp, max_hp)`.
  * Cycles 3 attack states:
    1. **Spread Volley:** Fires 3 `enemy_bullet.tscn` projectiles in a fan spread (`-18°`, `0°`, `+18°`) toward the player.
    2. **Mortar Telegraph:** Spawns a temporary ground warning ring (`1.1s` telegraph) at the player's predicted/current spot that detonates for `1` area damage if the player remains inside.
    3. **Heavy Advance:** Moves toward the player at `move_speed = 65.0` between attacks.
  * Overrides `die(from_ricochet: bool) -> void`: emits `EventBus.boss_defeated.emit(global_position, base_score)` in addition to explosion VFX/score.

### 5.4. Environmental Obstacles & Capture Zones
1. **`steel_bunker.tscn` (`StaticBody2D`):** Layer $3$, Group `"bouncy_surface"`, indestructible.
2. **`sandbag_barricade.tscn` (`StaticBody2D`):** Layer $3$, Group `"destructible_cover"`, $\text{HP} = 3$, does not bounce bullets.
3. **`mud_crater.tscn` (`Area2D`):** Layer $6$, Mask $1, 2$, `z_index = -1`, sets `speed_multiplier = 0.65` inside.
4. **`capture_zone.tscn` (`Area2D`):** Layer $6$, Mask $1, 2$, `z_index = -1`, Group `"capture_zone"`, `CircleShape2D` radius `180.0 px`.
   * Tracks bodies entering/exiting (`"player"` vs `"enemy"`).
   * States: `NEUTRAL`, `CAPTURING`, `CONTESTED`, `CAPTURED`.
   * When `"player"` is inside and enemy count inside is `0`, `progress` increases by `0.15 * delta` (`15%/s`). If enemies are inside while `progress < 1.0`, state switches to `CONTESTED` and progress pauses.
   * At `progress >= 1.0`, locks as `CAPTURED`, heals player `+1 HP`, awards `+500` score + floating text, and emits `EventBus.capture_zone_captured`.

---

## 6. Arena Layout, Map Expansion & Wave Director

### 6.1. Arena & Expansion Structure (`arena.tscn` & `arena_controller.gd`)
* **Inner Sector Bounds:** `Rect2(0, 0, 1280, 720)` surrounded by `SteelBunker`, `SandbagBarricade`, `MudCrater`, and destructible/openable **Expansion Barriers** along the outer edges of the initial `1280x720` box.
* **Expanded Sector Bounds:** `Rect2(-640, -360, 2560, 1440)` enclosed by outer perimeter walls (Layer $3$, `"bouncy_surface"`) with outer spawn gates.
* **Expansion Transition (`_on_boss_defeated`):**
  1. Removes/explodes the inner `ExpansionBarriers` so the player can drive freely into the `2560x1440` outer sector.
  2. Spawns `3` `CaptureZone` nodes at designated outer sector coordinates along with `EnemyPillbox` defenders and initial patrol enemies.
  3. Emits `EventBus.map_expanded.emit(EXPANDED_BOUNDS)` and transitions `GameManager` to `Phase.INVASION`.
* **Sector Loop (`_on_capture_zone_captured`):**
  * When `zones_captured >= zones_total`, emits `EventBus.sector_cleared`, awards `1000` bonus points, increments `sector_index += 1`, clears completed zone nodes, and starts the next sector escalation cycle.

### 6.2. Dynamic Camera (`camera_shake.gd`)
* Remains centered at `(640, 360)` with `1280x720` limits during `SKIRMISH` and `BOSS`.
* Upon receiving `EventBus.map_expanded(new_bounds)`, updates `limit_left`, `limit_right`, `limit_top`, `limit_bottom` to `new_bounds` and smoothly tracks the `Player` position while preserving `camera_shake_requested` offsets.

### 6.3. Phase-Aware Wave Director (`wave_director.gd`)
* Spawn interval formula:
  $$T_{\text{spawn}} = \max\left(0.65, 3.0 - 0.15 \times \lfloor \frac{t}{15.0} \rfloor - 0.1 \times (\text{sector} - 1)\right)$$
* Spawns `BossGoliath` when `GameManager.current_phase` transitions to `Phase.BOSS`.
* Adjusts spawn cadence during `BOSS` (slower support spawns) and `INVASION` (spawns patrols near active outer gates) so combat pressure remains balanced across all 3 phases.