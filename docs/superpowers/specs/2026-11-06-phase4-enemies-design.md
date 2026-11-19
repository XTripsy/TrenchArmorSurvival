# Phase 4 — Enemies Design (T-016..T-020)

Status: approved for implementation.
Scope: `base_enemy.gd`, `enemy_scout.tscn` + `enemy_scout.gd`, `enemy_artillery.tscn` + `enemy_artillery.gd`, `enemy_dreadnought.tscn` + `enemy_dreadnought.gd`.

## Intent

Implement the base enemy system and the 3 distinct enemy types specified in GDD and TAD:
1. Scout: fast chaser that deals collision damage on contact.
2. Artillery: stops at 350px distance and fires bullets every 2.5s.
3. Dreadnought: heavy tank with 2 HP, firing every 3.5s, killed instantly by 1 ricochet shot.
All enemies handle mud slowdown through `speed_multiplier` applied to their effective speed.

## Goals

- `scripts/enemies/base_enemy.gd`: Common class `BaseEnemy` (`CharacterBody2D`, layer 2, mask 1,2,3,4,6).
  - `@export var max_hp: int = 1`
  - `@export var move_speed: float = 150.0`
  - `@export var base_score: int = 100`
  - `var hp: int`
  - `var speed_multiplier: float = 1.0`
  - `take_damage(amount: int, from_ricochet: bool) -> void`
  - `die(from_ricochet: bool) -> void`
  - `get_player() -> PlayerTank`
- `enemy_scout.tscn` + `enemy_scout.gd` (class `EnemyScout` extends `BaseEnemy`):
  - HP 1, speed 250, score 100.
  - Chases player. On `move_and_slide()` collision with `PlayerTank` (or `body_entered` / collision check): call `player.take_damage(1)` then `die(false)`.
  - Visual: dull-brown light car (`#8B5A2B` / `#6B4226`) with spiked bumper polygon, size ~32×24.
- `enemy_artillery.tscn` + `enemy_artillery.gd` (class `EnemyArtillery` extends `BaseEnemy`):
  - HP 1, speed 110, score 200.
  - Distance > 350px to player: move toward player. Distance ≤ 350px: stop (`velocity = Vector2.ZERO`), rotate barrel/body toward player.
  - Timer 2.5s fire interval. Spawns `enemy_bullet.tscn` with speed 400.
  - Visual: dark gray (`#36393F`) hull + long barrel ~40×24.
- `enemy_dreadnought.tscn` + `enemy_dreadnought.gd` (class `EnemyDreadnought` extends `BaseEnemy`):
  - HP 2, speed 70, score 500.
  - Timer 3.5s fire interval. Spawns `enemy_bullet.tscn` with speed 350.
  - Overrides `take_damage(amount, from_ricochet)`: if `from_ricochet` is true, passes `max_hp` to `super.take_damage(max_hp, true)`.
  - Visual: large dark red/gray (`#8B3A3A`) Mark V tank ~48×36.
- Speed calculation across all enemies: `effective_speed = move_speed * speed_multiplier`.

## Contracts

### `base_enemy.gd`
```gdscript
class_name BaseEnemy
extends CharacterBody2D

@export var max_hp: int = 1
@export var move_speed: float = 150.0
@export var base_score: int = 100

var hp: int = 1
var speed_multiplier: float = 1.0
var _alive: bool = true

func _ready() -> void:
	hp = max_hp

func take_damage(amount: int, from_ricochet: bool = false) -> void:
	if not _alive:
		return
	hp = maxi(0, hp - amount)
	_flash_white()
	if hp <= 0:
		die(from_ricochet)

func die(from_ricochet: bool = false) -> void:
	if not _alive:
		return
	_alive = false
	EventBus.enemy_destroyed.emit(global_position, base_score, from_ricochet)
	queue_free()

func get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _flash_white() -> void:
	modulate = Color(10.0, 10.0, 10.0, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
```

### `enemy_scout.gd`
```gdscript
class_name EnemyScout
extends BaseEnemy

func _ready() -> void:
	max_hp = 1
	move_speed = 250.0
	base_score = 100
	super._ready()

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	var player: Node2D = get_player()
	if player != null:
		var dir: Vector2 = (player.global_position - global_position).normalized()
		velocity = dir * move_speed * speed_multiplier
		rotation = dir.angle()
		move_and_slide()
		_check_player_collision()

func _check_player_collision() -> void:
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider != null and collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.call("take_damage", 1, false)
			die(false)
			return
```

