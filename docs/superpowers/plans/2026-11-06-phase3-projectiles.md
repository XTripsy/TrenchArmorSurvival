# Projectiles (Phase 3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membangun peluru pemain (T-014) dan peluru musuh (T-015): pantulan sekali, warna ricochet, damage, dan cleanup.

**Architecture:** Dua scene `CharacterBody2D` mandiri dengan `move_and_collide` per physics step (TAD §5.2). `player.gd` sudah mengisi `direction` sebelum `add_child`; peluru menghitung `velocity` di `_ready()`. Penembak musuh (Phase 4) mengisi `direction` + `speed` sebelum `add_child`.

**Tech Stack:** Godot 4.7.2.stable.steam, GDScript 2.0 static typing, zero asset.

**Spec:** `docs/superpowers/specs/2026-11-06-phase3-projectiles-design.md`

## Global Constraints

- Static typing eksplisit pada setiap `var`, parameter, dan return type.
- Zero asset: hanya `Polygon2D`, `CircleShape2D`, `CollisionShape2D`.
- Komunikasi lintas sistem hanya lewat `EventBus` atau API autoload Phase 1.
- Tidak ada file di luar §2 + `docs/`; harness `tests/` sementara dan dihapus di Task 2.
- Folder ini bukan git repo → tidak ada commit; ledger menggantikan commit.
- `player_bullet.tscn` **boleh dibuat sekarang** (T-014); jangan menyentuh `player.gd`
  kecuali tes menemukan bug kontrak.
- Z-order peluru = 20 (kontrak T-038).
- Headless memakai audio driver dummy; `play_ricochet()` tidak menghasilkan suara nyata.

## Review Focus

1. Peluru pemain menembus player (layer 1 tidak ada di mask 6) → HP player tidak berubah.
2. Pantulan sukses tidak memicu sparks dua kali: `bullet_ricocheted` sudah di-subscribe
   `VFXManager`; jangan panggil `spawn_ricochet_sparks` pada cabang bounce.
3. Impact kedua menghancurkan peluru, bukan memantul lagi; sinyal tidak ter-emit lagi.
4. Peluru musuh tidak pernah memantul: dinding langsung menghancurkannya.
5. Collider tanpa `take_damage` (dinding) tidak memicu error `call()`.
6. Peluru yang spawn jauh di luar layar langsung dibersihkan.

---

### Task 1: `player_bullet.tscn` + `player_bullet.gd` (T-014)

**Files:**
- Create: `scripts/projectiles/player_bullet.gd`
- Create: `scenes/projectiles/player_bullet.tscn`
- Create: `tests/phase3_check.gd`
- Create: `tests/phase3_check.tscn`

**Interfaces:**
- Produces: `class_name PlayerBullet extends CharacterBody2D`; `const SPEED: float = 650.0`,
  `const MAX_BOUNCES: int = 1`, `const OFFSCREEN_MARGIN: float = 256.0`,
  `const RICOCHET_COLOR: Color`; `var direction: Vector2`, `var bounce_count: int`,
  `var is_ricochet: bool`; `@onready var visual: Polygon2D`.
- Consumes: `EventBus.bullet_ricocheted(pos, normal)`, `VFXManager.spawn_ricochet_sparks(pos, normal)`,
  `AudioManager.play_ricochet()`, `collider.call("take_damage", 1, is_ricochet)`.

- [ ] **Step 1: Tulis stub `PlayerBullet`**

`scripts/projectiles/player_bullet.gd`:
```gdscript
class_name PlayerBullet
extends CharacterBody2D

const SPEED: float = 650.0
const MAX_BOUNCES: int = 1
const OFFSCREEN_MARGIN: float = 256.0
const RICOCHET_COLOR: Color = Color("#FF5500")

var direction: Vector2 = Vector2.RIGHT
var bounce_count: int = 0
var is_ricochet: bool = false

@onready var visual: Polygon2D = $Visual
```

