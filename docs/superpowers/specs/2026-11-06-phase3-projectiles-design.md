# Phase 3 — Projectiles Design (T-014, T-015)

Status: draft for approval.
Scope: `player_bullet.tscn` + `player_bullet.gd`, `enemy_bullet.tscn` + `enemy_bullet.gd`.

## Intent

Peluru adalah inti permainan: peluru pemain memantul sekali dari baja, berubah oranye,
dan membunuh musuh dengan skor 2×; peluru musuh lurus, tidak memantul, dan hanya
melukai player/cover. Phase 3 harus membuat kedua proyektil ini berfungsi penuh
sebelum musuh (Phase 4) dan arena (Phase 6) ada, sehingga tes memakai stub.

## Goals

- `player_bullet.tscn`: `CharacterBody2D` layer 4, mask 2+3, warna `#FFD700`,
  kecepatan 650, pantul tepat 1×, jadi `#FF5500`, hancur pada impact kedua.
- `enemy_bullet.tscn`: `CharacterBody2D` layer 5, mask 1+3, warna `#FF2222`,
  kecepatan dari penembak (400/350), tidak memantul, hancur pada impact apa pun.
- Integrasi tanpa mengubah API Phase 1/2.
- Harness headless sementara; dihapus sebelum selesai.

## Non-goals

- Musuh, sandbag, bunker, arena (Phase 4–6). Tes memakai stub.
- Efek visual baru; memakai `VFXManager` yang ada.
- Audio nyata; headless memakai dummy driver.

## Approaches

1. **`move_and_collide` per physics step (dipilih).** Sesuai TAD §5.2, deterministik,
   memberi `KinematicCollision2D` (normal + posisi) langsung. Kekurangan: bisa
   "nyangkut" bila spawn menempel di dinding; dimitigasi dengan posisi spawn di muzzle.
2. **`Area2D` + `body_entered`.** Lebih mudah untuk hitbox, tetapi tidak memberi
   normal pantulan tanpa `CollisionPolygon2D` tambahan dan tidak sesuai TAD.
3. **Raycast manual.** Paling terkontrol untuk tunneling, tetapi menduplikasi fisika
   Godot dan menyimpang dari TAD.

TAD menetapkan opsi 1; opsi 2/3 tidak dipakai.

## Contracts

### `player_bullet.gd`

```gdscript
class_name PlayerBullet
extends CharacterBody2D

const SPEED: float = 650.0
const MAX_BOUNCES: int = 1
const OFFSCREEN_MARGIN: float = 256.0

var direction: Vector2 = Vector2.RIGHT
var bounce_count: int = 0
var is_ricochet: bool = false
```

- `_ready()`: bila `direction` nol → `Vector2.RIGHT`; `velocity = direction.normalized() * SPEED`;
  `rotation = velocity.angle()`. Pemain mengisi `direction` **sebelum** `add_child`
  (kontrak Phase 2).
- `_physics_process(delta)`: `move_and_collide(velocity * delta)`.
- Urutan penanganan collider (mengikuti TAD):
  1. `has_method("take_damage")` → `collider.call("take_damage", 1, is_ricochet)`, lalu `queue_free()`.
  2. `is_in_group("bouncy_surface")`:
     - `bounce_count < MAX_BOUNCES` → `bounce_count += 1`, `is_ricochet = true`,
       `velocity = velocity.bounce(normal)`, `rotation = velocity.angle()`,
       `visual.color = #FF5500`, `EventBus.bullet_ricocheted.emit(pos, normal)`,
       `AudioManager.play_ricochet()`. **Tidak** memanggil `spawn_ricochet_sparks`
       (VFXManager sudah subscribe sinyal itu; memanggil lagi = sparks ganda).
     - sudah maksimum → `VFXManager.spawn_ricochet_sparks(pos, normal)` lalu `queue_free()`.
  3. Selain itu → `queue_free()`.
- Setelah gerak, bila di luar viewport yang di-`grow(256)` → `queue_free()`.
- Player tidak terkena: layer player (1) tidak ada di mask peluru (2+3). Tidak perlu
  pengecekan grup tambahan; tes membuktikannya.
- `Visual` (`Polygon2D`) bentuk peluru 12×4 menghadap +X, warna `#FFD700`, `z_index = 20`
  pada root.

### `enemy_bullet.gd`

