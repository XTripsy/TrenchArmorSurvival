# Player Tank (Phase 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membangun tank pemain Phase 2 (T-009..T-013): scene, gerak/aim, tembakan/recoil, damage/i-frames, dan jejak roda prosedural.

**Architecture:** Satu scene `player.tscn` dengan root `CharacterBody2D` + script `player.gd`; semua logika di root, visual prosedural sebagai anak. Test dijalankan lewat satu harness scene sementara yang meng-instance player, mensimulasikan input dengan `Input.action_press`, dan memeriksa node/state langsung.

**Tech Stack:** Godot 4.7.2.stable.steam, GDScript 2.0 static typing, zero asset.

**Spec:** `docs/superpowers/specs/2026-11-06-phase2-player-design.md`

**Status:** Executed 2026-11-06 — all tasks complete; review fix applied. Checkboxes below are the historical task list; see `2026-11-06-phase2-player.progress.md` for evidence.

## Global Constraints

- Static typing eksplisit pada setiap `var`, parameter, dan return type.
- Zero asset: hanya `Polygon2D`/`Line2D`/`CPUParticles2D`/`Marker2D`/`Timer`.
- Komunikasi lintas sistem hanya lewat `EventBus` atau API autoload Phase 1.
- Tidak ada file di luar §2 + `docs/`; harness `tests/` sementara dan dihapus di Task 5.
- Folder ini bukan git repo → tidak ada langkah commit; ledger
  `docs/superpowers/plans/2026-11-06-phase2-player.progress.md` menggantikan commit.
- Player tidak memakai `PROCESS_MODE_ALWAYS`; ikut pause dan hit-stop.
- `res://scenes/projectiles/player_bullet.tscn` belum ada di Phase 2; semua jalur
  peluru harus aman tanpa file itu.

## Review Focus

1. Menembak saat kursor tepat di atas tank → arah aim tetap unit vector, tidak NaN.
   (Test di Task 3.)
2. Dua `take_damage` dalam frame yang sama → hanya satu yang berlaku. (Test di Task 4.)
3. Menembak sambil bergerak ke arah berlawanan → recoil menyusul input tanpa teleport.
   (Test di Task 3.)
4. Pause/hit-stop saat bergerak atau menembak → posisi/cooldown tidak berubah selama
   pause dan lanjut wajar setelah resume. (Test di Task 2 & 4.)
5. Jejak roda saat tank berputar/bergerak terus → tetap 2 titik per potongan, tidak ada
   garis liar, dan tidak menumpuk setelah 3 s. (Test di Task 5.)

---

### Task 1: `player.tscn` + stub script (T-009)

**Files:**
- Create: `scenes/player/player.tscn`
- Create: `scripts/player/player.gd` (`class_name PlayerTank`, `extends CharacterBody2D`)
- Create: `tests/phase2_check.gd`, `tests/phase2_check.tscn`

**Interfaces:**
- Produces: scene path `res://scenes/player/player.tscn`; root `Player`
  (`CharacterBody2D`, `class_name PlayerTank`), grup `"player"`, layer `1`, mask `54`,
  `motion_mode = 1` (floating); node `CollisionShape2D` (Rect 36×36), `HullVisual`
  (`Node2D` → `HullBody`, `TrackLeft`, `TrackRight` `Polygon2D`), `TurretPivot`
  (`Node2D` → `TurretVisual` `Polygon2D` → `Star` `Polygon2D`, `MuzzleMarker`
  `Marker2D`), `TreadTimer` (`Timer`, 0.05).

- [ ] **Step 1: Tulis harness scene + cek hierarki**

`tests/phase2_check.tscn`:
```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tests/phase2_check.gd" id="1_check"]

[node name="Phase2Check" type="Node"]
script = ExtResource("1_check")
```

