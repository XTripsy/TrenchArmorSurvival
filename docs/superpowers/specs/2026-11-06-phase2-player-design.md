# Player Tank (Phase 2) — Design

Tanggal: 2026-11-06
Status: approved
Scope: TODO Phase 2 (T-009..T-013)

## Intent

Menghadirkan tank pemain yang terasa berat dan presisi: bodi bergerak 8 arah dan
berputar halus mengikuti arah gerak, turet mengikuti kursor tanpa delay, tembakan
memberi recoil yang terasa, dan kerusakan terasa lewat hit-stop, shake, kilat putih,
serta i-frames. Semua visual prosedural (tanpa asset) dan semua komunikasi lintas
sistem lewat `EventBus` atau API autoload Phase 1.

Phase 2 belum membuat peluru (T-014 milik Phase 3), arena (Phase 6), atau HUD
(Phase 7). Player harus tetap berfungsi penuh tanpa file-file itu.

## Goals

- `player.tscn` dengan hierarki, layer/mask, dan ukuran hitbox persis §2/TAD §5.1.
- Gerak 8 arah `BASE_SPEED * speed_multiplier`, rotasi bodi halus hanya saat bergerak.
- Turet mengikuti kursor; tembakan dibatasi `FIRE_COOLDOWN`.
- Recoil terasa (impulse + animasi barrel + shake + flash + audio).
- Damage + i-frames 1.2 s tanpa damage ganda, kilat putih 0.1 s.
- Jejak roda berpasangan, hanya saat bergerak, memudar dan hilang setelah 3 s.
- Semua API yang dibutuhkan Phase 3+ stabil: `take_damage()`, `speed_multiplier`,
  grup `"player"`, dan titik spawn peluru.

## Non-Goals

- Peluru, ricochet, damage ke enemy (Phase 3).
- Arena, dinding, `MudCrater` yang mengubah `speed_multiplier` (Phase 5–6).
- HUD, pause menu, game over menu (Phase 7).
- Crosshair kustom (GDD §3.1) — kursor sistem tetap dipakai; crosshair masuk polish UI.
- Animasi sprite/karakter.

## Constraints

- Static typing eksplisit di setiap deklarasi.
- Zero asset: `Polygon2D`/`Line2D`/`CPUParticles2D`/`Marker2D` saja.
- Komunikasi lintas sistem hanya lewat `EventBus`; panggilan autoload Phase 1 diizinkan
  (`VFXManager`, `AudioManager`, `GameManager`).
- Scene tidak menyalakan `process_mode = ALWAYS`; player ikut pause dan hit-stop.
- Tidak boleh error bila `res://scenes/projectiles/player_bullet.tscn` belum ada.

## Approaches

**1. Dependensi peluru (Phase 3 belum ada).**
- *Stub `player_bullet.tscn` sekarang* — melanggar urutan fase dan §2.
- *Guard `ResourceLoader.exists()` lalu spawn bila ada* (dipilih). Menembak tetap
  memproses cooldown, recoil, audio, flash, dan shake; peluru otomatis muncul saat
  T-014 selesai. Pola yang sama sudah dipakai `VFXManager` untuk `floating_text.tscn`.

**2. Representasi jejak roda.**
- *Satu `Line2D` panjang per track yang ditambah titik tiap tick* — hemat node, tetapi
  seluruh jejak 3 detik lenyap sekaligus (fade per potongan tidak mungkin).
- *Spawn satu `tread_mark.tscn` (root `Line2D`) per track tiap tick, 2 titik per
  instance* (dipilih). Tiap potongan memudar sendiri; sesuai TAD yang menyebut
  `tread_mark.tscn` sebagai `Line2D`; 2 instance/tick = 2 garis berpasangan.
- *Root `Node2D` + 2 `Line2D` per tick* — satu node lebih sedikit, tetapi menyimpang
  dari bentuk scene yang diminta.