Jalankan `--headless --editor --quit` sekali agar `class_name PlayerBullet` terdaftar
sebelum harness memakainya sebagai tipe.

- [ ] **Step 2: Tulis harness player bullet**

`tests/phase3_check.tscn`:
```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tests/phase3_check.gd" id="1_check"]

[node name="Phase3Check" type="Node"]
script = ExtResource("1_check")
```

`tests/phase3_check.gd`:
```gdscript
extends Node

const PLAYER_BULLET: String = "res://scenes/projectiles/player_bullet.tscn"
const PLAYER_SCENE: String = "res://scenes/player/player.tscn"

var failures: PackedStringArray = PackedStringArray()

class FakeTarget:
	extends StaticBody2D
	var damage_events: Array[Vector2i] = []
	func take_damage(amount: int, from_ricochet: bool) -> void:
		damage_events.append(Vector2i(amount, 1 if from_ricochet else 0))

func _ready() -> void:
	await get_tree().process_frame
	await _run_checks()
	if failures.is_empty():
		print("PASS")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			printerr("FAIL: " + failure)
		get_tree().quit(1)

func _run_checks() -> void:
	await _check_player_bullet_contract()
	await _check_player_bullet_bounce()
	await _check_player_bullet_second_impact()
	await _check_player_bullet_damage()
	await _check_player_bullet_ricochet_damage()
	await _check_player_bullet_ignores_player()
	await _check_player_bullet_offscreen()

func _fail(message: String) -> void:
	failures.append(message)

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func _wait_physics(frames: int) -> void:
	for i: int in frames:
		await get_tree().physics_frame

func _make_wall(pos: Vector2, size: Vector2, bouncy: bool) -> StaticBody2D:
	var wall: StaticBody2D = StaticBody2D.new()
	wall.collision_layer = 4
	wall.collision_mask = 0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	wall.add_child(shape)
	add_child(wall)
	wall.global_position = pos
	if bouncy:
		wall.add_to_group("bouncy_surface")
	return wall

func _make_target(pos: Vector2, layer: int) -> FakeTarget:
	var target: FakeTarget = FakeTarget.new()
	target.collision_layer = layer
	target.collision_mask = 0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(36.0, 36.0)
	shape.shape = rect
	target.add_child(shape)
	add_child(target)
	target.global_position = pos
	return target

func _spawn_player_bullet(pos: Vector2, dir: Vector2) -> PlayerBullet:
	if not ResourceLoader.exists(PLAYER_BULLET):
		_fail("player_bullet.tscn belum ada")
		return null
	var packed: PackedScene = load(PLAYER_BULLET) as PackedScene
	var bullet: PlayerBullet = packed.instantiate() as PlayerBullet
	bullet.direction = dir
	add_child(bullet)
	bullet.global_position = pos
	return bullet

func _count_sparks(node: Node) -> int:
	var count: int = 0
	for child: Node in node.get_children():
		if child is CPUParticles2D and (child as CPUParticles2D).one_shot:
			count += 1
		count += _count_sparks(child)
	return count

func _check_player_bullet_contract() -> void:
	var bullet: PlayerBullet = _spawn_player_bullet(Vector2(200.0, 600.0), Vector2.DOWN)
	if bullet == null:
		return
	await get_tree().physics_frame
	if absf(bullet.velocity.length() - 650.0) > 1.0:
		_fail("player bullet speed harus 650, dapat %f" % bullet.velocity.length())
	if absf(angle_difference(bullet.rotation, Vector2.DOWN.angle())) > 0.01:
		_fail("rotasi player bullet harus mengikuti arah")
	if bullet.collision_layer != 8:
		_fail("player bullet layer harus 8, dapat %d" % bullet.collision_layer)
	if bullet.collision_mask != 6:
		_fail("player bullet mask harus 6 (layer 2+3), dapat %d" % bullet.collision_mask)
	bullet.queue_free()
	await get_tree().process_frame

func _check_player_bullet_bounce() -> void:
	var wall: StaticBody2D = _make_wall(Vector2(300.0, 100.0), Vector2(20.0, 200.0), true)
	var bounces: Array[bool] = []
	var on_bounce: Callable = func(_pos: Vector2, _normal: Vector2) -> void:
		bounces.append(true)
	EventBus.bullet_ricocheted.connect(on_bounce)
	var bullet: PlayerBullet = _spawn_player_bullet(Vector2(200.0, 100.0), Vector2.RIGHT)
	if bullet == null:
		EventBus.bullet_ricocheted.disconnect(on_bounce)
		wall.queue_free()
		return
	await _wait_physics(12)
	if _count_sparks(self) != 1:
		_fail("pantulan harus memunculkan tepat satu efek sparks (tidak dobel)")
	await _wait_physics(18)
	if bullet.bounce_count != 1:
		_fail("bounce_count harus 1, dapat %d" % bullet.bounce_count)
	if not bullet.is_ricochet:
		_fail("is_ricochet harus true setelah pantulan")
	if bullet.velocity.x >= 0.0:
		_fail("velocity harus berbalik ke kiri setelah pantulan")
	if not bullet.visual.color.is_equal_approx(PlayerBullet.RICOCHET_COLOR):
		_fail("warna bullet setelah pantulan harus #FF5500")
	if bounces.size() != 1:
		_fail("bullet_ricocheted harus ter-emit sekali, dapat %d" % bounces.size())
	EventBus.bullet_ricocheted.disconnect(on_bounce)
	bullet.queue_free()
	wall.queue_free()
	await get_tree().process_frame

func _check_player_bullet_second_impact() -> void:
	var right_wall: StaticBody2D = _make_wall(Vector2(300.0, 300.0), Vector2(20.0, 200.0), true)
	var left_wall: StaticBody2D = _make_wall(Vector2(100.0, 300.0), Vector2(20.0, 200.0), true)
	var bullet: PlayerBullet = _spawn_player_bullet(Vector2(200.0, 300.0), Vector2.RIGHT)
	if bullet == null:
		right_wall.queue_free()
		left_wall.queue_free()
		return
	await _wait_physics(60)
	if is_instance_valid(bullet):
		_fail("player bullet harus hancur pada impact kedua")
		bullet.queue_free()
	right_wall.queue_free()
	left_wall.queue_free()
	await get_tree().process_frame

func _check_player_bullet_damage() -> void:
	var target: FakeTarget = _make_target(Vector2(300.0, 500.0), 2)
	var bullet: PlayerBullet = _spawn_player_bullet(Vector2(200.0, 500.0), Vector2.RIGHT)
	if bullet == null:
		target.queue_free()
		return
	await _wait_physics(30)
	if target.damage_events.size() != 1 or target.damage_events[0] != Vector2i(1, 0):
		_fail("musuh harus menerima take_damage(1, false), dapat %s" % str(target.damage_events))
	if is_instance_valid(bullet):
		_fail("player bullet harus hilang setelah mengenai musuh")
	target.queue_free()
	await get_tree().process_frame

func _check_player_bullet_ricochet_damage() -> void:
	var wall: StaticBody2D = _make_wall(Vector2(300.0, 200.0), Vector2(20.0, 200.0), true)
	var target: FakeTarget = _make_target(Vector2(150.0, 200.0), 2)
	var bullet: PlayerBullet = _spawn_player_bullet(Vector2(200.0, 200.0), Vector2.RIGHT)
	if bullet == null:
		target.queue_free()
		wall.queue_free()
		return
	await _wait_physics(60)
	if target.damage_events.size() != 1 or target.damage_events[0] != Vector2i(1, 1):
		_fail("musuh setelah pantulan harus menerima take_damage(1, true), dapat %s" % str(target.damage_events))
	if is_instance_valid(bullet):
		_fail("player bullet ricochet harus hilang setelah mengenai musuh")
	target.queue_free()
	wall.queue_free()
	await get_tree().process_frame

func _check_player_bullet_ignores_player() -> void:
	var packed: PackedScene = load(PLAYER_SCENE) as PackedScene
	var player: PlayerTank = packed.instantiate() as PlayerTank
	add_child(player)
	player.global_position = Vector2(640.0, 360.0)
	await get_tree().physics_frame
	var bullet: PlayerBullet = _spawn_player_bullet(Vector2(560.0, 360.0), Vector2.RIGHT)
	if bullet == null:
		player.queue_free()
		return
	await _wait_physics(20)
	if player.hp != 3:
		_fail("player bullet tidak boleh melukai player (hp=%d)" % player.hp)
	if not is_instance_valid(bullet):
		_fail("player bullet tidak boleh hancur karena player")
	if is_instance_valid(bullet):
		bullet.queue_free()
	player.queue_free()
	await get_tree().process_frame

func _check_player_bullet_offscreen() -> void:
	var bullet: PlayerBullet = _spawn_player_bullet(Vector2(3000.0, 3000.0), Vector2.RIGHT)
	if bullet == null:
		return
	await _wait_physics(5)
	if is_instance_valid(bullet):
		_fail("player bullet di luar layar harus hilang")
		bullet.queue_free()
	await get_tree().process_frame
```