`tests/phase2_check.gd`:
```gdscript
extends Node

const PLAYER_SCENE: String = "res://scenes/player/player.tscn"

var failures: PackedStringArray = PackedStringArray()

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
	await _check_player_scene()

func _fail(message: String) -> void:
	failures.append(message)

func _check_player_scene() -> void:
	if not ResourceLoader.exists(PLAYER_SCENE):
		_fail("player.tscn belum ada")
		return
	var packed: PackedScene = load(PLAYER_SCENE) as PackedScene
	if packed == null:
		_fail("player.tscn gagal di-load")
		return
	var node: Node = packed.instantiate()
	var player: PlayerTank = node as PlayerTank
	if player == null:
		_fail("root player harus CharacterBody2D dengan script PlayerTank")
		node.free()
		return
	if player.position != Vector2(640.0, 360.0):
		_fail("posisi awal scene harus (640, 360)")
	if not player.is_in_group("player"):
		_fail("player tidak berada di grup \"player\"")
	if player.collision_layer != 1:
		_fail("collision_layer harus 1, dapat %d" % player.collision_layer)
	if player.collision_mask != 54:
		_fail("collision_mask harus 54 (2+3+5+6), dapat %d" % player.collision_mask)
	if player.motion_mode != CharacterBody2D.MOTION_MODE_FLOATING:
		_fail("motion_mode harus FLOATING untuk top-down")
	var shape_node: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		_fail("CollisionShape2D hilang")
	else:
		var rect: RectangleShape2D = shape_node.shape as RectangleShape2D
		if rect == null or rect.size != Vector2(36.0, 36.0):
			_fail("hitbox harus RectangleShape2D 36x36")
	if not (player.get_node_or_null("HullVisual") is Node2D):
		_fail("HullVisual (Node2D) hilang")
	if not (player.get_node_or_null("HullVisual/HullBody") is Polygon2D):
		_fail("HullBody (Polygon2D) hilang")
	if not (player.get_node_or_null("TurretPivot") is Node2D):
		_fail("TurretPivot (Node2D) hilang")
	if not (player.get_node_or_null("TurretPivot/TurretVisual") is Polygon2D):
		_fail("TurretVisual (Polygon2D) hilang")
	if not (player.get_node_or_null("TurretPivot/TurretVisual/Star") is Polygon2D):
		_fail("Star (Polygon2D) hilang")
	if not (player.get_node_or_null("TurretPivot/MuzzleMarker") is Marker2D):
		_fail("MuzzleMarker (Marker2D) hilang")
	var tread_timer: Timer = player.get_node_or_null("TreadTimer") as Timer
	if tread_timer == null:
		_fail("TreadTimer hilang")
	elif not is_equal_approx(tread_timer.wait_time, 0.05):
		_fail("TreadTimer.wait_time harus 0.05")
	add_child(player)
	await get_tree().physics_frame
	player.queue_free()
	await get_tree().process_frame
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run:
```powershell
cmd /c '"D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path "D:\GodotProject\TrenchArmorSurvival" res://tests/phase2_check.tscn 2>&1'
```
Expected: `FAIL: player.tscn belum ada`, exit 1.

- [ ] **Step 3: Buat scene + stub script**

`scripts/player/player.gd` (stub dulu):
```gdscript
class_name PlayerTank
extends CharacterBody2D
```

Setelah menulis script, jalankan `--headless --editor --quit` sekali agar global class
`PlayerTank` terdaftar sebelum harness memakainya sebagai tipe.

`scenes/player/player.tscn` — root `CharacterBody2D` dengan properti:
`groups = ["player"]`, `position = Vector2(640, 360)`, `collision_layer = 1`,
`collision_mask = 54`, `motion_mode = 1`, script `player.gd`.
Isi polygon:
- `HullBody`: `(18,-14), (18,14), (-16,14), (-18,10), (-18,-10), (-16,-14)`, warna `#556B2F`.
- `TrackLeft`: `(-16,-16), (16,-16), (16,-10), (-16,-10)`, warna `#2E241E`.
- `TrackRight`: `(-16,10), (16,10), (16,16), (-16,16)`, warna `#2E241E`.
- `TurretVisual`: `(-8,-6), (20,-3), (22,0), (20,3), (-8,6)`, warna `#3B4A20`.
- `Star`: 10 titik bintang (radius luar 5, dalam 2) berpusat `(0,0)`, warna putih,
  `z_index = 1`.
- `MuzzleMarker`: `position = Vector2(24, 0)`.
- `TreadTimer`: `wait_time = 0.05`, `autostart = true`.