```gdscript
class_name EnemyBullet
extends CharacterBody2D

const DEFAULT_SPEED: float = 400.0
const OFFSCREEN_MARGIN: float = 256.0

var direction: Vector2 = Vector2.RIGHT
var speed: float = DEFAULT_SPEED
```

- `_ready()`: fallback `direction` nol → kanan; `velocity = direction.normalized() * speed`;
  `rotation = velocity.angle()`. Penembak (Phase 4) mengisi `direction` dan `speed`
  sebelum `add_child`.
- `_physics_process(delta)`: `move_and_collide(velocity * delta)`.
- Collider dengan `take_damage` → `collider.call("take_damage", 1, false)` lalu
  `queue_free()`. Collider lain (dinding) → `queue_free()`. Tidak pernah memantul.
- Off-screen cleanup sama.
- Visual 10×4 menghadap +X, warna `#FF2222`, `z_index = 20`.

### Integrasi Phase 2

`player.gd:_spawn_bullet()` sudah memakai path yang sama, mengisi `direction` sebelum
`add_child`, dan mengeset posisi/rotasi setelah masuk tree. Setelah scene ini ada,
pemain otomatis menembakkan peluru nyata tanpa perubahan kode player.

## Scene contracts

`player_bullet.tscn`:
- root `PlayerBullet` (`CharacterBody2D`, `collision_layer = 8`, `collision_mask = 6`,
  `motion_mode = MOTION_MODE_FLOATING`, `z_index = 20`, script).
- `CollisionShape2D` → `CircleShape2D` radius 4.
- `Visual` (`Polygon2D`) warna `#FFD700`, polygon `(-6,-2),(6,-2),(8,0),(6,2),(-6,2),(-8,0)`.

`enemy_bullet.tscn`:
- root `EnemyBullet` (`CharacterBody2D`, layer 16, mask 5, FLOATING, `z_index = 20`, script).
- `CollisionShape2D` → `CircleShape2D` radius 4.
- `Visual` (`Polygon2D`) warna `#FF2222`, polygon `(-5,-2),(5,-2),(6,0),(5,2),(-5,2),(-6,0)`.

## Tests (temporary harness, deleted before finishing)

Stub di harness: dinding `StaticBody2D` layer 3 grup `bouncy_surface`; musuh palsu layer 2
dengan `take_damage`; cover palsu layer 3 dengan `take_damage`; player asli.

Player bullet:
1. `direction` sebelum `add_child` → velocity 650, rotasi sesuai.
2. Pantul 1× dari dinding → `bounce_count == 1`, `is_ricochet == true`, velocity
   berbalik, warna `#FF5500`, `bullet_ricocheted` ter-emit sekali, peluru masih hidup.
3. Impact kedua pada dinding → peluru `queue_free`; sparks muncul; sinyal tidak
   ter-emit lagi.
4. Musuh kena → `take_damage(1, false)`, peluru hilang.
5. Musuh kena setelah pantulan → `take_damage(1, true)`.
6. Player ditembak lurus → HP tidak berubah (peluru melewati player).
7. Peluru jauh di luar layar → hilang.

Enemy bullet:
1. `speed = 350` sebelum `add_child` → velocity 350.
2. Kena player → HP 3→2, peluru hilang.
3. Kena dinding → peluru hilang, tanpa damage.
4. Kena cover palsu → `take_damage(1, false)`, peluru hilang.
5. Jauh di luar layar → hilang.

## Risks

- **Spawn menempel dinding** → pantulan instan; diterima, muzzle berada di luar hull.
- **Tunneling** pada 650 px/s: 10.8 px/frame, radius 4, dinding tebal ≥ 20 px di arena
  Phase 6 → aman.
- **Sparks ganda** → dicegah dengan tidak memanggil VFX pada bounce sukses.
- **`current_scene` bukan identitas** saat F6 → peluru memakai koordinat world; arena
  Phase 6 ada di origin. Sama seperti catatan Phase 2 (T-024).
- **Headless viewport** 1280×720; margin 256 cukup untuk tes off-screen.

## Definition of Done

- Kedua scene load tanpa error; layer/mask/warna/kecepatan sesuai.
- Pantulan tepat 1×, oranye, hancur pada impact kedua; tidak melukai player.
- Peluru musuh hancur oleh dinding dan mengurangi 1 HP player.
- Harness `PASS` exit 0; `--headless --editor --quit` exit 0; harness dihapus.
- T-014/T-015 `[x]`, ledger + PROGRESS LOG diperbarui.