**3. Recoil yang bertahan.**
- *Set `velocity` sekali* — `_physics_process` berikutnya menimpanya dengan input,
  recoil praktis tidak terasa.
- *`_recoil_velocity` terpisah yang meluruh* (dipilih). Impulse `-aim * 200` disimpan,
  ditambahkan ke velocity, lalu `move_toward(ZERO, RECOIL_DECAY * delta)`. Total
  dorongan ±22 px, cukup terasa tanpa mengacaukan kontrol.

**4. Kondisi mati.**
- *`queue_free()` root* — referensi untuk HUD/Phase 3+ hilang dan `player_died` bisa
  terpicu sebelum node selesai diproses.
- *Sembunyikan visual + matikan collision + `_alive = false`* (dipilih). Node tetap ada
  untuk dibaca UI/arena; `EventBus.player_died` tetap satu-satunya sinyal game over.

## Design

### Scene `scenes/player/player.tscn` (T-009)

```text
Player (CharacterBody2D)          group "player", layer 1, mask 2|3|5|6 (=54)
├── CollisionShape2D              RectangleShape2D 36x36
├── HullVisual (Node2D)           rotation mengikuti arah gerak
│   ├── HullBody (Polygon2D)      #556B2F
│   ├── TrackLeft (Polygon2D)     #2E241E
│   └── TrackRight (Polygon2D)    #2E241E
├── TurretPivot (Node2D)          look_at(kursor)
│   ├── TurretVisual (Polygon2D)  barrel + #3B4A20
│   │   └── Star (Polygon2D)      bintang 5 sudut, putih
│   └── MuzzleMarker (Marker2D)   ujung barrel (≈ (22, 0))
└── TreadTimer (Timer)            wait_time 0.05, autostart
```

- `position = Vector2(640, 360)` diset di scene (arena boleh menimpa saat spawn).
- `motion_mode = MOTION_MODE_FLOATING` (top-down; mode default `GROUNDED` akan
  menerapkan logika lantai dan mengganggu gerak sumbu Y).
- Turet digambar menghadap +X agar `look_at()` langsung benar.
- Tidak ada script di `player.tscn` selain `player.gd` pada root.

### `scripts/player/player.gd` (T-010..T-013)

**Konstanta & state**

```gdscript
const MAX_HP: int = 3
const BASE_SPEED: float = 220.0
const TURN_SPEED: float = 10.0
const FIRE_COOLDOWN: float = 0.45
const RECOIL_FORCE: float = 40.0
const RECOIL_DECAY: float = 900.0
const IFRAME_DURATION: float = 1.2
const HIT_FLASH_DURATION: float = 0.1
const TREAD_FADE: float = 3.0
const BULLET_SCENE: String = "res://scenes/projectiles/player_bullet.tscn"

var hp: int = MAX_HP
var speed_multiplier: float = 1.0
var is_invulnerable: bool = false
var _alive: bool = true
var _fire_cooldown_left: float = 0.0
var _recoil_velocity: Vector2 = Vector2.ZERO
var _last_left_track: Vector2
var _last_right_track: Vector2
var _had_track_anchor: bool = false
var _engine_moving: bool = false
var _iframe_tween: Tween = null
var _recoil_tween: Tween = null
```

`_ready()`: `hp = MAX_HP`, lalu `AudioManager.play_engine(false)` sekali agar idle
rumble langsung terdengar (di headless ini aman, hanya menghasilkan null playback).

**`_physics_process(delta)`**
1. `if not _alive: return`.
2. `var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")`.
3. `velocity = input_vector * BASE_SPEED * speed_multiplier + _recoil_velocity`.
4. `_recoil_velocity = _recoil_velocity.move_toward(Vector2.ZERO, RECOIL_DECAY * delta)`.
5. `move_and_slide()`.
6. `var has_input := input_vector.length_squared() > 0.0`. **Rotasi hull, jejak roda, dan
   status audio memakai `has_input`, bukan panjang `velocity`** — kalau memakai
   velocity, recoil akan memutar hull ke belakang dan mencetak jejak palsu.