- [ ] **Step 3: Jalankan, pastikan gagal**

Run:
```powershell
cmd /c '"D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path "D:\GodotProject\TrenchArmorSurvival" res://tests/phase3_check.tscn 2>&1'
```
Expected: `FAIL: player_bullet.tscn belum ada` (berkali-kali), exit 1.

- [ ] **Step 4: Buat scene + implementasi**

`scenes/projectiles/player_bullet.tscn`:
```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/projectiles/player_bullet.gd" id="1_bullet"]

[sub_resource type="CircleShape2D" id="CircleShape2D_bullet"]
radius = 4.0

[node name="PlayerBullet" type="CharacterBody2D"]
collision_layer = 8
collision_mask = 6
motion_mode = 1
z_index = 20
script = ExtResource("1_bullet")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_bullet")

[node name="Visual" type="Polygon2D" parent="."]
color = Color(1, 0.843137, 0, 1)
polygon = PackedVector2Array(-6, -2, 6, -2, 8, 0, 6, 2, -6, 2, -8, 0)
```

Lengkapi `player_bullet.gd`:
```gdscript
func _ready() -> void:
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	velocity = direction.normalized() * SPEED
	rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision != null:
		_handle_collision(collision)
	if is_queued_for_deletion():
		return
	if not get_viewport().get_visible_rect().grow(OFFSCREEN_MARGIN).has_point(global_position):
		queue_free()

func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider: Object = collision.get_collider()
	if collider == null:
		queue_free()
		return
	if collider.has_method("take_damage"):
		collider.call("take_damage", 1, is_ricochet)
		queue_free()
		return
	if collider is Node and (collider as Node).is_in_group("bouncy_surface"):
		if bounce_count < MAX_BOUNCES:
			_bounce(collision)
		else:
			VFXManager.spawn_ricochet_sparks(collision.get_position(), collision.get_normal())
			queue_free()
		return
	queue_free()

func _bounce(collision: KinematicCollision2D) -> void:
	bounce_count += 1
	is_ricochet = true
	velocity = velocity.bounce(collision.get_normal())
	rotation = velocity.angle()
	visual.color = RICOCHET_COLOR
	EventBus.bullet_ricocheted.emit(collision.get_position(), collision.get_normal())
	AudioManager.play_ricochet()
```
Jangan panggil `VFXManager.spawn_ricochet_sparks` di `_bounce()` (VFXManager sudah
subscribe `bullet_ricocheted`).