- [ ] **Step 4: Jalankan, pastikan lulus**

Run: perintah Step 2.
Expected: `PASS`, exit 0, tanpa `ERROR`/`SCRIPT ERROR`.

---

### Task 2: Gerak 8 arah, rotasi hull, aim turet (T-010)

**Files:**
- Modify: `scripts/player/player.gd`
- Modify: `tests/phase2_check.gd`

**Interfaces:**
- Consumes: hierarki Task 1; input `move_up/down/left/right`; `AudioManager.play_engine(bool)`.
- Produces: `var speed_multiplier: float = 1.0`, `var hp: int = MAX_HP`,
  `const MAX_HP/BASE_SPEED/TURN_SPEED`; perilaku `_physics_process`.

- [ ] **Step 1: Tambah cek gerak, rotasi, aim, collision, pause**

Tambahkan ke `_run_checks()`:
```gdscript
	await _check_movement()
```

Tambahkan helper + tes:
```gdscript
func _spawn_player() -> PlayerTank:
	var packed: PackedScene = load(PLAYER_SCENE) as PackedScene
	var player: PlayerTank = packed.instantiate() as PlayerTank
	add_child(player)
	player.global_position = Vector2(640.0, 360.0)
	return player

func _wait_physics(frames: int) -> void:
	for i: int in frames:
		await get_tree().physics_frame

func _check_movement() -> void:
	var player: PlayerTank = _spawn_player()
	await get_tree().physics_frame
	var hull: Node2D = player.get_node("HullVisual") as Node2D
	var turret: Node2D = player.get_node("TurretPivot") as Node2D

	var start: Vector2 = player.global_position
	Input.action_press("move_right")
	await _wait_physics(15)
	Input.action_release("move_right")
	if player.global_position.x <= start.x + 10.0:
		_fail("gerak kanan tidak menggeser player")
	if absf(angle_difference(hull.rotation, 0.0)) > 0.25:
		_fail("hull tidak menghadap arah gerak")

	Input.action_press("move_up")
	await _wait_physics(15)
	Input.action_release("move_up")
	if absf(angle_difference(hull.rotation, -PI / 2.0)) > 0.25:
		_fail("hull tidak berputar ke atas saat bergerak naik")
	var frozen: float = hull.rotation
	await _wait_physics(5)
	if not is_equal_approx(hull.rotation, frozen):
		_fail("hull berputar saat idle")

	var expected_aim: float = (player.get_global_mouse_position() - player.global_position).angle()
	if absf(angle_difference(turret.rotation, expected_aim)) > 0.05:
		_fail("turet tidak mengarah ke kursor")

	player.speed_multiplier = 0.5
	Input.action_press("move_right")
	await _wait_physics(3)
	if absf(player.velocity.length() - 110.0) > 1.0:
		_fail("speed_multiplier tidak memengaruhi kecepatan")
	Input.action_release("move_right")
	player.speed_multiplier = 1.0

	var wall: StaticBody2D = StaticBody2D.new()
	wall.collision_layer = 4
	wall.collision_mask = 0
	var wall_shape: CollisionShape2D = CollisionShape2D.new()
	var wall_rect: RectangleShape2D = RectangleShape2D.new()
	wall_rect.size = Vector2(20.0, 200.0)
	wall_shape.shape = wall_rect
	wall.add_child(wall_shape)
	add_child(wall)
	wall.global_position = Vector2(700.0, 360.0)
	player.global_position = Vector2(640.0, 360.0)
	Input.action_press("move_right")
	await _wait_physics(40)
	Input.action_release("move_right")
	if player.global_position.x > 690.0:
		_fail("player tidak terhalang dinding (mask layer 3 salah)")
	wall.queue_free()
	await get_tree().physics_frame

	player.global_position = Vector2(640.0, 360.0)
	GameManager.change_state(GameManager.State.PLAYING)
	GameManager.change_state(GameManager.State.PAUSED)
	Input.action_press("move_right")
	await _wait_physics(10)
	Input.action_release("move_right")
	if absf(player.global_position.x - 640.0) > 0.5:
		_fail("player bergerak saat pause")
	GameManager.change_state(GameManager.State.PLAYING)
	player.queue_free()
	await get_tree().process_frame
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Expected: FAIL karena `player.velocity` selalu nol / tidak ada gerak (script masih stub).

- [ ] **Step 3: Implementasikan `player.gd` bagian gerak & aim**

```gdscript
class_name PlayerTank
extends CharacterBody2D