7. Bila has_input: `hull_visual.rotation = lerp_angle(hull_visual.rotation, input_vector.angle(), TURN_SPEED * delta)`.
8. `turret_pivot.look_at(get_global_mouse_position())`.
9. `_fire_cooldown_left = maxf(0.0, _fire_cooldown_left - delta)`.
10. `if Input.is_action_pressed("shoot") and _fire_cooldown_left <= 0.0: _fire()`.
11. Bila `has_input != _engine_moving`: `_engine_moving = has_input` dan
    `AudioManager.play_engine(_engine_moving)`. Hanya saat berubah, supaya tidak
    mengalokasikan generator tiap frame di kondisi tanpa audio device.
12. Saat transisi diam→bergerak, set `_last_left_track`/`_last_right_track` ke posisi
    track saat ini supaya tidak ada garis panjang dari posisi lama (lihat T-013).

**`_fire()`**
- `_fire_cooldown_left = FIRE_COOLDOWN`.
- `var aim: Vector2 = Vector2.RIGHT.rotated(turret_pivot.global_rotation)` (selalu
  unit vector; tidak perlu guard nol).
- `_recoil_velocity -= aim * RECOIL_FORCE * 5.0`.
- `VFXManager.spawn_muzzle_flash(muzzle_marker.global_position, aim.angle())`.
- `AudioManager.play_cannon()`.
- `EventBus.camera_shake_requested.emit(2.0, 0.1)`.
- Recoil tween: hentikan tween lama bila masih valid, simpan `base_x`, lalu
  `position.x` ke `base_x - 6.0` dalam 0.05 s dan kembali dalam 0.12 s.
- Peluru: hanya bila `ResourceLoader.exists(BULLET_SCENE)`. **Urutan wajib:** isi
  `bullet.set("direction", aim)` **sebelum** `add_child()` (properti ada dicek lewat
  `bullet.get("direction") != null`), baru `parent.add_child(bullet)`, lalu set
  `global_position = muzzle_marker.global_position` dan `rotation = aim.angle()`.
  `_ready()` anak berjalan sinkron di dalam `add_child()`, jadi T-014 boleh menghitung
  `velocity = direction * SPEED` di `_ready()` tanpa melihat `Vector2.ZERO`. Parent =
  `get_tree().current_scene` (fallback `get_parent()`). Memakai `get()`/`set()` supaya
  properti yang belum ada tidak memicu error.

**`take_damage(amount: int, _is_ricochet: bool = false) -> void`**
- Abaikan bila `not _alive` atau `is_invulnerable`.
- `hp = maxi(0, hp - amount)`; `EventBus.player_damaged.emit(hp, MAX_HP)`.
- `EventBus.camera_shake_requested.emit(12.0, 0.35)`;
  `GameManager.trigger_hit_stop(0.05)`.
- Kilat putih: `hull_visual.modulate` dan `turret_visual.modulate` ke
  `Color(10, 10, 10, 1)` (di-clamp menjadi putih tanpa HDR 2D) lalu kembali
  `Color.WHITE` setelah 0.1 s.
- `hp <= 0` → `_die()`; selain itu `_start_iframes()`.

**`_start_iframes()`**
- `is_invulnerable = true`.
- Kedip pada `self.modulate.a` (bukan visual) agar tidak bentrok dengan kilat putih:
  6 siklus 0.1 s turun ke 0.25 dan naik, total 1.2 s; callback mengembalikan
  `modulate.a = 1.0` dan `is_invulnerable = false`.
- Tween disimpan di `_iframe_tween`; bila damage baru datang setelah i-frame habis,
  tween lama tidak boleh mengubah state (dibuat ulang).

**`_die()`**
- `_alive = false`; `is_invulnerable = true`; hentikan kedua tween dan kembalikan
  `modulate`/`modulate.a`.