- [ ] **Step 5: Jalankan, pastikan lulus**

Run: perintah Step 3. Expected: `PASS`, exit 0, tanpa `ERROR`/`SCRIPT ERROR`.

---

### Task 2: `enemy_bullet.tscn` + `enemy_bullet.gd` (T-015) + bersih-bersih

**Files:**
- Create: `scripts/projectiles/enemy_bullet.gd`
- Create: `scenes/projectiles/enemy_bullet.tscn`
- Modify: `tests/phase3_check.gd` (tambah cek enemy bullet)
- Delete: `tests/phase3_check.gd`, `tests/phase3_check.tscn` (+ `.uid`)

**Interfaces:**
- Produces: `class_name EnemyBullet extends CharacterBody2D`;
  `const DEFAULT_SPEED: float = 400.0`, `const OFFSCREEN_MARGIN: float = 256.0`;
  `var direction: Vector2`, `var speed: float`.
- Consumes: `collider.call("take_damage", 1, false)`; layer 5 / mask 1+3.

- [ ] **Step 1: Tulis stub `EnemyBullet`**

`scripts/projectiles/enemy_bullet.gd`:
```gdscript
class_name EnemyBullet
extends CharacterBody2D

const DEFAULT_SPEED: float = 400.0
const OFFSCREEN_MARGIN: float = 256.0

var direction: Vector2 = Vector2.RIGHT
var speed: float = DEFAULT_SPEED

@onready var visual: Polygon2D = $Visual
```

