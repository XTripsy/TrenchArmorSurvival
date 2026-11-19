# Project Setup (Phase 0) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menyiapkan `project.godot` dan struktur folder *Trench Armor Survival* untuk Godot 4.7.2.stable.steam, lengkap dengan input map, nama physics layer, dan 4 autoload stub.

**Architecture:** Konfigurasi ditulis langsung di `project.godot` (config_version 5, format 4.7), lalu diverifikasi oleh satu script headless `verify_setup.gd` yang memeriksa `ProjectSettings`, `InputMap`, dan keberadaan folder. Script verifikasi itu sementara dan dihapus di Task 4.

**Tech Stack:** Godot 4.7.2 (GDScript 2.0), tanpa asset eksternal.

**Spec:** `docs/superpowers/specs/2026-11-06-project-setup-design.md`

## Global Constraints

- Engine: `4.7.2.stable.steam.ed1daf0bf` di `D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`.
- `config_version=5`; `config/features=PackedStringArray("4.7", "Forward Plus")`.
- Viewport 1280x720, stretch `canvas_items`, aspect `keep`, physics 60 Hz.
- Zero-asset: tidak ada file gambar/audio/biner.
- Tidak membuat file di luar struktur TODO §2, kecuali `project.godot` dan `docs/`.
- GDScript memakai static typing eksplisit.
- Folder ini **bukan git repo** → tidak ada langkah commit; setiap task diakhiri validasi. `git init` hanya jika diminta.

## Review Focus

- Sebuah action input kehilangan salah satu key (mis. arrow key hilang) → pemain hanya bisa WASD; diverifikasi di Task 2.
- Nama autoload di `[autoload]` beda dengan nama file → `EventBus` undefined saat Phase 1; diverifikasi di Task 4.
- Renderer di `project.godot` tidak konsisten dengan tag `config/features` → editor menulis ulang file; diverifikasi di Task 1.
- `stretch/aspect` salah (`expand` bukan `keep`) → letterboxing/rasio berubah; diverifikasi di Task 1.
- Folder §2 tidak lengkap → file Phase 1 dibuat di tempat salah; diverifikasi di Task 1.

---

### Task 1: `project.godot` + struktur folder (T-001)

**Files:**
- Create: `project.godot`
- Create (folder): `autoloads/`, `scenes/{player,projectiles,enemies,environment,ui}/`, `scripts/{arena,player,projectiles,enemies,environment,ui}/`
- Create (sementara): `verify_setup.gd`

**Interfaces:**
- Produces: `project.godot` dengan section `[application]`, `[display]`, `[physics]`, `[rendering]`; `verify_setup.gd` dengan fungsi `_require(failures: PackedStringArray, key: String, expected: Variant) -> void` dan `_finish(failures: PackedStringArray) -> void`.

- [ ] **Step 1: Tulis script verifikasi (yang gagal)**

Buat `verify_setup.gd` di root proyek:

```gdscript
extends SceneTree

const EXPECTED_FOLDERS: PackedStringArray = PackedStringArray([
	"res://autoloads",
	"res://scenes/player",
	"res://scenes/projectiles",
	"res://scenes/enemies",
	"res://scenes/environment",
	"res://scenes/ui",
	"res://scripts/arena",
	"res://scripts/player",
	"res://scripts/projectiles",
	"res://scripts/enemies",
	"res://scripts/environment",
	"res://scripts/ui",
])

func _init() -> void:
	var failures: PackedStringArray = PackedStringArray()

	for folder: String in EXPECTED_FOLDERS:
		if not DirAccess.dir_exists_absolute(folder):
			failures.append("folder tidak ada: %s" % folder)

	_require(failures, "application/config/name", "Trench Armor Survival")
	_require(failures, "display/window/size/viewport_width", 1280)
	_require(failures, "display/window/size/viewport_height", 720)
	_require(failures, "display/window/stretch/mode", "canvas_items")
	_require(failures, "display/window/stretch/aspect", "keep")
	_require(failures, "physics/common/physics_ticks_per_second", 60)
	_require(failures, "rendering/renderer/rendering_method", "forward_plus")
	_finish(failures)

func _require(failures: PackedStringArray, key: String, expected: Variant) -> void:
	var actual: Variant = ProjectSettings.get_setting(key)
	if actual != expected:
		failures.append("%s: harus %s, dapat %s" % [key, str(expected), str(actual)])

func _finish(failures: PackedStringArray) -> void:
	if failures.is_empty():
		print("PASS")
		quit(0)
	else:
		for failure: String in failures:
			printerr("FAIL: " + failure)
		quit(1)
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `& "D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --script res://verify_setup.gd`
Expected: exit code ≠ 0 (belum ada `project.godot`).