const MAX_HP: int = 3
const BASE_SPEED: float = 220.0
const TURN_SPEED: float = 10.0

var hp: int = MAX_HP
var speed_multiplier: float = 1.0
var _engine_moving: bool = false

@onready var hull_visual: Node2D = $HullVisual
@onready var turret_pivot: Node2D = $TurretPivot

func _ready() -> void:
	hp = MAX_HP
	AudioManager.play_engine(false)

func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * BASE_SPEED * speed_multiplier
	move_and_slide()
	var has_input: bool = input_vector.length_squared() > 0.0
	if has_input:
		hull_visual.rotation = lerp_angle(hull_visual.rotation, input_vector.angle(), TURN_SPEED * delta)
	turret_pivot.look_at(get_global_mouse_position())
	if has_input != _engine_moving:
		_engine_moving = has_input
		AudioManager.play_engine(_engine_moving)
```

- [ ] **Step 4: Jalankan, pastikan lulus**

Expected: `PASS`, exit 0.

---

### Task 3: Tembakan, recoil, VFX/audio/shake (T-011)

**Files:**
- Modify: `scripts/player/player.gd`
- Modify: `tests/phase2_check.gd`

**Interfaces:**
- Consumes: `VFXManager.spawn_muzzle_flash(Vector2, float)`, `AudioManager.play_cannon()`,
  `EventBus.camera_shake_requested`, `ResourceLoader.exists()`.
- Produces: `var _fire_cooldown_left: float`, `const FIRE_COOLDOWN/RECOIL_FORCE/RECOIL_DECAY`,
  `_fire()`; kontrak peluru: `direction` diisi bila properti ada.

- [ ] **Step 1: Tambah cek tembakan & recoil**

Tambahkan ke `_run_checks()`:
```gdscript
	await _check_shooting()
```

Tambahkan:
```gdscript
func _check_shooting() -> void:
	var player: PlayerTank = _spawn_player()
	await get_tree().physics_frame
	var turret: Node2D = player.get_node("TurretPivot") as Node2D
	var turret_visual: Polygon2D = player.get_node("TurretPivot/TurretVisual") as Polygon2D
	var base_x: float = turret_visual.position.x
	var shakes: Array[Vector2] = []
	var on_shake: Callable = func(intensity: float, duration: float) -> void:
		shakes.append(Vector2(intensity, duration))
	EventBus.camera_shake_requested.connect(on_shake)

	var baseline: int = get_child_count()
	Input.action_press("shoot")
	await _wait_physics(3)
	Input.action_release("shoot")
	if get_child_count() <= baseline:
		_fail("menembak tidak memunculkan muzzle flash/smoke")
	if shakes.count(Vector2(2.0, 0.1)) != 1:
		_fail("shake tembakan harus tepat satu (2.0, 0.1)")
	if player._fire_cooldown_left <= 0.0:
		_fail("cooldown tidak dimulai setelah menembak")

	var aim: Vector2 = Vector2.RIGHT.rotated(turret.rotation)
	var before: Vector2 = player.global_position
	await _wait_physics(6)
	if (player.global_position - before).dot(aim) >= -1.0:
		_fail("recoil tidak mendorong player ke belakang")

	Input.action_press("shoot")
	await _wait_physics(3)
	Input.action_release("shoot")
	if shakes.count(Vector2(2.0, 0.1)) != 1:
		_fail("bisa menembak lagi sebelum cooldown habis")
	await _wait(0.5)
	Input.action_press("shoot")
	await _wait_physics(3)
	Input.action_release("shoot")
	if shakes.count(Vector2(2.0, 0.1)) != 2:
		_fail("tidak bisa menembak lagi setelah cooldown")

	await _wait(0.3)
	if not is_equal_approx(turret_visual.position.x, base_x):
		_fail("barrel tidak kembali ke posisi awal setelah recoil")

	# Menembak saat bergerak ke arah berlawanan: recoil + input, tanpa teleport.
	await _wait(0.5)
	Input.action_press("move_left")
	await _wait_physics(2)
	var moving_before: Vector2 = player.global_position
	Input.action_press("shoot")
	await _wait_physics(6)
	Input.action_release("shoot")
	Input.action_release("move_left")
	var moved: float = (player.global_position - moving_before).length()
	if moved > 40.0:
		_fail("recoil + gerak melompat terlalu jauh (teleport)")

	# Kursor tepat di tank: aim tetap unit vector, recoil tepat 200.
	player._recoil_velocity = Vector2.ZERO
	player._fire_cooldown_left = 0.0
	turret.rotation = 0.0
	player._fire()
	if not is_equal_approx(player._recoil_velocity.length(), 200.0):
		_fail("aim bukan unit vector saat turet menghadap +X")

	EventBus.camera_shake_requested.disconnect(on_shake)
	Input.action_release("shoot")
	player.queue_free()
	await get_tree().process_frame