Jalankan `--headless --editor --quit` agar `class_name EnemyBullet` terdaftar.

- [ ] **Step 2: Tambah cek enemy bullet ke harness**

Tambahkan ke `_run_checks()`:
```gdscript
	await _check_enemy_bullet_contract()
	await _check_enemy_bullet_hits_player()
	await _check_enemy_bullet_wall()
	await _check_enemy_bullet_cover()
	await _check_enemy_bullet_offscreen()
```

Tambahkan helper + tes:
```gdscript
const ENEMY_BULLET: String = "res://scenes/projectiles/enemy_bullet.tscn"

func _spawn_enemy_bullet(pos: Vector2, dir: Vector2, bullet_speed: float) -> EnemyBullet:
	if not ResourceLoader.exists(ENEMY_BULLET):
		_fail("enemy_bullet.tscn belum ada")
		return null
	var packed: PackedScene = load(ENEMY_BULLET) as PackedScene
	var bullet: EnemyBullet = packed.instantiate() as EnemyBullet
	bullet.direction = dir
	bullet.speed = bullet_speed
	add_child(bullet)
	bullet.global_position = pos
	return bullet

func _check_enemy_bullet_contract() -> void:
	var bullet: EnemyBullet = _spawn_enemy_bullet(Vector2(200.0, 600.0), Vector2.DOWN, 350.0)
	if bullet == null:
		return
	await get_tree().physics_frame
	if absf(bullet.velocity.length() - 350.0) > 1.0:
		_fail("enemy bullet speed harus 350, dapat %f" % bullet.velocity.length())
	if bullet.collision_layer != 16:
		_fail("enemy bullet layer harus 16, dapat %d" % bullet.collision_layer)
	if bullet.collision_mask != 5:
		_fail("enemy bullet mask harus 5 (layer 1+3), dapat %d" % bullet.collision_mask)
	bullet.queue_free()
	await get_tree().process_frame

func _check_enemy_bullet_hits_player() -> void:
	var packed: PackedScene = load(PLAYER_SCENE) as PackedScene
	var player: PlayerTank = packed.instantiate() as PlayerTank
	add_child(player)
	player.global_position = Vector2(640.0, 360.0)
	await get_tree().physics_frame
	var bullet: EnemyBullet = _spawn_enemy_bullet(Vector2(560.0, 360.0), Vector2.RIGHT, 400.0)
	if bullet == null:
		player.queue_free()
		return
	await _wait_physics(20)
	if player.hp != 2:
		_fail("enemy bullet harus mengurangi 1 HP player (hp=%d)" % player.hp)
	if is_instance_valid(bullet):
		_fail("enemy bullet harus hilang setelah mengenai player")
	await _wait(0.1)
	player.queue_free()
	await get_tree().process_frame

func _check_enemy_bullet_wall() -> void:
	var wall: StaticBody2D = _make_wall(Vector2(300.0, 400.0), Vector2(20.0, 200.0), false)
	var bullet: EnemyBullet = _spawn_enemy_bullet(Vector2(200.0, 400.0), Vector2.RIGHT, 400.0)
	if bullet == null:
		wall.queue_free()
		return
	await _wait_physics(30)
	if is_instance_valid(bullet):
		_fail("enemy bullet harus hancur di dinding, bukan memantul")
		bullet.queue_free()
	wall.queue_free()
	await get_tree().process_frame

func _check_enemy_bullet_cover() -> void:
	var cover: FakeTarget = _make_target(Vector2(300.0, 600.0), 4)
	var bullet: EnemyBullet = _spawn_enemy_bullet(Vector2(200.0, 600.0), Vector2.RIGHT, 400.0)
	if bullet == null:
		cover.queue_free()
		return
	await _wait_physics(30)
	if cover.damage_events.size() != 1 or cover.damage_events[0] != Vector2i(1, 0):
		_fail("cover harus menerima take_damage(1, false), dapat %s" % str(cover.damage_events))
	if is_instance_valid(bullet):
		_fail("enemy bullet harus hilang setelah mengenai cover")
	cover.queue_free()
	await get_tree().process_frame

func _check_enemy_bullet_offscreen() -> void:
	var bullet: EnemyBullet = _spawn_enemy_bullet(Vector2(3000.0, 3000.0), Vector2.RIGHT, 400.0)
	if bullet == null:
		return
	await _wait_physics(5)
	if is_instance_valid(bullet):
		_fail("enemy bullet di luar layar harus hilang")
		bullet.queue_free()
	await get_tree().process_frame
```

