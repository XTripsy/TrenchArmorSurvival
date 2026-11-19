# Autoload Core (Phase 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mengimplementasikan `EventBus`, `VFXManager`, `GameManager`, dan `AudioManager` sesuai TAD §4 dengan tes headless yang gagal dulu lalu lulus.

**Architecture:** Empat autoload sudah terdaftar sejak Phase 0. Setiap task mengganti stub dengan implementasi penuh dan menambah assertion di satu harness sementara `tests/phase1_check.tscn`. VFX memakai `Polygon2D`/`CPUParticles2D`; audio memakai `AudioStreamGenerator` dengan waveform pra-render.

**Tech Stack:** Godot 4.7.2.stable.steam, GDScript 2.0 static typing, tanpa asset.

**Spec:** `docs/superpowers/specs/2026-11-06-phase1-autoloads-design.md`

## Global Constraints

- Static typing eksplisit pada setiap `var`, parameter, dan return type.
- Zero asset: tidak ada file gambar/audio.
- Autoload `GameManager`/`AudioManager` memakai `process_mode = PROCESS_MODE_ALWAYS`; `VFXManager` mengikuti pause.
- Komunikasi lintas sistem hanya lewat `EventBus`.
- Semua pemutaran audio harus aman saat `get_stream_playback()` mengembalikan `null` (headless/dummy driver).
- Harness `tests/` bersifat sementara dan dihapus di Task 4.
- Folder ini bukan git repo → tidak ada langkah commit.

## Review Focus

- Hit-stop bertumpuk: dua `trigger_hit_stop` berurutan → `Engine.time_scale` harus tetap kembali 1.0, bukan tertahan 0.05.
- Ricochet kill saat `floating_text.tscn` belum ada → tidak boleh error, teks tetap muncul.
- Pause saat hit-stop aktif → timer restore harus tetap jalan dan `paused` kembali false setelah state berubah.
- Audio tanpa device → keempat API tidak boleh mencetak error.
- Efek yang dipanggil berulang → node harus `queue_free` (tidak menumpuk tanpa batas).

---

### Task 1: `EventBus` (T-005)

**Files:**
- Modify: `autoloads/event_bus.gd`
- Create: `tests/phase1_check.gd`
- Create: `tests/phase1_check.tscn`

**Interfaces:**
- Produces: 7 signal — `player_damaged(current_hp: int, max_hp: int)`, `player_died()`, `enemy_destroyed(enemy_position: Vector2, base_score: int, was_ricochet: bool)`, `score_updated(new_score: int, ricochet_kills: int)`, `camera_shake_requested(intensity: float, duration: float)`, `bullet_ricocheted(impact_position: Vector2, impact_normal: Vector2)`, `game_state_changed(new_state: int)`.

- [ ] **Step 1: Tulis harness (gagal)**

`tests/phase1_check.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tests/phase1_check.gd" id="1_check"]

[node name="Phase1Check" type="Node"]
script = ExtResource("1_check")
```

`tests/phase1_check.gd`:

```gdscript
extends Node

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
	_check_event_bus()
	await _wait(0.1)

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func _fail(message: String) -> void:
	failures.append(message)

func _check_event_bus() -> void:
	var expected: Dictionary = {
		"player_damaged": [TYPE_INT, TYPE_INT],
		"player_died": [],
		"enemy_destroyed": [TYPE_VECTOR2, TYPE_INT, TYPE_BOOL],
		"score_updated": [TYPE_INT, TYPE_INT],
		"camera_shake_requested": [TYPE_FLOAT, TYPE_FLOAT],
		"bullet_ricocheted": [TYPE_VECTOR2, TYPE_VECTOR2],
		"game_state_changed": [TYPE_INT],
	}
	for signal_name: String in expected:
		if not EventBus.has_signal(signal_name):
			_fail("signal hilang: %s" % signal_name)
			continue
		var actual: Array[int] = []
		for signal_info: Dictionary in EventBus.get_signal_list():
			if signal_info["name"] == signal_name:
				for arg: Dictionary in signal_info["args"]:
					actual.append(int(arg["type"]))
				break
		var wanted: Array[int] = []
		for type_id: int in expected[signal_name]:
			wanted.append(type_id)
		if actual != wanted:
			_fail("argumen %s: harus %s, dapat %s" % [signal_name, str(wanted), str(actual)])
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run:
```powershell
cmd /c '"D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path "D:\GodotProject\TrenchArmorSurvival" res://tests/phase1_check.tscn' 2>&1
```
Expected: 7 baris `FAIL: signal hilang: ...`, exit code 1.

- [ ] **Step 3: Implementasikan `autoloads/event_bus.gd`**

```gdscript
extends Node