```

Tambahkan `_wait`:
```gdscript
func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Expected: FAIL `menembak tidak memunculkan muzzle flash/smoke` dst.

- [ ] **Step 3: Implementasikan tembakan & recoil**

Tambahkan konstanta:
```gdscript
const FIRE_COOLDOWN: float = 0.45
const RECOIL_FORCE: float = 40.0
const RECOIL_DECAY: float = 900.0
const BULLET_SCENE: String = "res://scenes/projectiles/player_bullet.tscn"
```

State:
```gdscript
var _fire_cooldown_left: float = 0.0
var _recoil_velocity: Vector2 = Vector2.ZERO
var _recoil_tween: Tween = null

@onready var turret_visual: Polygon2D = $TurretPivot/TurretVisual
@onready var muzzle_marker: Marker2D = $TurretPivot/MuzzleMarker
```

Di `_physics_process`, setelah `move_and_slide()`:
```gdscript
	_recoil_velocity = _recoil_velocity.move_toward(Vector2.ZERO, RECOIL_DECAY * delta)
	_fire_cooldown_left = maxf(0.0, _fire_cooldown_left - delta)
	if Input.is_action_pressed("shoot") and _fire_cooldown_left <= 0.0:
		_fire()
```

Ganti baris `velocity = ...` menjadi:
```gdscript
	velocity = input_vector * BASE_SPEED * speed_multiplier + _recoil_velocity
```

`_fire()`:
```gdscript
func _fire() -> void:
	_fire_cooldown_left = FIRE_COOLDOWN
	var aim: Vector2 = Vector2.RIGHT.rotated(turret_pivot.global_rotation)
	_recoil_velocity -= aim * RECOIL_FORCE * 5.0
	VFXManager.spawn_muzzle_flash(muzzle_marker.global_position, aim.angle())
	AudioManager.play_cannon()
	EventBus.camera_shake_requested.emit(2.0, 0.1)
	_play_recoil_tween()
	_spawn_bullet(aim)

func _play_recoil_tween() -> void:
	if _recoil_tween != null and _recoil_tween.is_valid():
		_recoil_tween.kill()
	var base_x: float = turret_visual.position.x
	_recoil_tween = create_tween()
	_recoil_tween.tween_property(turret_visual, "position:x", base_x - 6.0, 0.05)
	_recoil_tween.tween_property(turret_visual, "position:x", base_x, 0.12)

func _spawn_bullet(aim: Vector2) -> void:
	if not ResourceLoader.exists(BULLET_SCENE):
		return
	var packed: PackedScene = load(BULLET_SCENE) as PackedScene
	if packed == null:
		return
	var bullet: Node2D = packed.instantiate() as Node2D
	if bullet == null:
		return
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(bullet)
	bullet.global_position = muzzle_marker.global_position
	bullet.rotation = aim.angle()
	if bullet.get("direction") != null:
		bullet.set("direction", aim)
```

- [ ] **Step 4: Jalankan, pastikan lulus**

Expected: `PASS`, exit 0, tanpa error meskipun `player_bullet.tscn` belum ada.

---

