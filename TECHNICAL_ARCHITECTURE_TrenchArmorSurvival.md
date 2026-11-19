# Technical Architecture Document (TAD): Trench Armor Survival

## 1. Engine Standards & Project Configuration

### 1.1. Core Specifications
* **Engine Target:** Godot Engine 4.2+ (fully compatible with Godot 4.x).
* **Scripting Language:** GDScript 2.0 with **Strict Static Typing** required on every line of code (e.g. `var move_speed: float = 220.0`, `func apply_damage(amount: int, is_ricochet: bool) -> void:`).
* **Rendering Method:** `Forward+` or `Compatibility` (2D Orthographic).
* **Zero-Asset Dependency (Procedural Fallback):** All primary visual objects must be built using `Polygon2D`, `Line2D`, and `CPUParticles2D`, with Hex color codes matching the GDD. The game must be fully playable through code before any external image assets are added.

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
│   ├── game_manager.gd       # State Machine, Score, Timer, & Hit-Stop Logic
│   ├── vfx_manager.gd        # Particle, Debris, Scorch Mark, & Floating Text Spawner
│   └── audio_manager.gd      # Procedural/Polyphonic SFX & BGM Controller
├── scenes/
│   ├── main_menu.tscn        # Title Screen & Blueprint UI
│   ├── arena.tscn            # Main Gameplay Level (Fixed Camera 1280x720)
│   ├── player/
│   │   ├── player.tscn       # Player Tank
│   │   └── tread_mark.tscn   # Tank Track Marks (Line2D)
│   ├── projectiles/
│   │   ├── player_bullet.tscn
│   │   └── enemy_bullet.tscn
│   ├── enemies/
│   │   ├── enemy_scout.tscn
│   │   ├── enemy_artillery.tscn
│   │   └── enemy_dreadnought.tscn
│   ├── environment/
│   │   ├── steel_bunker.tscn
│   │   ├── sandbag_barricade.tscn
│   │   └── mud_crater.tscn
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
    │   ├── base_enemy.gd     # Parent class for all enemies
    │   ├── enemy_scout.gd
    │   ├── enemy_artillery.gd
    │   └── enemy_dreadnought.gd
    ├── environment/
    │   ├── sandbag_barricade.gd
    │   └── mud_crater.gd
    └── ui/
        ├── main_menu.gd
        ├── hud.gd
        ├── pause_menu.gd
        ├── game_over_menu.gd
        └── floating_text.gd
```

---

## 3. Physics & Collision Matrix

The collision detection system uses 6 Physics Layers and Node Groups to distinguish bouncing surfaces from non-bouncing surfaces.

### 3.1. Collision Layers Table

| Bit / Layer | Layer Name | Objects on This Layer | Collision Mask (Detects Layers) |
| :--- | :--- | :--- | :--- |
| **Layer 1** | `Player` | `Player` (`CharacterBody2D`) | $2, 3, 5, 6$ |
| **Layer 2** | `Enemy` | `EnemyScout`, `EnemyArtillery`, `EnemyDreadnought` | $1, 2, 3, 4, 6$ |
| **Layer 3** | `Environment` | Perimeter Walls, `SteelBunker`, `SandbagBarricade` | No mask required (Static) |
| **Layer 4** | `PlayerBullet` | `PlayerBullet` (`CharacterBody2D`) | $2, 3$ *(Ignore Layer 1 = No Self-Damage)* |
| **Layer 5** | `EnemyBullet` | `EnemyBullet` (`Area2D` / `CharacterBody2D`) | $1, 3$ |
| **Layer 6** | `TerrainHazard` | `MudCrater` (`Area2D`) | $1, 2$ |

### 3.2. Node Groups (Surface & Entity Tagging)
* `"player"`: Assigned to the `Player` root node so enemy AI can quickly find its target using `get_tree().get_first_node_in_group("player")`.
* `"bouncy_surface"`: Assigned to Perimeter Walls and `SteelBunker`. Player bullets only bounce when the collided object belongs to this group.
* `"destructible_cover"`: Assigned to `SandbagBarricade`. It absorbs bullets without bouncing them and loses HP when hit.

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
```

### 4.2. `GameManager.gd` (State & Time Controller)
* **Game States Enum:** `enum State { MENU, PLAYING, PAUSED, GAME_OVER }`
* **Tracked Metrics:**
  * `score: int = 0`
  * `time_survived: float = 0.0`
  * `ricochet_kills: int = 0`
* **Score Calculation Logic:**
  When receiving the `enemy_destroyed(pos, base_score, was_ricochet)` signal:
  * If `was_ricochet == true`, award $\text{base\_score} \times 2$ points, increment `ricochet_kills += 1`, and call `VFXManager.spawn_floating_text(pos, "+%d RICOCHET!" % (base_score * 2))`.
  * If `false`, award the normal $\text{base\_score}$ value.
* **Hit-Stop / Freeze-Frame System:**
  Implement `trigger_hit_stop(duration: float = 0.05) -> void:` to set `Engine.time_scale = 0.05`, then restore it to $1.0$ using `get_tree().create_timer(duration, true, false, true).timeout`.