signal player_damaged(current_hp: int, max_hp: int)
signal player_died()
signal enemy_destroyed(enemy_position: Vector2, base_score: int, was_ricochet: bool)
signal score_updated(new_score: int, ricochet_kills: int)
signal camera_shake_requested(intensity: float, duration: float)
signal bullet_ricocheted(impact_position: Vector2, impact_normal: Vector2)
signal game_state_changed(new_state: int)
```

- [ ] **Step 4: Jalankan, pastikan lulus**

Run: perintah Step 2
Expected: `PASS`, exit code 0, tanpa `ERROR`.

---

### Task 2: `VFXManager` (T-007)

**Files:**
- Modify: `autoloads/vfx_manager.gd`
- Modify: `tests/phase1_check.gd`

**Interfaces:**
- Consumes: `EventBus.bullet_ricocheted`, `EventBus.enemy_destroyed`, `EventBus.camera_shake_requested`.
- Produces: `spawn_muzzle_flash(pos: Vector2, rot: float) -> void`, `spawn_ricochet_sparks(pos: Vector2, normal: Vector2) -> void`, `spawn_tank_explosion(pos: Vector2) -> void`, `spawn_floating_text(pos: Vector2, text: String) -> void`.
- Scene contract: bila `res://scenes/ui/floating_text.tscn` ada, node root-nya `Node2D` dan punya `setup(text: String) -> void`; kalau tidak, VFXManager membuat label prosedural sendiri.

- [ ] **Step 1: Tambah cek VFX ke harness**

Tambahkan `await _check_vfx()` di `_run_checks()` setelah `_check_event_bus()`, lalu fungsi:

```gdscript
func _check_vfx() -> void:
	var methods: Array[String] = ["spawn_muzzle_flash", "spawn_ricochet_sparks", "spawn_tank_explosion", "spawn_floating_text"]
	for method_name: String in methods:
		if not VFXManager.has_method(method_name):
			_fail("VFXManager tidak punya method: %s" % method_name)
	if not failures.is_empty():
		return

	var baseline: int = get_child_count()

	VFXManager.spawn_muzzle_flash(Vector2(100, 100), 0.0)
	if get_child_count() <= baseline:
		_fail("muzzle flash tidak membuat node efek")
	await _wait(0.2)
	if get_child_count() > baseline:
		_fail("muzzle flash tidak dibersihkan setelah 0.2s")

	VFXManager.spawn_ricochet_sparks(Vector2(100, 100), Vector2.UP)
	if get_child_count() <= baseline:
		_fail("ricochet sparks tidak membuat node efek")

	VFXManager.spawn_tank_explosion(Vector2(200, 200))
	if get_child_count() <= baseline:
		_fail("tank explosion tidak membuat node efek")

	baseline = get_child_count()
	VFXManager.spawn_floating_text(Vector2(200, 200), "+200 RICOCHET!")
	if get_child_count() <= baseline:
		_fail("floating text tidak membuat node")
	await _wait(1.0)
	if get_child_count() > baseline:
		_fail("floating text tidak hilang setelah 0.8s")

	var shakes: Array[Vector2] = []
	var on_shake: Callable = func(intensity: float, duration: float) -> void:
		shakes.append(Vector2(intensity, duration))
	EventBus.camera_shake_requested.connect(on_shake)
	var baseline_shake: int = get_child_count()
	EventBus.enemy_destroyed.emit(Vector2(300, 300), 100, false)
	EventBus.camera_shake_requested.disconnect(on_shake)
	if shakes.size() != 1 or shakes[0] != Vector2(5.0, 0.2):
		_fail("enemy_destroyed tidak memicu camera shake (5.0, 0.2)")
	if get_child_count() <= baseline_shake:
		_fail("enemy_destroyed tidak memicu explosion")

	var baseline_spark: int = get_child_count()
	EventBus.bullet_ricocheted.emit(Vector2(50, 50), Vector2.RIGHT)
	if get_child_count() <= baseline_spark:
		_fail("bullet_ricocheted tidak memicu sparks")

	var repeated_baseline: int = get_child_count()
	for i: int in 20:
		VFXManager.spawn_muzzle_flash(Vector2(100, 100), 0.0)
	await _wait(0.3)
	if get_child_count() > repeated_baseline:
		_fail("muzzle flash berulang tidak dibersihkan")
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: perintah Task 1 Step 2
Expected: 4 baris `FAIL: VFXManager tidak punya method: ...`, exit code 1.

- [ ] **Step 3: Implementasikan `autoloads/vfx_manager.gd`**

Ketentuan yang harus dipenuhi (bentuk bebas selama kontraknya sama):
- Parent efek: `get_tree().current_scene` bila valid, jika tidak `self`.
- Muzzle flash: `Polygon2D` kuning-putih `#FFF2B2` di `pos` dengan `rotation = rot`, memudar dalam 0.08 s lalu `queue_free`, plus `CPUParticles2D` asap kelabu.
- Ricochet sparks: `CPUParticles2D` satu kali, `color = Color("#FFD700")`, `direction = normal`, `spread = 45.0`, `lifetime = 0.25`.
- Tank explosion: scorch `Polygon2D` hitam transparan `z_index = -1` (fade setelah ~4 s), partikel api `#FF5500`, asap hitam, dan 3–5 pecahan `Polygon2D` yang meluncur 0.4 s lalu fade setelah ~4 s.
- Floating text: lihat kontrak scene di **Interfaces**; gerak naik 30 px dan fade 0.8 s lalu `queue_free`.
- `_ready()`: `EventBus.bullet_ricocheted` → `spawn_ricochet_sparks`; `EventBus.enemy_destroyed` → `spawn_tank_explosion` + `EventBus.camera_shake_requested.emit(5.0, 0.2)`.
- Jangan set `process_mode`; efek harus ikut pause.

- [ ] **Step 4: Jalankan, pastikan lulus**

Run: perintah Task 1 Step 2
Expected: `PASS`, exit code 0, tanpa `ERROR`.

---

### Task 3: `GameManager` (T-006)

**Files:**
- Modify: `autoloads/game_manager.gd`
- Modify: `tests/phase1_check.gd`

**Interfaces:**
- Consumes: `EventBus.enemy_destroyed`, `EventBus.player_died`; `VFXManager.spawn_floating_text(pos: Vector2, text: String)`.
- Produces: `enum State { MENU, PLAYING, PAUSED, GAME_OVER }`, `var state: State`, `var score: int`, `var time_survived: float`, `var ricochet_kills: int`, `change_state(new_state: State) -> void`, `reset_run() -> void`, `trigger_hit_stop(duration: float = 0.05) -> void`.

- [ ] **Step 1: Tambah cek GameManager ke harness**

Tambahkan `await _check_game_manager()` di `_run_checks()` setelah VFX, lalu:

```gdscript
func _check_game_manager() -> void:
	var methods: Array[String] = ["change_state", "reset_run", "trigger_hit_stop"]
	for method_name: String in methods:
		if not GameManager.has_method(method_name):
			_fail("GameManager tidak punya method: %s" % method_name)
	if not failures.is_empty():
		return

	GameManager.reset_run()
	if GameManager.score != 0 or GameManager.time_survived != 0.0 or GameManager.ricochet_kills != 0:
		_fail("reset_run tidak mengosongkan skor/waktu/ricochet")

	var scores: Array[Vector2i] = []
	var on_score: Callable = func(new_score: int, ricochet: int) -> void:
		scores.append(Vector2i(new_score, ricochet))
	EventBus.score_updated.connect(on_score)

	GameManager.change_state(GameManager.State.PLAYING)
	await _wait(0.15)
	if GameManager.time_survived <= 0.0:
		_fail("time_survived tidak bertambah saat PLAYING")

	EventBus.enemy_destroyed.emit(Vector2.ZERO, 100, false)
	if GameManager.score != 100:
		_fail("skor direct kill: harus 100, dapat %d" % GameManager.score)
	EventBus.enemy_destroyed.emit(Vector2.ZERO, 100, true)
	if GameManager.score != 300:
		_fail("skor ricochet kill: harus 300, dapat %d" % GameManager.score)
	if GameManager.ricochet_kills != 1:
		_fail("ricochet_kills: harus 1, dapat %d" % GameManager.ricochet_kills)
	if scores.is_empty() or scores[-1] != Vector2i(300, 1):
		_fail("score_updated tidak membawa (300, 1)")
	if not _has_label_with_text(self, "+200 RICOCHET!"):
		_fail("ricochet kill tidak memunculkan floating text")

	GameManager.change_state(GameManager.State.PAUSED)
	if not get_tree().paused:
		_fail("PAUSED tidak menghentikan SceneTree")
	GameManager.change_state(GameManager.State.PLAYING)
	if get_tree().paused:
		_fail("PLAYING tidak melanjutkan SceneTree")

	GameManager.trigger_hit_stop(0.05)
	if not is_equal_approx(Engine.time_scale, 0.05):
		_fail("hit-stop tidak menyetel time_scale 0.05")
	await _wait(0.2)
	if not is_equal_approx(Engine.time_scale, 1.0):
		_fail("time_scale tidak kembali 1.0 setelah hit-stop")

	GameManager.trigger_hit_stop(0.05)
	await _wait(0.02)
	GameManager.trigger_hit_stop(0.05)
	await _wait(0.3)
	if not is_equal_approx(Engine.time_scale, 1.0):
		_fail("time_scale tertahan setelah hit-stop bertumpuk")

	GameManager.trigger_hit_stop(0.05)
	GameManager.change_state(GameManager.State.PAUSED)
	await _wait(0.2)
	if not get_tree().paused:
		_fail("pause hilang saat hit-stop aktif")
	if not is_equal_approx(Engine.time_scale, 1.0):
		_fail("time_scale tidak kembali 1.0 saat game paused")
	GameManager.change_state(GameManager.State.PLAYING)

	EventBus.player_died.emit()
	if GameManager.state != GameManager.State.GAME_OVER:
		_fail("player_died tidak memindahkan state ke GAME_OVER")
	EventBus.score_updated.disconnect(on_score)

func _has_label_with_text(node: Node, text: String) -> bool:
	var label: Label = node as Label
	if label != null and label.text == text:
		return true
	for child: Node in node.get_children():
		if _has_label_with_text(child, text):
			return true
	return false
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: perintah Task 1 Step 2
Expected: `FAIL: GameManager tidak punya method: change_state` dst., exit code 1.

- [ ] **Step 3: Implementasikan `autoloads/game_manager.gd`**

Ketentuan:
- `_ready()`: `process_mode = Node.PROCESS_MODE_ALWAYS`; sambungkan `enemy_destroyed` dan `player_died`.
- `_process(delta)`: `time_survived += delta` hanya saat `state == State.PLAYING`.
- `change_state()`: set state, `get_tree().paused = (state == State.PAUSED)`, emit `EventBus.game_state_changed.emit(int(state))`.
- `reset_run()`: `score = 0`, `time_survived = 0.0`, `ricochet_kills = 0`, `Engine.time_scale = 1.0`.
- `trigger_hit_stop(duration)`: naikkan nomor urut internal, `Engine.time_scale = 0.05`, restore ke 1.0 lewat `get_tree().create_timer(duration, true, false, true)` hanya bila nomor urut masih yang terbaru.
- Skor: ricochet `base_score * 2` + `ricochet_kills += 1` + `VFXManager.spawn_floating_text(pos, "+%d RICOCHET!" % (base_score * 2))`; direct `+base_score`. Selalu emit `score_updated(score, ricochet_kills)`.
- `player_died` → `change_state(State.GAME_OVER)`.

- [ ] **Step 4: Jalankan, pastikan lulus**

Run: perintah Task 1 Step 2
Expected: `PASS`, exit code 0, tanpa `ERROR`.

---

### Task 4: `AudioManager` (T-008) + bersih-bersih

**Files:**
- Modify: `autoloads/audio_manager.gd`
- Modify: `tests/phase1_check.gd`
- Delete: `tests/phase1_check.gd`, `tests/phase1_check.tscn` (+ `.uid`)

**Interfaces:**
- Produces: `play_cannon() -> void`, `play_ricochet() -> void`, `play_explosion() -> void`, `play_engine(moving: bool) -> void`.

- [ ] **Step 1: Tambah cek audio ke harness**

Tambahkan `await _check_audio()` di `_run_checks()` setelah GameManager, lalu:

```gdscript
func _check_audio() -> void:
	var methods: Array[String] = ["play_cannon", "play_ricochet", "play_explosion", "play_engine"]
	for method_name: String in methods:
		if not AudioManager.has_method(method_name):
			_fail("AudioManager tidak punya method: %s" % method_name)
	if not failures.is_empty():
		return

	AudioManager.play_cannon()
	AudioManager.play_ricochet()
	AudioManager.play_explosion()
	AudioManager.play_engine(true)
	await _wait(0.1)
	AudioManager.play_engine(false)
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: perintah Task 1 Step 2
Expected: `FAIL: AudioManager tidak punya method: play_cannon` dst., exit code 1.