### Task 4: Damage, i-frames, hit flash, death (T-012)

**Files:**
- Modify: `scripts/player/player.gd`
- Modify: `tests/phase2_check.gd`

**Interfaces:**
- Consumes: `EventBus.player_damaged/player_died`, `GameManager.trigger_hit_stop`,
  `VFXManager.spawn_tank_explosion`.
- Produces: `take_damage(amount: int, _is_ricochet: bool = false) -> void`,
  `var is_invulnerable: bool`, `var _alive: bool`.

- [ ] **Step 1: Tambah cek damage, i-frames, dan kematian**

Tambahkan ke `_run_checks()`:
```gdscript
	await _check_damage()
```

Tambahkan:
```gdscript
func _check_damage() -> void:
	var player: PlayerTank = _spawn_player()
	await get_tree().physics_frame
	var hull: Node2D = player.get_node("HullVisual") as Node2D
	var turret: Node2D = player.get_node("TurretPivot") as Node2D
	var shakes: Array[Vector2] = []
	var damage_events: Array[Vector2i] = []
	var death_events: Array[bool] = []
	var on_shake: Callable = func(intensity: float, duration: float) -> void:
		shakes.append(Vector2(intensity, duration))
	var on_damage: Callable = func(current_hp: int, max_hp: int) -> void:
		damage_events.append(Vector2i(current_hp, max_hp))
	var on_death: Callable = func() -> void:
		death_events.append(true)
	EventBus.camera_shake_requested.connect(on_shake)
	EventBus.player_damaged.connect(on_damage)
	EventBus.player_died.connect(on_death)

	player.take_damage(1)
	if player.hp != 2:
		_fail("damage 1: hp harus 2, dapat %d" % player.hp)
	if damage_events.is_empty() or damage_events[-1] != Vector2i(2, 3):
		_fail("player_damaged harus membawa (2, 3)")
	if not player.is_invulnerable:
		_fail("i-frames tidak aktif setelah damage")
	if not is_equal_approx(Engine.time_scale, 0.05):
		_fail("damage tidak memicu hit-stop")
	if not shakes.has(Vector2(12.0, 0.35)):
		_fail("damage tidak memicu shake (12.0, 0.35)")
	if absf(hull.modulate.r - 10.0) > 0.1:
		_fail("hit flash putih tidak diterapkan")
	await _wait(0.25)
	if not is_equal_approx(hull.modulate.r, 1.0):
		_fail("hit flash tidak kembali normal")
	if not is_equal_approx(Engine.time_scale, 1.0):
		_fail("time_scale tidak kembali 1.0")

	player.take_damage(1)
	if player.hp != 2:
		_fail("damage kedua saat i-frame tidak boleh berlaku")
	if damage_events.size() != 1:
		_fail("player_damaged ter-emit ganda saat i-frame")

	await _wait(1.25)
	if player.is_invulnerable:
		_fail("i-frames tidak berakhir setelah 1.2s")

	var baseline: int = get_child_count()
	player.take_damage(2)
	if player.hp != 0:
		_fail("damage fatal: hp harus 0, dapat %d" % player.hp)
	if death_events.size() != 1:
		_fail("player_died harus ter-emit tepat sekali")
	if player._alive:
		_fail("player masih hidup setelah hp 0")
	if hull.visible or turret.visible:
		_fail("visual player tidak disembunyikan saat mati")
	if get_child_count() <= baseline:
		_fail("kematian tidak memunculkan ledakan")
	await _wait(0.25)
	if not is_equal_approx(Engine.time_scale, 1.0):
		_fail("time_scale tidak kembali setelah kematian")

	var shakes_before: int = shakes.size()
	Input.action_press("shoot")
	await _wait_physics(5)
	Input.action_release("shoot")
	if shakes.size() != shakes_before:
		_fail("player mati masih bisa menembak")
	player.take_damage(1)
	if player.hp != 0 or death_events.size() != 1:
		_fail("damage setelah mati tidak boleh berlaku")

	EventBus.camera_shake_requested.disconnect(on_shake)
	EventBus.player_damaged.disconnect(on_damage)
	EventBus.player_died.disconnect(on_death)
	player.queue_free()
	await get_tree().process_frame
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Expected: FAIL `Invalid call ... take_damage` atau hp tidak berubah.

- [ ] **Step 3: Implementasikan damage, i-frames, dan kematian**

Tambahkan konstanta/state:
```gdscript
const IFRAME_DURATION: float = 1.2
const HIT_FLASH_DURATION: float = 0.1

