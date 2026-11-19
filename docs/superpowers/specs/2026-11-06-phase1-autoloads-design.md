# Autoload Core (Phase 1) — Design

Tanggal: 2026-11-06
Status: approved
Scope: TODO Phase 1 (T-005..T-008)

## Intent

Empat autoload adalah tulang punggung komunikasi game: `EventBus` (signal hub),
`GameManager` (state, skor, waktu, hit-stop), `VFXManager` (efek prosedural),
`AudioManager` (SFX prosedural). Phase 2+ hanya boleh bergantung pada API di sini,
bukan pada `get_node()` antar-scene.

## Goals

- `EventBus`: 7 signal bertipe persis seperti TAD §4.1.
- `GameManager`: enum state, skor + multiplier ricochet, `time_survived`, hit-stop,
  sinkronisasi `get_tree().paused`, `reset_run()`.
- `VFXManager`: 4 efek prosedural (muzzle flash, ricochet sparks, tank explosion,
  floating text) tanpa asset, auto-subscribe ke `bullet_ricocheted` dan
  `enemy_destroyed`.
- `AudioManager`: `play_cannon()`, `play_ricochet()`, `play_explosion()`,
  `play_engine(moving)`, sintesis prosedural, tidak error tanpa asset dan tanpa
  audio device.

## Non-Goals

- Gameplay entity, scene arena, HUD, pause menu (Phase 2+).
- BGM (T-037).
- Volume settings, bus routing, positional audio.
- `floating_text.tscn` versi final (T-030).

## Constraints

- Static typing eksplisit di setiap deklarasi.
- Zero asset: semua visual `Polygon2D`/`Line2D`/`CPUParticles2D`, semua audio sintetis.
- Komunikasi antar-sistem hanya lewat `EventBus`.
- Autoload `process_mode = PROCESS_MODE_ALWAYS` agar pause dan hit-stop tetap diproses.
- Tidak boleh ada error saat `assets/` kosong atau audio driver dummy (headless).

## Approaches

**Audio.** Dua cara memenuhi fallback prosedural:

1. `AudioStreamGenerator` dengan waveform pra-render + pump per frame (dipilih).
   Sesuai TAD §4.4 yang menyebut "must use AudioStreamGenerator". Pump hanya
   menyalin sample yang sudah dihitung saat `_ready`, jadi tidak ada sintesis
   per frame.
2. `AudioStreamWAV` pra-render + pool `AudioStreamPlayer`.
   Lebih sederhana dan bebas underrun, tetapi menyimpang dari kata "must" di TAD.

**Floating text.** `VFXManager` memuat `res://scenes/ui/floating_text.tscn` bila ada;
kalau belum (T-030 belum dikerjakan), dibuat `Node2D` + `Label` prosedural dengan
Tween yang sama. Tanpa ini, setiap ricochet kill di Phase 1–6 akan error.

**Parent efek.** `get_tree().current_scene` bila ada, jika tidak `self`, supaya efek
ikut hilang saat arena di-reload (T-034).

## Decisions

| Topik | Keputusan | Alasan |
|---|---|---|
| Urutan task | T-005 → T-007 → T-006 → T-008 | `GameManager` memanggil `VFXManager.spawn_floating_text`; VFX harus ada lebih dulu agar tes ricochet tidak error. |
| Efek suara ricochet | pitch acak 0.9–1.1 | GDD §8.1. |
| Arah spark | searah normal permukaan (menjauhi dinding), spread ±45° | Event hanya membawa normal, bukan velocity. |
| Hit-stop | `Engine.time_scale = 0.05`, restore lewat timer `ignore_time_scale = true`, dijaga sequence agar hit-stop baru tidak dibatalkan timer lama | DoD "time_scale selalu kembali 1.0". |
| GameManager state | `State { MENU, PLAYING, PAUSED, GAME_OVER }`, `change_state()` meng-emit `game_state_changed(int)` | TAD §4.2. |
| Scorch mark | `z_index = -1`, fade setelah beberapa detik | Tidak menutupi tank. |
| Audio tanpa driver | `get_stream_playback()` boleh `null` → return tanpa error | Headless/dummy driver. |

## Definition of Done

- Setiap task punya tes headless yang gagal dulu (RED) lalu lulus (GREEN).
- `godot --headless --path . res://tests/phase1_check.tscn` → `PASS`, exit 0,
  tanpa `ERROR`/`SCRIPT ERROR` di output.
- 4 API `AudioManager` bisa dipanggil tanpa asset dan tanpa audio device.
- `verify`/`tests` sementara dihapus sebelum selesai; tidak ada file di luar §2 +
  `docs/`.

## Review Follow-up (2026-11-06)

Empat temuan Important dari review Phase 1 sudah diperbaiki dan diverifikasi
dengan harness sementara (`tests/phase1_review_check.tscn`, dihapus setelahnya).

**Kontrak `floating_text.tscn` (untuk T-030).** Root harus `Node2D` dan punya
`setup(text: String) -> void`. `VFXManager.spawn_floating_text()` memanggil
`setup()` **setelah** instance di-`add_child` dan diposisikan, jadi `setup()` boleh
membuat `Tween` sendiri (`Node.create_tween()` butuh node di dalam tree). Instance
yang tidak memenuhi kontrak di-`free()` lalu diganti label prosedural.

**One-shot audio.** `AudioStreamGenerator` menyimpan hingga `buffer_length` (0.2 s)
audio yang belum terdengar, sedangkan `_process` menghentikan voice begitu sample
terakhir dimasukkan ke buffer. Karena itu setiap one-shot dirender dengan ekor
senyap `ONE_SHOT_TAIL = 0.25 s` (> `buffer_length`); `stop()` di ujung array hanya
membuang senyap, bukan decay suara. Loop engine tidak diberi ekor.

**Kontrol engine.** `AudioManager.stop_engine()` menghentikan loop, melepas voice
dari `_active`, dan mengosongkan `_engine_player`. Method ini terhubung ke
`EventBus.player_died` dan tersedia untuk T-025/T-034.

**Partikel prosedural.** Semua `CPUParticles2D` memakai `GradientTexture2D` yang
dibuat di `_ready()` (radial lembut untuk asap/api, streak 8×32 untuk sparks) dan
`color_ramp` yang memudarkan alpha ke 0. Sparks memakai
`particle_flag_align_y = true` agar streak mengikuti arah pantulan.