### 4.3. `VFXManager.gd` (Procedural Juice Generator)
Responsible for creating visual effects in the arena without adding effect logic to entity scripts:
* `spawn_muzzle_flash(pos: Vector2, rot: float) -> void`: Creates a yellow-white polygon flash for $0.08\text{ s}$ and a puff of gray smoke particles.
* `spawn_ricochet_sparks(pos: Vector2, normal: Vector2) -> void`: Emits yellow (`#FFD700`) line-shaped `CPUParticles2D` in the reflection direction.
* `spawn_tank_explosion(pos: Vector2) -> void`:
  1. Places a transparent black polygon scorch mark on the lower ground layer.
  2. Emits orange (`#FF5500`) fireball particles and black smoke.
  3. Creates $3\text{ to }5$ rigid/tweened debris fragments (armor plates) that are launched in random directions and stop after $0.4\text{ s}$.
* `spawn_floating_text(pos: Vector2, text: String) -> void`: Instantiates `floating_text.tscn`, which moves upward by $30\text{ px}$ and fades out (`modulate.a = 0`) over $0.8\text{ s}$ using a `Tween`.

### 4.4. `AudioManager.gd` (Procedural / Pool Audio)
Manages a pool of `AudioStreamPlayer` and `AudioStreamPlayer2D` nodes. If `.wav/.ogg` audio files are not yet available in the `assets/` folder, `AudioManager` must use `AudioStreamGenerator` (simple procedural waveform synthesis: white-noise bursts for explosions/cannon fire, high-pitched sine-wave sweeps for ricochet pings) so the game does not produce errors and still provides audio feedback.

---

## 5. Entity Specifications & Node Hierarchies

### 5.1. Player Tank (`res://scenes/player/player.tscn`)
* **Root Node:** `Player` (`CharacterBody2D`) — Group: `"player"`, Layer: $1$, Mask: $2, 3, 5, 6$.
* **Child Nodes:**
  * `CollisionShape2D` (`RectangleShape2D`, size $36 \times 36\text{ px}$).
  * `HullVisual` (`Node2D` containing an Olive Drab `#556B2F` `Polygon2D` and track-line details).
  * `TurretPivot` (`Node2D` for independent rotation toward the cursor).
    * `TurretVisual` (`Polygon2D` for the cannon assembly and white star). Moves backward/forward using a `Tween` during recoil.
    * `MuzzleMarker` (`Marker2D` at the barrel tip, used as the bullet spawn point).
  * `TreadTimer` (`Timer` with a $0.05\text{ s}$ interval for placing track-mark points).
* **Key Variables & Logic (`player.gd`):**
  * `const MAX_HP: int = 3`, `const BASE_SPEED: float = 220.0`, `const TURN_SPEED: float = 10.0`, `const FIRE_COOLDOWN: float = 0.45`, `const RECOIL_FORCE: float = 40.0`, `const IFRAME_DURATION: float = 1.2`.
  * `var speed_multiplier: float = 1.0` (changed to $0.65$ by `MudCrater`).
  * **Movement & Hull Rotation:** Read the `Input.get_vector()` vector. While moving, interpolate the angle using `HullVisual.rotation = lerp_angle(HullVisual.rotation, velocity.angle(), TURN_SPEED * delta)`.
  * **Turret Aim:** `TurretPivot.look_at(get_global_mouse_position())`.
  * **Shooting & Recoil:** When firing, apply `velocity -= aim_direction * RECOIL_FORCE * 5.0`, run a backward recoil `Tween` on `TurretVisual.position.x`, and emit `EventBus.camera_shake_requested.emit(2.0, 0.1)`.
  * **Damage & I-Frames:** When damaged, reduce HP, set `is_invulnerable = true` for $1.2\text{ s}$ (make the visual blink using a `Tween` on `modulate.a`), call `GameManager.trigger_hit_stop(0.05)`, and emit `EventBus.camera_shake_requested.emit(12.0, 0.35)`.

### 5.2. Player Bullet (`res://scenes/projectiles/player_bullet.tscn`)
* **Root Node:** `PlayerBullet` (`CharacterBody2D`) — Layer: $4$, Mask: $2, 3$.
* **Key Variables (`player_bullet.gd`):**
  * `const SPEED: float = 650.0`
  * `const MAX_BOUNCES: int = 1`
  * `var bounce_count: int = 0`
  * `var is_ricochet: bool = false`
* **Physics Step (`_physics_process`):**
  ```gdscript
  var collision: KinematicCollision2D = move_and_collide(velocity * delta)
  if collision:
      var collider: Object = collision.get_collider()
      if collider.has_method("take_damage"):
          collider.take_damage(1, is_ricochet)
          queue_free()
      elif collider.is_in_group("bouncy_surface"):
          if bounce_count < MAX_BOUNCES:
              bounce_count += 1
              is_ricochet = true
              velocity = velocity.bounce(collision.get_normal())
              rotation = velocity.angle()
              _apply_ricochet_visuals() # Change color to #FF5500
              EventBus.bullet_ricocheted.emit(collision.get_position(), collision.get_normal())
          else:
              VFXManager.spawn_ricochet_sparks(collision.get_position(), collision.get_normal())
              queue_free()
      else:
          queue_free()
  ```