var is_invulnerable: bool = false
var _alive: bool = true
var _iframe_tween: Tween = null

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var tread_timer: Timer = $TreadTimer
```

Implementasi:
```gdscript
func take_damage(amount: int, _is_ricochet: bool = false) -> void:
	if not _alive or is_invulnerable:
		return
	hp = maxi(0, hp - amount)
	EventBus.player_damaged.emit(hp, MAX_HP)
	EventBus.camera_shake_requested.emit(12.0, 0.35)
	GameManager.trigger_hit_stop(0.05)
	_flash_white()
	if hp <= 0:
		_die()
	else:
		_start_iframes()

func _flash_white() -> void:
	hull_visual.modulate = Color(10.0, 10.0, 10.0, 1.0)
	turret_visual.modulate = Color(10.0, 10.0, 10.0, 1.0)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(hull_visual, "modulate", Color.WHITE, HIT_FLASH_DURATION)
	tween.tween_property(turret_visual, "modulate", Color.WHITE, HIT_FLASH_DURATION)

func _start_iframes() -> void:
	is_invulnerable = true
	if _iframe_tween != null and _iframe_tween.is_valid():
		_iframe_tween.kill()
	_iframe_tween = create_tween()
	for i: int in 6:
		_iframe_tween.tween_property(self, "modulate:a", 0.25, 0.1)
		_iframe_tween.tween_property(self, "modulate:a", 1.0, 0.1)
	_iframe_tween.tween_callback(_on_iframes_finished)

func _on_iframes_finished() -> void:
	modulate.a = 1.0
	is_invulnerable = false

func _die() -> void:
	_alive = false
	is_invulnerable = true
	if _iframe_tween != null and _iframe_tween.is_valid():
		_iframe_tween.kill()
	modulate.a = 1.0
	EventBus.player_died.emit()
	VFXManager.spawn_tank_explosion(global_position)
	hull_visual.visible = false
	turret_pivot.visible = false
	collision_shape.set_deferred("disabled", true)
	tread_timer.stop()
```

Tambahkan guard di awal `_physics_process`:
```gdscript
	if not _alive:
		return
```

- [ ] **Step 4: Jalankan, pastikan lulus**

Expected: `PASS`, exit 0.

---

### Task 5: Jejak roda + bersih-bersih (T-013)

**Files:**
- Create: `scenes/player/tread_mark.tscn`
- Modify: `scripts/player/player.gd`
- Modify: `tests/phase2_check.gd`
- Delete: `tests/phase2_check.gd`, `tests/phase2_check.tscn` (+ `.uid`)

**Interfaces:**
- Consumes: `TreadTimer`, `HullVisual`; scene `res://scenes/player/tread_mark.tscn`.
- Produces: `const TREAD_FADE/TREAD_WIDTH`; jejak roda world-space.

- [ ] **Step 1: Tambah cek jejak roda**

Tambahkan ke `_run_checks()`:
```gdscript
	await _check_tread_marks()
```