- [ ] **Step 3: Jalankan, pastikan gagal**

Run: perintah Task 1 Step 3. Expected: `FAIL: enemy_bullet.tscn belum ada`, exit 1
(cek player bullet tetap PASS).

- [ ] **Step 4: Buat scene + implementasi**

`scenes/projectiles/enemy_bullet.tscn`:
```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/projectiles/enemy_bullet.gd" id="1_bullet"]

[sub_resource type="CircleShape2D" id="CircleShape2D_bullet"]
radius = 4.0

[node name="EnemyBullet" type="CharacterBody2D"]
collision_layer = 16
collision_mask = 5
motion_mode = 1
z_index = 20
script = ExtResource("1_bullet")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_bullet")

[node name="Visual" type="Polygon2D" parent="."]
color = Color(1, 0.133333, 0.133333, 1)
polygon = PackedVector2Array(-5, -2, 5, -2, 6, 0, 5, 2, -5, 2, -6, 0)
```

Lengkapi `enemy_bullet.gd`:
```gdscript
func _ready() -> void:
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	velocity = direction.normalized() * speed
	rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision != null:
		_handle_collision(collision)
	if is_queued_for_deletion():
		return
	if not get_viewport().get_visible_rect().grow(OFFSCREEN_MARGIN).has_point(global_position):
		queue_free()

func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider: Object = collision.get_collider()
	if collider != null and collider.has_method("take_damage"):
		collider.call("take_damage", 1, false)
	queue_free()
```

- [ ] **Step 5: Jalankan, pastikan lulus**

Run: perintah Task 1 Step 3. Expected: `PASS`, exit 0, tanpa `ERROR`.

- [ ] **Step 6: Hapus harness + validasi editor**

Run:
```powershell
Remove-Item -Recurse -Force tests
cmd /c '"D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path "D:\GodotProject\TrenchArmorSurvival" --editor --quit 2>&1'
```
Expected: exit 0, tanpa `ERROR`/`Parse Error`; `tests/` hilang.

- [ ] **Step 7: Catat hasil di ledger**

Buat `docs/superpowers/plans/2026-11-06-phase3-projectiles.progress.md` dengan status
tiap task, ruling, dan bukti PASS. Tandai `[x]` untuk T-014/T-015 di
`TODO_TrenchArmorSurvival.md` setelah semua lulus.