### 5.3. Enemy Architecture (`BaseEnemy` & Subclasses)
All enemies inherit from `scripts/enemies/base_enemy.gd` (`CharacterBody2D`, Layer: $2$, Mask: $1, 2, 3, 4, 6$).
* **`BaseEnemy` Properties:**
  * `@export var max_hp: int = 1`
  * `@export var move_speed: float = 150.0`
  * `@export var base_score: int = 100`
  * `var speed_multiplier: float = 1.0`
  * Method `take_damage(amount: int, from_ricochet: bool) -> void`: Reduces HP, triggers a white Hit Flash (`modulate = Color(10, 10, 10, 1)` for $0.1\text{ s}$), and calls `die(from_ricochet)` when $\text{HP} \le 0$.
* **Subclasses:**
  1. **`enemy_scout.gd` (Scout Rammer):** $\text{HP} = 1$, $\text{Speed} = 250.0$, $\text{Score} = 100$. Directly pursues the player's position. On contact with `Player` (detected through `move_and_slide` slide collisions or an `Area2D` hurtbox), deals $1\text{ damage}$ to the player and calls `die(false)`.
  2. **`enemy_artillery.gd` (Light Artillery):** $\text{HP} = 1$, $\text{Speed} = 110.0$, $\text{Score} = 200$. Calculates `global_position.distance_to(player.global_position)`. If the distance is $> 350.0\text{ px}$, moves forward; if it is $\le 350.0\text{ px}$, sets `velocity = Vector2.ZERO`. Fires `enemy_bullet.tscn` (speed $400\text{ px/s}$, no ricochet) every $2.5\text{ s}$.
  3. **`enemy_dreadnought.gd` (Heavy Dreadnought):** $\text{HP} = 2$, $\text{Speed} = 70.0$, $\text{Score} = 500$, fires every $3.5\text{ s}$ (bullet speed $350\text{ px/s}$). Overrides `take_damage`:
     ```gdscript
     func take_damage(amount: int, from_ricochet: bool) -> void:
         if from_ricochet:
             super.take_damage(max_hp, true) # Instant kill from a ricochet bullet!
         else:
             super.take_damage(amount, false)
     ```

### 5.4. Environmental Obstacles
1. **`steel_bunker.tscn` (`StaticBody2D`):** Layer $3$, Group `"bouncy_surface"`. An angled metallic-gray steel polygon with rivet details. Indestructible.
2. **`sandbag_barricade.tscn` (`StaticBody2D`):** Layer $3$, Group `"destructible_cover"`. Has `take_damage(amount: int, _is_ricochet: bool)`. Has $\text{HP} = 3$. Each hit from either player or enemy bullets causes a white flash and slight shrinking/cracking. Destroyed when $\text{HP} \le 0$.
3. **`mud_crater.tscn` (`Area2D`):** Layer $6$, Mask $1, 2$, `z_index = -1`. Connects `body_entered` and `body_exited` signals. When a tank enters, set `body.speed_multiplier = 0.65`; when it exits, restore `body.speed_multiplier = 1.0`.

---

## 6. Arena Layout & Wave Director Algorithm

### 6.1. Arena Structure (`res://scenes/arena.tscn`)
* Contains a `Camera2D` at the center $(640, 360)$ with the `camera_shake.gd` script, which listens to the `EventBus.camera_shake_requested` signal.
* Outer boundary walls (`PerimeterWalls`) are placed along all four screen edges, with $4$ spawn-gate openings ($80\text{ px}$ wide) at the center of the Top, Bottom, Left, and Right sides. Each gate has an off-screen `Marker2D` used as an enemy spawn point.
* Place $4$ `SteelBunker` units symmetrically at a $45^\circ$ angle in the four arena quadrants (as ricochet mirrors), $3$ `SandbagBarricade` units near the center, and $3$ `MudCrater` units.

### 6.2. Time-Based Wave Director (`wave_director.gd`)
Controls the `SpawnTimer` interval and enemy-type probabilities based on survival time $t$ (in seconds):
* **Spawn Interval Calculation:**
  $$T_{\text{spawn}} = \max\left(0.8, 3.0 - 0.15 \times \lfloor \frac{t}{15.0} \rfloor\right)$$
* **Spawn Probability Table (Weighted Random Roll $0.0\text{–}1.0$):**
  * If $t < 45.0$: $100\%$ `EnemyScout`.
  * If $45.0 \le t < 90.0$: Roll $< 0.70 \rightarrow$ `EnemyScout`, remaining ($30\%$) $\rightarrow$ `EnemyArtillery`.
  * If $t \ge 90.0$: Roll $< 0.50 \rightarrow$ `EnemyScout`, Roll $< 0.85$ ($35\%$) $\rightarrow$ `EnemyArtillery`, remaining ($15\%$) $\rightarrow$ `EnemyDreadnought`.