- [ ] **Step 3: Buat folder dan `project.godot`**

Buat semua folder dari `EXPECTED_FOLDERS`. Isi `project.godot`:

```ini
; Engine configuration file.
; It's best edited using the editor UI and not directly,
; since the parameters that go here are not all obvious.

config_version=5

[application]

config/name="Trench Armor Survival"
config/features=PackedStringArray("4.7", "Forward Plus")

[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"

[physics]

common/physics_ticks_per_second=60

[rendering]

renderer/rendering_method="forward_plus"
environment/defaults/default_clear_color=Color(0.290196, 0.231373, 0.196078, 1)
```

- [ ] **Step 4: Jalankan verifikasi, pastikan lulus**

Run: perintah Step 2
Expected: `PASS`, exit code 0.

- [ ] **Step 5: Smoke test editor**

Run: `& "D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --editor --quit`
Expected: selesai tanpa `SCRIPT ERROR` / `Parse Error`; folder `.godot/` terbentuk.

---

### Task 2: Input map (T-002)

**Files:**
- Modify: `project.godot` (tambah section `[input]`)
- Modify: `verify_setup.gd`

**Interfaces:**
- Produces: 6 action `move_up`, `move_down`, `move_left`, `move_right`, `shoot`, `pause`.

- [ ] **Step 1: Tambah cek input ke `verify_setup.gd`**

Tambahkan sebelum `_finish(failures)` di `_init()`:

```gdscript
	_require_key(failures, "move_up", KEY_W)
	_require_key(failures, "move_up", KEY_UP)
	_require_key(failures, "move_down", KEY_S)
	_require_key(failures, "move_down", KEY_DOWN)
	_require_key(failures, "move_left", KEY_A)
	_require_key(failures, "move_left", KEY_LEFT)
	_require_key(failures, "move_right", KEY_D)
	_require_key(failures, "move_right", KEY_RIGHT)
	_require_key(failures, "pause", KEY_ESCAPE)
	_require_mouse(failures, "shoot", MOUSE_BUTTON_LEFT)
```

Dan dua helper:

```gdscript
func _require_key(failures: PackedStringArray, action: StringName, key: Key) -> void:
	if not InputMap.has_action(action):
		failures.append("action tidak ada: %s" % action)
		return
	for event: InputEvent in InputMap.action_get_events(action):
		var key_event: InputEventKey = event as InputEventKey
		if key_event != null and key_event.physical_keycode == key:
			return
	failures.append("action %s tidak punya key %s" % [action, OS.get_keycode_string(key)])

func _require_mouse(failures: PackedStringArray, action: StringName, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		failures.append("action tidak ada: %s" % action)
		return
	for event: InputEvent in InputMap.action_get_events(action):
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event != null and mouse_event.button_index == button:
			return
	failures.append("action %s tidak punya mouse button %d" % [action, button])
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: perintah verifikasi Task 1 Step 2
Expected: `FAIL: action tidak ada: move_up` dst., exit code 1.

- [ ] **Step 3: Tambah `[input]` ke `project.godot`**

Tambahkan section berikut (keycode: W=87, A=65, S=83, D=68, Left=4194319, Up=4194320, Right=4194321, Down=4194322, Esc=4194305):

```ini
[input]