Tambahkan:
```gdscript
func _count_tread_marks(node: Node) -> int:
	var count: int = 0
	for child: Node in node.get_children():
		if child is Line2D and child.name.begins_with("TreadMark"):
			count += 1
		count += _count_tread_marks(child)
	return count

func _check_tread_marks() -> void:
	var player: PlayerTank = _spawn_player()
	await get_tree().physics_frame
	var before: int = _count_tread_marks(self)
	await _wait(0.2)
	if _count_tread_marks(self) != before:
		_fail("jejak roda muncul saat idle")

	Input.action_press("move_right")
	await _wait(0.35)
	Input.action_release("move_right")
	var marks: int = _count_tread_marks(self)
	if marks < 6:
		_fail("jejak roda tidak muncul saat bergerak (dapat %d)" % marks)
	var sample: Line2D = null
	for child: Node in get_children():
		if child is Line2D and child.name.begins_with("TreadMark"):
			sample = child as Line2D
			break
	if sample == null:
		_fail("tidak ada node TreadMark")
	else:
		if sample.get_parent() == player:
			_fail("jejak roda harus di-parent ke world, bukan player")
		if sample.z_index != -2:
			_fail("jejak roda harus z_index -2")
		if sample.width != 5.0:
			_fail("jejak roda harus width 5.0")
		if not sample.default_color.is_equal_approx(Color("#2E241E")):
			_fail("jejak roda harus berwarna #2E241E")
		if sample.points.size() != 2:
			_fail("tiap potongan jejak harus 2 titik")

	await _wait(0.2)
	if _count_tread_marks(self) != marks:
		_fail("jejak roda bertambah saat idle")
	await _wait(3.2)
	if _count_tread_marks(self) != 0:
		_fail("jejak roda tidak hilang setelah 3s")
	player.queue_free()
	await get_tree().process_frame
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Expected: FAIL `jejak roda tidak muncul saat bergerak`.

- [ ] **Step 3: Buat `tread_mark.tscn` + implementasi**

`scenes/player/tread_mark.tscn`:
```ini
[gd_scene format=3]

[node name="TreadMark" type="Line2D"]
width = 5.0
default_color = Color(0.180392, 0.141176, 0.117647, 1)
z_index = -2
antialiased = true
```

Di `player.gd` tambahkan:
```gdscript
const TREAD_MARK_SCENE: String = "res://scenes/player/tread_mark.tscn"
const TREAD_FADE: float = 3.0

var _last_left_track: Vector2
var _last_right_track: Vector2
var _had_track_anchor: bool = false
```

Di `_ready()`:
```gdscript
	tread_timer.timeout.connect(_on_tread_timer_timeout)
```

Di `_physics_process`, setelah menghitung `has_input`:
```gdscript
	if has_input and not _had_track_anchor:
		_last_left_track = _track_point(-13.0)
		_last_right_track = _track_point(13.0)
		_had_track_anchor = true
	elif not has_input:
		_had_track_anchor = false
```

Implementasi:
```gdscript
func _track_point(side: float) -> Vector2:
	return hull_visual.global_transform * Vector2(-4.0, side)

func _on_tread_timer_timeout() -> void:
	if not _alive or not _had_track_anchor:
		return
	var left: Vector2 = _track_point(-13.0)
	var right: Vector2 = _track_point(13.0)
	_spawn_tread_mark(_last_left_track, left)
	_spawn_tread_mark(_last_right_track, right)
	_last_left_track = left
	_last_right_track = right

func _spawn_tread_mark(from: Vector2, to: Vector2) -> void:
	if not ResourceLoader.exists(TREAD_MARK_SCENE):
		return
	var packed: PackedScene = load(TREAD_MARK_SCENE) as PackedScene
	if packed == null:
		return
	var mark: Line2D = packed.instantiate() as Line2D
	if mark == null:
		return
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(mark)
	mark.points = PackedVector2Array([from, to])
	var tween: Tween = mark.create_tween()
	tween.tween_property(mark, "modulate:a", 0.0, TREAD_FADE)
	tween.tween_callback(mark.queue_free)
```

Catatan: `has_input` harus dipakai juga untuk audio/hull (sudah dari Task 2/3), bukan velocity.

- [ ] **Step 4: Jalankan, pastikan lulus**

Expected: `PASS`, exit 0, tanpa `ERROR`.

- [ ] **Step 5: Hapus harness + validasi editor**

Run:
```powershell
Remove-Item -Recurse -Force tests
cmd /c '"D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path "D:\GodotProject\TrenchArmorSurvival" --editor --quit 2>&1'
```
Expected: exit 0, tanpa `ERROR`/`Parse Error`; `tests/` hilang.

- [ ] **Step 6: Catat hasil di ledger**

Buat/isi `docs/superpowers/plans/2026-11-06-phase2-player.progress.md` dengan status
tiap task, ruling, dan bukti PASS. Tandai `[x]` untuk T-009..T-013 di
`TODO_TrenchArmorSurvival.md` setelah semua lulus.