- `EventBus.player_died.emit()` (GameManager → GAME_OVER; AudioManager → `stop_engine`).
- `VFXManager.spawn_tank_explosion(global_position)`.
- Sembunyikan `hull_visual` dan `turret_pivot`; `collision_shape.set_deferred("disabled", true)`;
  `tread_timer.stop()`.
- Node root tetap ada; tidak `queue_free()`.

**Jejak roda (T-013)**
- `TreadTimer.timeout` → bila `_alive` dan bergerak:
  - hitung posisi dunia track kiri/kanan dari `hull_visual.global_transform *
    Vector2(-4.0, ±13.0)`;
  - spawn 2 instance `tread_mark.tscn` ke `get_tree().current_scene` (fallback
    `get_parent()`), masing-masing `points = [sebelumnya, sekarang]`;
  - simpan posisi sekarang sebagai "sebelumnya";
  - fade `modulate:a → 0` selama 3 s lalu `queue_free`.
- `tread_mark.tscn`: root `Line2D`, `width = 5.0`, `default_color = #2E241E`,
  `z_index = -2`, `antialiased = true`.
- Bila tidak bergerak, timer tetap jalan tetapi tidak men-spawn; posisi "sebelumnya"
  di-reset saat mulai bergerak lagi (`_had_track_anchor = false`).
- Tween fade dibuat pada node mark setelah masuk tree
  (`mark.create_tween()`), bukan pada player, agar tiap potongan memudar mandiri.

### Z-order contract (menutup Minor #7 Phase 1)

| Band | Isi |
|---|---|
| -2 | Jejak roda |
| -1 | Scorch mark |
| 0 | Player, enemy, environment |
| 5–10 | Debris, smoke, fire |
| 15 | Ricochet sparks |
| 20 | Bullet, muzzle flash |
| 30 | Floating text / UI world-space |

T-038 wajib memakai kontrak ini; asap tidak boleh menutupi peluru.

## Risks & Mitigations

- **Node jejak roda menumpuk**: 2 node/tick, umur 3 s, 20 tick/s → maksimum ~120 node
  saat bergerak terus. Dapat diterima untuk MVP; T-040 mengevaluasi pooling bila perlu.
- **Tween recoil bertumpuk** saat menembak cepat: tween lama di-`kill()` sebelum yang
  baru, sehingga barrel tidak "nyangkut" di posisi mundur.
- **I-frame + hit flash** memakai properti berbeda (root `modulate.a` vs visual
  `modulate`), jadi tidak saling menimpa.
- **Mouse di posisi tank** → `turret_pivot.look_at()` dengan vektor nol adalah no-op,
  jadi turet mempertahankan sudut terakhir (bukan reset ke kanan). Tidak ada NaN;
  `_fire()` tetap memakai `Vector2.RIGHT.rotated(global_rotation)` yang selalu unit.
- **`player_bullet.tscn` belum ada** → guard `ResourceLoader.exists()`, tidak error.
- **Pause/hit-stop** → player tidak `PROCESS_MODE_ALWAYS`; pause benar-benar
  menghentikan timer/tween. Hit-stop hanya memperlambat (`Engine.time_scale = 0.05`
  selama 0.05 s), bukan menghentikan.

## Definition of Done

- `player.tscn` load tanpa error; hierarki, group, layer 1, mask 54, hitbox 36×36,
  `TreadTimer` 0.05 sesuai.
- Gerak 8 arah, rotasi hull halus hanya saat bergerak, turet menghadap kursor.
- Tidak bisa menembak lebih cepat dari 0.45 s; recoil terasa dan kembali normal.
- Damage kedua saat i-frame diabaikan; HP 0 → `player_died`, explosion, visual hilang.
- Jejak roda muncul hanya saat bergerak dan habis setelah 3 s.
- Harness headless sementara: `PASS`, exit 0, tanpa `ERROR`; harness dihapus.
- `--headless --editor --quit` exit 0.