### `enemy_artillery.gd`
```gdscript
class_name EnemyArtillery
extends BaseEnemy

const FIRE_INTERVAL: float = 2.5
const BULLET_SPEED: float = 400.0
const STOP_DISTANCE: float = 350.0
const BULLET_SCENE: String = "res://scenes/projectiles/enemy_bullet.tscn"

@onready var fire_timer: Timer = $FireTimer
@onready var muzzle_marker: Marker2D = $MuzzleMarker

func _ready() -> void:
	max_hp = 1
	move_speed = 110.0
	base_score = 200
	super._ready()
	fire_timer.wait_time = FIRE_INTERVAL
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	fire_timer.start()

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	var player: Node2D = get_player()
	if player != null:
		var dist: float = global_position.distance_to(player.global_position)
		var dir: Vector2 = (player.global_position - global_position).normalized()
		rotation = dir.angle()
		if dist > STOP_DISTANCE:
			velocity = dir * move_speed * speed_multiplier
			move_and_slide()
		else:
			velocity = Vector2.ZERO

func _on_fire_timer_timeout() -> void:
	if not _alive:
		return
	var player: Node2D = get_player()
	if player == null:
		return
	_fire(player)

func _fire(player: Node2D) -> void:
	if not ResourceLoader.exists(BULLET_SCENE):
		return
	var packed: PackedScene = load(BULLET_SCENE) as PackedScene
	if packed == null:
		return
	var bullet: Node2D = packed.instantiate() as Node2D
	if bullet == null:
		return
	var dir: Vector2 = (player.global_position - global_position).normalized()
	if bullet.get("direction") != null:
		bullet.set("direction", dir)
	if bullet.get("speed") != null:
		bullet.set("speed", BULLET_SPEED)
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(bullet)
	bullet.global_position = muzzle_marker.global_position if muzzle_marker != null else global_position
	bullet.rotation = dir.angle()
```

### `enemy_dreadnought.gd`
```gdscript
class_name EnemyDreadnought
extends BaseEnemy

const FIRE_INTERVAL: float = 3.5
const BULLET_SPEED: float = 350.0
const BULLET_SCENE: String = "res://scenes/projectiles/enemy_bullet.tscn"

@onready var fire_timer: Timer = $FireTimer
@onready var muzzle_marker: Marker2D = $MuzzleMarker

func _ready() -> void:
	max_hp = 2
	move_speed = 70.0
	base_score = 500
	super._ready()
	fire_timer.wait_time = FIRE_INTERVAL
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	fire_timer.start()

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	var player: Node2D = get_player()
	if player != null:
		var dir: Vector2 = (player.global_position - global_position).normalized()
		velocity = dir * move_speed * speed_multiplier
		rotation = dir.angle()
		move_and_slide()

func take_damage(amount: int, from_ricochet: bool = false) -> void:
	if from_ricochet:
		super.take_damage(max_hp, true)
	else:
		super.take_damage(amount, false)

func _on_fire_timer_timeout() -> void:
	if not _alive:
		return
	var player: Node2D = get_player()
	if player == null:
		return
	_fire(player)

func _fire(player: Node2D) -> void:
	if not ResourceLoader.exists(BULLET_SCENE):
		return
	var packed: PackedScene = load(BULLET_SCENE) as PackedScene
	if packed == null:
		return
	var bullet: Node2D = packed.instantiate() as Node2D
	if bullet == null:
		return
	var dir: Vector2 = (player.global_position - global_position).normalized()
	if bullet.get("direction") != null:
		bullet.set("direction", dir)
	if bullet.get("speed") != null:
		bullet.set("speed", BULLET_SPEED)
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(bullet)
	bullet.global_position = muzzle_marker.global_position if muzzle_marker != null else global_position
	bullet.rotation = dir.angle()
```

## Scene Specs

1. `enemy_scout.tscn`:
   - Root `EnemyScout` (`CharacterBody2D`, layer 2, mask 1,2,3,4,6, `motion_mode = FLOATING`, script `enemy_scout.gd`).
   - `CollisionShape2D` → `CircleShape2D` radius 14.
   - `Visual` (`Polygon2D`) color `#8B5A2B` (dull-brown), vehicle shape ~32×24 with spiked front.

2. `enemy_artillery.tscn`:
   - Root `EnemyArtillery` (`CharacterBody2D`, layer 2, mask 1,2,3,4,6, `motion_mode = FLOATING`, script `enemy_artillery.gd`).
   - `CollisionShape2D` → `RectangleShape2D` 36×24.
   - `Visual` (`Polygon2D`) color `#36393F` (dark gray), tank hull + long barrel ~40×24.
   - `MuzzleMarker` (`Marker2D`) at tip of barrel (24, 0).
   - `FireTimer` (`Timer`, autostart false, one_shot false).

3. `enemy_dreadnought.tscn`:
   - Root `EnemyDreadnought` (`CharacterBody2D`, layer 2, mask 1,2,3,4,6, `motion_mode = FLOATING`, script `enemy_dreadnought.gd`).
   - `CollisionShape2D` → `RectangleShape2D` 44×32.
   - `Visual` (`Polygon2D`) color `#8B3A3A` (dark red), heavy tank shape ~48×36.
   - `MuzzleMarker` (`Marker2D`) at tip of barrel (26, 0).
   - `FireTimer` (`Timer`, autostart false, one_shot false).

## Verification Strategy

Create temporary harness scene `tests/phase4_check.tscn` + `tests/phase4_check.gd` to verify:
1. `BaseEnemy` damage, hit flash, death signal (`enemy_destroyed`).
2. `EnemyScout` movement speed 250, collision damage with player, death on impact.
3. `EnemyArtillery` stopping at <= 350px, firing enemy bullet at 400 speed every 2.5s.
4. `EnemyDreadnought` 2 HP for direct shot (1 HP takes hit flash but stays alive, 2nd hit dies), but 1 ricochet shot instantly kills it.
5. Mud slowdown: setting `speed_multiplier = 0.65` reduces effective velocity by 35%.
6. Clean up temporary test harness after verification.