- [ ] **Step 3: Implementasikan `autoloads/audio_manager.gd`**

Ketentuan:
- `process_mode = Node.PROCESS_MODE_ALWAYS`; `MIX_RATE = 22050.0`; pool 8 `AudioStreamPlayer` anak, `AudioStreamGenerator` dengan `buffer_length = 0.2` per suara.
- Waveform dirender sekali di `_ready()` menjadi `PackedVector2Array` mono (sample yang sama di L/R): cannon = noise burst + tone rendah 0.35 s; explosion = noise low-pass 0.8 s; ricochet = sine sweep 2400→900 Hz 0.3 s; engine = loop 1.0 s (sine 55 Hz + 82.5 Hz + noise) dengan fade 0.02 s di kedua ujung.
- `_process()` mem-pump frame ke `AudioStreamGeneratorPlayback` selama `can_push_frame()`; bila playback `null` → lewati tanpa error.
- `play_ricochet()` memakai `pitch_scale` acak 0.9–1.1.
- `play_engine(true)` memulai loop dengan `pitch_scale` 1.15; `play_engine(false)` menghentikan voice engine (idle tidak perlu loop terpisah). Tidak boleh ada error bila engine dipanggil dua kali.
- Tidak boleh ada `push_error`/`printerr` saat asset tidak ada.

- [ ] **Step 4: Jalankan, pastikan lulus**

Run: perintah Task 1 Step 2
Expected: `PASS`, exit code 0, tanpa `ERROR` / `SCRIPT ERROR`.

- [ ] **Step 5: Hapus harness sementara**

Run: `Remove-Item -Recurse -Force tests`
Expected: `tests/` hilang; `--headless --editor --quit` tetap exit 0.