move_up={
"deadzone": 0.2,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":87,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194320,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_down={
"deadzone": 0.2,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194322,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_left={
"deadzone": 0.2,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194319,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_right={
"deadzone": 0.2,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194321,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
shoot={
"deadzone": 0.2,
"events": [Object(InputEventMouseButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"button_mask":0,"position":Vector2(0, 0),"global_position":Vector2(0, 0),"factor":1.0,"button_index":1,"canceled":false,"pressed":false,"double_click":false,"script":null)
]
}
pause={
"deadzone": 0.2,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194305,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
```

- [ ] **Step 4: Jalankan verifikasi, pastikan lulus**

Run: perintah verifikasi Task 1 Step 2
Expected: `PASS`, exit code 0. Jika ada `Object(...)` yang tidak dikenal, engine mencetak error dan action hilang → perbaiki properti yang dilaporkan.

---

### Task 3: Nama physics layer (T-003)

**Files:**
- Modify: `project.godot` (tambah section `[layer_names]`)
- Modify: `verify_setup.gd`

**Interfaces:**
- Produces: setting `layer_names/2d_physics/layer_1` … `layer_6` dengan nilai Player, Enemy, Environment, PlayerBullet, EnemyBullet, TerrainHazard.

- [ ] **Step 1: Tambah cek layer ke `verify_setup.gd`**

Tambahkan sebelum `_finish(failures)`:

```gdscript
	_require(failures, "layer_names/2d_physics/layer_1", "Player")
	_require(failures, "layer_names/2d_physics/layer_2", "Enemy")
	_require(failures, "layer_names/2d_physics/layer_3", "Environment")
	_require(failures, "layer_names/2d_physics/layer_4", "PlayerBullet")
	_require(failures, "layer_names/2d_physics/layer_5", "EnemyBullet")
	_require(failures, "layer_names/2d_physics/layer_6", "TerrainHazard")
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: perintah verifikasi Task 1 Step 2
Expected: 6 baris `FAIL: layer_names/...: harus ..., dapat <null>`.

- [ ] **Step 3: Tambah `[layer_names]` ke `project.godot`**

```ini
[layer_names]

2d_physics/layer_1="Player"
2d_physics/layer_2="Enemy"
2d_physics/layer_3="Environment"
2d_physics/layer_4="PlayerBullet"
2d_physics/layer_5="EnemyBullet"
2d_physics/layer_6="TerrainHazard"
```

- [ ] **Step 4: Jalankan verifikasi, pastikan lulus**

Run: perintah verifikasi Task 1 Step 2
Expected: `PASS`, exit code 0.

---

### Task 4: Autoload stub (T-004)

**Files:**
- Create: `autoloads/event_bus.gd`, `autoloads/game_manager.gd`, `autoloads/vfx_manager.gd`, `autoloads/audio_manager.gd`
- Modify: `project.godot` (tambah section `[autoload]`)
- Modify: `verify_setup.gd`
- Delete: `verify_setup.gd` (setelah lulus)

**Interfaces:**
- Produces: singleton global `EventBus`, `GameManager`, `VFXManager`, `AudioManager` (masing-masing `extends Node`, isi menyusul di Phase 1).

- [ ] **Step 1: Tambah cek autoload ke `verify_setup.gd`**

Tambahkan sebelum `_finish(failures)`:

```gdscript
	for autoload_name: String in ["EventBus", "GameManager", "VFXManager", "AudioManager"]:
		var raw: Variant = ProjectSettings.get_setting("autoload/" + autoload_name)
		var path: String = ""
		if raw is String:
			path = (raw as String).trim_prefix("*")
		if not path.ends_with(".gd"):
			failures.append("autoload %s tidak terdaftar" % autoload_name)
		elif not ResourceLoader.exists(path):
			failures.append("autoload %s menunjuk file hilang: %s" % [autoload_name, path])
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: perintah verifikasi Task 1 Step 2
Expected: 4 baris `FAIL: autoload ... tidak terdaftar`.

- [ ] **Step 3: Buat 4 stub dan daftarkan**

Tiap file (`event_bus.gd`, `game_manager.gd`, `vfx_manager.gd`, `audio_manager.gd`) berisi tepat dua baris:

```gdscript
extends Node
```

Tambahkan ke `project.godot`:

```ini
[autoload]

EventBus="*res://autoloads/event_bus.gd"
GameManager="*res://autoloads/game_manager.gd"
VFXManager="*res://autoloads/vfx_manager.gd"
AudioManager="*res://autoloads/audio_manager.gd"
```

- [ ] **Step 4: Jalankan verifikasi, pastikan lulus**

Run: perintah verifikasi Task 1 Step 2
Expected: `PASS`, exit code 0.

- [ ] **Step 5: Smoke test editor (parse semua script termasuk autoload)**

Run: `& "D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --editor --quit`
Expected: tanpa `SCRIPT ERROR` / `Parse Error`.

- [ ] **Step 6: Hapus script verifikasi sementara**

Run: `Remove-Item verify_setup.gd`
Expected: file hilang; `--editor --quit` tetap bersih.
