# TODO.md — Trench Armor Survival (Godot 4.2+, GDScript)

> This document is **self-contained**: all important numeric values are specified in each task.
> Read the GDD/TAD only when an ambiguity needs clarification (references: `TAD §x`, `GDD §x`).
> If documents conflict, **TAD takes precedence** (see "Decisions & Notes").

---

## 0. AGENT PROTOCOL (MUST READ)

1. Work through tasks **sequentially** by phase. Do not skip a phase unless its `Depends` requirements are met.
2. One task = one commit. Format: `feat(scope): T-xxx short description` (Conventional Commits).
3. After completing a task, change `[ ]` to `[x]`. Do not delete tasks.
4. Do not create files outside the structure in **§2**. (The optional `assets/` folder is allowed for audio/images.)
5. **Strict static typing** is mandatory: every `var`, parameter, and return type must have an explicit type.
6. **Zero-asset requirement:** create all visuals using `Polygon2D` / `Line2D` / `CPUParticles2D`. Use `AudioStreamGenerator` as the fallback for all audio. The game must be playable without external assets.
7. Cross-system communication must happen **only through `EventBus`**. Avoid fragile paths such as `get_node("../..")`.
8. Every task has a DoD (Definition of Done). A task is not complete until its DoD is satisfied.
9. Validate each phase (if the Godot CLI is available): `godot --headless --quit` → there must be no parse errors or typing warnings.
10. If uncertain, document the assumption in `NOTES.md` (do not repeatedly ask questions), then continue with the task.

---

## PROGRESS LOG

**Snapshot:** 2026-11-09 · Engine `4.7.2.stable.steam.ed1daf0bf` · **Next: Phase 9 (T-039..T-041)**

| Phase | Tasks | Status | Bukti |
|---|---|---|---|
| 0 — Project Setup | T-001..T-004 | ✅ Selesai | `project.godot` valid; autoloads terdaftar; `--headless --editor --quit` exit 0 |
| 1 — Autoload Core | T-005..T-008 | ✅ Selesai + review fixed | Harness headless `PASS` exit 0 (2×); `--headless --editor --quit` exit 0 |
| 2 — Player | T-009..T-013 | ✅ Selesai + review fixed | Harness headless `PASS` exit 0 (3×); `--headless --editor --quit` exit 0 |
| 3 — Projectiles | T-014..T-015 | ✅ Selesai (menunggu review) | Harness headless `PASS` exit 0 (3×); `--headless --editor --quit` exit 0 |
| 4 — Enemies | T-016..T-020 | ✅ Selesai + terverifikasi (belum review terpisah) | Harness headless `PASS` 50/50 exit 0; `--headless --editor --quit` exit 0 |
| 5 — Environment | T-021..T-023 | ✅ Selesai + terverifikasi (belum review terpisah) | Harness headless `PASS` 40/40 exit 0; `--headless --editor --quit` exit 0 |
| 6 — Arena & Wave Director | T-024..T-027 | ✅ Selesai + terverifikasi (belum review terpisah) | Harness headless `PASS` 167/167 exit 0; `--headless --editor --quit` exit 0 |
| 7 — UI & Game Flow | T-028..T-034 | ✅ Selesai + terverifikasi (belum review terpisah) | Harness headless `PASS` 93/93 + restart 5/5 exit 0; `--headless --editor --quit` exit 0; `--headless --quit` exit 0 |
| 8 — Audio & Juice Polish | T-035..T-038 | ✅ Selesai + review fixed | Harness headless `PASS` 74/74 + retry 4/4 exit 0; `--headless --editor --quit` exit 0; `--headless --quit` exit 0 |

### Yang sudah dikerjakan

**Phase 0 — Project Setup**
- `project.godot`: viewport `1280×720`, stretch `canvas_items`/`keep`, physics `60 Hz`, renderer `Forward+`, 6 input action (WASD/arrow, LMB, Esc), 6 nama physics layer, 4 autoload.
- 12 folder sesuai §2 dibuat.
- 4 stub autoload (`extends Node`) terdaftar; `run/main_scene` sengaja belum diisi (milik T-028).

**Phase 1 — Autoload Core**
- `autoloads/event_bus.gd` — 7 signal bertipe persis TAD §4.1.
- `autoloads/game_manager.gd` — `State { MENU, PLAYING, PAUSED, GAME_OVER }`, skor + ricochet 2×, `time_survived`, sinkron `get_tree().paused`, `reset_run()`, hit-stop dengan sequence guard.
- `autoloads/vfx_manager.gd` — muzzle flash, ricochet sparks (streak `align_y`), tank explosion (scorch/fire/smoke/debris), floating text + fallback prosedural; auto-subscribe `bullet_ricocheted` dan `enemy_destroyed`.
- `autoloads/audio_manager.gd` — `play_cannon/ricochet/explosion/engine`, `stop_engine`; sintesis `AudioStreamGenerator` 22 050 Hz, pool 8 voice, aman tanpa audio device.

**Review Phase 1 (4 Important) — diperbaiki & diverifikasi RED→GREEN**
1. One-shot terpotong buffer → ekor senyap `ONE_SHOT_TAIL = 0.25 s` (> `buffer_length` 0.2 s).
2. Partikel tanpa tekstur → `GradientTexture2D` prosedural + `color_ramp` alpha→0; sparks streak + `particle_flag_align_y`.
3. `setup()` floating text sebelum masuk tree → dipanggil setelah `add_child` + `global_position`.
4. Engine loop tak bisa berhenti → `stop_engine()`, terhubung ke `EventBus.player_died`.
- Minor ikut dibereskan: #5 instance kontrak salah di-`free()`; #6 normal `ZERO` → `Vector2.UP`.
- Minor ditunda: #7 z-order (T-038), #8 skor setelah GAME_OVER (Phase 3), #9 cakupan `reset_run()` (T-034), #10 kelaparan voice, #11 generator per pemutaran.

**Phase 2 — Player**
- `scenes/player/player.tscn` — `PlayerTank` (`CharacterBody2D`, grup `player`, layer 1, mask 54, `MOTION_MODE_FLOATING`), hitbox 36×36, `HullVisual` (hull + 2 track), `TurretPivot` (barrel + star + `MuzzleMarker`), `TreadTimer` 0.05 s.
- `scripts/player/player.gd` — gerak 8 arah + `speed_multiplier`, rotasi hull halus, turet ikut kursor, tembakan cooldown 0.45 s + recoil 200 + tween barrel, VFX/audio/shake, damage + i-frames 1.2 s + blink + hit flash, hit-stop, kematian (`player_died`, ledakan, visual disembunyikan), jejak roda world-space.
- `scenes/player/tread_mark.tscn` — `Line2D` width 5, `#2E241E`, `z_index = -2`, fade 3 s lalu `queue_free`.
- Kontrak Phase 3: `player.gd` mengisi `direction` pada peluru hanya bila properti itu ada (`bullet.get("direction") != null`); `player_bullet.tscn` dibuat di Phase 3 (T-014).
- Urutan kontrak: `direction` diisi **sebelum** `add_child`, karena `_ready()` peluru berjalan sinkron di dalam `add_child`. Position/rotation diset setelah masuk tree.

### Review Phase 2 (1 Important) — diperbaiki & diverifikasi RED→GREEN
1. `direction` peluru diisi setelah `add_child` → T-014 bisa spawn peluru diam. Fix: isi sebelum `add_child`; RED fake bullet `velocity=(0,0)` → GREEN `PASS`.
- Minor diperbaiki: `IFRAME_DURATION` kini dipakai; dokumen aim-on-tank & wording hit-stop dikoreksi.
- Minor ditunda: `_die()` reset tween/visual (T-034), parent world/effects (T-024), set `is_invulnerable` sebelum emit (tidak ada listener reentrant), uji cooldown saat hit-stop (QA Phase 9).

**Phase 3 — Projectiles**
- `scenes/projectiles/player_bullet.tscn` + `scripts/projectiles/player_bullet.gd` — `PlayerBullet` (`CharacterBody2D`, layer 4/mask 2+3, FLOATING, z 20), `CircleShape2D` r4, visual `#FFD700` 12×4. Kecepatan 650, pantul 1×, jadi `#FF5500`, hancur pada impact kedua, `bullet_ricocheted` + `play_ricochet`, off-screen margin 256.
- `scenes/projectiles/enemy_bullet.tscn` + `scripts/projectiles/enemy_bullet.gd` — `EnemyBullet` (layer 5/mask 1+3, FLOATING, z 20), visual `#FF2222` 10×4. Kecepatan dari penembak (`speed`, default 400), tidak memantul, damage `1, false` ke target ber-`take_damage`, off-screen margin 256.
- Urutan impact peluru pemain: `take_damage` → `bouncy_surface` → hancur. Sparks pantulan tidak dipanggil manual karena `VFXManager` sudah subscribe `bullet_ricocheted`.
- Integrasi: `player._fire()` sekarang menembakkan scene nyata; kontrak `direction` sebelum `add_child` terbukti dengan tes.

**Phase 4 — Enemies**
- `scripts/enemies/base_enemy.gd` — `BaseEnemy` (`CharacterBody2D`, layer 2, mask 47), `max_hp/move_speed/base_score`, `hp`, `speed_multiplier`, hit flash overbright 0.1 s, `take_damage`, `die` → `EventBus.enemy_destroyed`, `get_player()`.
- `scenes/enemies/enemy_scout.tscn` + `enemy_scout.gd` — HP 1 / speed 250 / score 100; mengejar player; kontak → `take_damage(1)` lalu `die(false)`.
- `scenes/enemies/enemy_artillery.tscn` + `enemy_artillery.gd` — HP 1 / speed 110 / score 200; maju bila >350 px, berhenti bila ≤350 px; tembak `enemy_bullet.tscn` 400 px/s tiap 2.5 s.
- `scenes/enemies/enemy_dreadnought.tscn` + `enemy_dreadnought.gd` — HP 2 / speed 70 / score 500; tembak 350 px/s tiap 3.5 s; override `take_damage` → ricochet instakill.
- T-020: `speed_multiplier` diterapkan ke velocity ketiga enemy.
- Koreksi saat verifikasi: `collision_mask` scene 61 → 47 (layer 1,2,3,4,6) dan `FireTimer.autostart` true → false agar sesuai spec/design.

**Phase 5 — Environment**
- `scenes/environment/steel_bunker.tscn` — `StaticBody2D` layer 3 (nilai 4), grup `"bouncy_surface"`, wedge 96×96 dengan hypotenuse 45°, border + 3 rivet; tanpa `take_damage` (indestructible).
- `scenes/environment/sandbag_barricade.tscn` + `scripts/environment/sandbag_barricade.gd` — `StaticBody2D` layer 3, grup `"destructible_cover"`; HP 3, flash putih 0.1 s, menyusut 8% per hit, retak di HP 1, hancur di hit ke-3 dengan partikel one-shot; tidak memantulkan peluru.
- `scenes/environment/mud_crater.tscn` + `scripts/environment/mud_crater.gd` — `Area2D` layer 6 (nilai 32), mask layer 1+2 (nilai 3), `z_index=-1`; `body_entered` → `speed_multiplier = 0.65`, `body_exited` → `1.0`; peluru tidak terpengaruh.
- Koreksi saat eksekusi: polygon bunker dibalik agar hypotenuse 45° yang pertama kena peluru; `_destroy()` menyembunyikan `Visual` (bukan root) agar partikel tetap terlihat.

**Phase 6 — Arena & Wave Director**
- `scenes/arena.tscn` + `scripts/arena/arena_controller.gd` — `ArenaController` (`Node2D`), background `#4A3B32` `z_index=-100`, `Camera2D` di `(640,360)`, 8 segmen `PerimeterWalls` layer 3 grup `"bouncy_surface"` dengan 4 gate 80 px, 4 `Marker2D` grup `"spawn_gate"` di luar layar, 4 bunker pinwheel `0/90/180/270°`, 3 sandbag, 3 mud, `Enemies` container, `WaveDirector`, dan `Player` di center. `reset_arena()` mereset run dan wave.
- `scripts/arena/camera_shake.gd` — `CameraShake` (`Camera2D`), subscribe `EventBus.camera_shake_requested`; offset acak dengan falloff linear, clamp `MAX_OFFSET=32`, kembali `(0,0)`, shake yang lebih lemah diabaikan.
- `scripts/arena/wave_director.gd` — `WaveDirector` (`Node`), `spawn_interval(t) = max(0.8, 3.0 - 0.15*floor(t/15))`, `pick_enemy_type` sesuai tabel 100% Scout / 70-30 / 50-35-15, spawn acak di gate milik arena, timer hanya hidup saat `PLAYING`, reset pada run baru.
- T-027: `VFXManager` sudah satu-satunya emitter `camera_shake_requested(5.0, 0.2)` pada `enemy_destroyed`; tidak ada koneksi baru.

**Phase 7 — UI & Game Flow**
- `scenes/main_menu.tscn` + `scripts/ui/main_menu.gd` — judul, grid blueprint prosedural (52 `Line2D`), `DEPLOY (START)` / `QUIT`, panduan `WASD` + `MOUSE`; `main_menu.tscn` kini `run/main_scene`.
- `scenes/ui/hud.tscn` + `hud.gd` — 3 perisai (retak + gelap saat `player_damaged`), `SCORE: %06d` via `score_updated`, `TIME: MM:SS`, reticle prosedural yang mengikuti mouse dan hanya tampil saat `PLAYING`.
- `scenes/ui/floating_text.tscn` + `floating_text.gd` — `setup(text)` + Tween naik 30 px, fade 0.8 s, lalu `queue_free()`; dipakai `VFXManager` alih-alih fallback prosedural.
- `scenes/ui/pause_menu.tscn` + `pause_menu.gd` — `Esc` toggle `PLAYING ↔ PAUSED`, tombol `RESUME` / `RESTART` / `MAIN MENU`, `PROCESS_MODE_ALWAYS`.
- `scenes/ui/game_over_menu.tscn` + `game_over_menu.gd` — overlay sepia, `TANK DESTROYED`, statistik final score/time/ricochet, `REDEPLOY (SPACE / CLICK)` + `MAIN MENU`.
- `arena_controller.gd` — `_ready` memulai run baru (`reset_run` + `PLAYING`), `restart_run()` (reload scene), `return_to_menu()`; restart menghapus semua node dinamis lewat reload, termasuk bullet/partikel/scorch/tread mark.

**Phase 8 — Audio & Juice Polish**
- T-035: `audio_manager.gd` — `play_engine()` menyimpan `_engine_moving`, pitch idle `0.85` / moving `1.15` pada voice yang sama; `stop_engine()`; `_on_game_state_changed()` menghidupkan engine hanya saat `PLAYING` dan menghentikannya di state lain.
- T-036: `play_hit()` (noise + ring 520 Hz, 0.18 s), `play_enemy_cannon()` (pitch 0.8), `last_sfx` di-set oleh semua `play_*`; `player_damaged` → hit, `enemy_destroyed` → explosion, `player_died` → stop engine + explosion + stop BGM. Call site: `BaseEnemy.take_damage`, `SandbagBarricade.take_damage`, `EnemyArtillery._fire`, `EnemyDreadnought._fire`.
- T-037: BGM prosedural 125 BPM, 2 bar (84 672 frame), kick tiap beat, snare beat 2/4, hi-hat tiap setengah beat, drone 55/82.5 Hz, fade 0.01 s; `start_bgm()` / `stop_bgm()` / `is_bgm_playing()` memakai voice loop dengan `volume_db = -12`; hanya hidup saat `PLAYING`.
- T-038: Scout `Visual` → `#8B3A3A`; `Outline` (`Line2D`, closed, width 1.5) di Scout/Artillery/Dreadnought (`#D9C9A3`) dan `HullVisual` player (`#E8D9A0`); bullet tetap `z_index = 20` di atas scorch `-1`, debris `5`, smoke `9`, fire `10`, sparks `15`.
- `_play()` selalu mereset `volume_db = 0.0` agar voice yang dipinjam BGM tidak membawa atenuasi -12 dB.
- Review fix: `_retry_playback()` di `_process` memulai ulang engine/BGM saat `PLAYING` begitu ada voice bebas, sehingga redeploy cepat setelah ledakan tidak membuat audio senyap permanen.

**Audit Phase 1–8 (2026-11-09)**
- Bug ditemukan & diperbaiki: cursor sistem tetap `HIDDEN` saat `PAUSED` dan `GAME_OVER`, sementara reticle HUD disembunyikan → tombol pause/game over tidak punya pointer yang terlihat. `pause_menu.gd` kini menampilkan cursor saat pause dan menyembunyikannya saat resume; `game_over_menu.gd` menampilkan cursor saat statistik tampil.
- Alur end-to-end diverifikasi: deploy → combat → pause/resume → restart dari pause → game over → redeploy → main menu → deploy lagi; semua state (`PLAYING`/`PAUSED`/`GAME_OVER`/`MENU`), `time_scale`, `tree.paused`, skor, dan audio bersih.
- Gameplay nyata di arena: ricochet memantul & jadi oranye, enemy bullet melukai player, sandbag hancur tepat 3 hit tanpa memantul, mud memperlambat 35% lalu pulih, Dreadnought tahan 1 hit langsung dan mati oleh 1 ricochet dengan skor 2×.

### Bukti verifikasi
- Harness sementara `res://tests/phase2_check.tscn`: RED per task (scene hilang → gerak → tembakan → damage → jejak) lalu GREEN `PASS`, exit 0, dua kali.
- Harness review `res://tests/phase2_fix_check.tscn` + fake `player_bullet.tscn`: RED kontrak peluru → GREEN `PASS`, exit 0; mencakup damage seframe, aim tepat di tank, collision mati, dan jejak saat berbelok.
- Phase 3 `res://tests/phase3_check.tscn`: RED `player_bullet.tscn belum ada` → GREEN; RED `enemy_bullet.tscn belum ada` → GREEN; `PASS` exit 0 dua kali. Mencakup pantulan, warna, sinyal + sparks tunggal, impact kedua, damage normal/ricochet, player aman, enemy bullet vs player/dinding/cover, off-screen, dan integrasi `player._fire()`.
- Phase 4 `res://tests/phase4_check.tscn`: RED `9/48` gagal (6 bug timing harness + 3 mask) → perbaiki harness → RED `3/50` (mask) → GREEN `PASS` 50 checks, exit 0. Mencakup signal/hit flash `BaseEnemy`, chase + kontak + mud Scout, threshold/tembak/peluru 400/mud Artillery, 2 HP vs ricochet Dreadnought, dan kontrak layer/mask/motion tiap scene.
- Phase 5 `res://tests/phase5_check.tscn`: RED `bunker` (scene hilang) → GREEN 11/11; RED `sandbag` → GREEN 29/29; RED `mud` → GREEN `PASS` 40/40, exit 0. Mencakup bounce 45° bunker, sandbag 3 hit + no-bounce, mud slowdown/restore, dan peluru yang tidak terpengaruh crater.
- Phase 6 `res://tests/phase6_check.tscn`: RED arena (scene hilang) → GREEN 119/119; RED camera (tanpa script) → GREEN 127/127; RED wave director (tanpa script) → GREEN 164/164; tambah T-027 → final `PASS` 167/167, exit 0. Mencakup 8 dinding + 4 gate bersih, pinwheel bunker, posisi obstacle, 12 kombinasi gate × tipe enemy, interval & probabilitas wave, state gating/reset, offset kamera, dan tepat satu shake `(5.0, 0.2)` per `enemy_destroyed`.
- Phase 7 `res://tests/phase7_check.tscn`: RED menu (scene hilang) → GREEN 16/16; RED HUD → GREEN 35/35; RED floating text → GREEN 43/43; RED pause → GREEN 60/60; RED game over → GREEN 75/75; RED cursor → GREEN 82/82; RED flow → final `PASS` 93/93, exit 0. Mencakup grid/tombol menu, skor/waktu/perisai, floating text via `VFXManager`, pause saat tree paused, statistik game over, reticle, dan reset run saat arena mulai.
- Phase 7 `res://tests/phase7_restart.tscn`: 5 reload beruntun → `PASS (5 runs)`, exit 0; tiap run memverifikasi `PLAYING`, skor/time reset, `time_scale == 1.0`, `Enemies` kosong, tidak ada sisa grup `enemy`, peluru pemain, atau peluru musuh.
- Phase 8 `res://tests/phase8_check.tscn`: RED T-036 5/32 (call site + `last_sfx`), RED T-037 3/35 (buffer/method BGM), RED T-038 7/74 (warna Scout + outline); final `PASS` 74/74, exit 0. Mencakup pitch engine & state gating, `last_sfx` tiap SFX, wiring EventBus, hit sandbag/enemy, tembakan artillery/dreadnought, buffer + transient BGM, reuse/atenuasi voice, alur state audio, warna/outline siluet, dan z-order efek di bawah bullet.
- Phase 8 review fix `res://tests/phase8_retry_check.tscn`: RED `engine and BGM recover once a voice frees` → GREEN `PASS` 4/4, exit 0; membuktikan engine/BGM pulih otomatis setelah 8 voice dipenuhi one-shot.
- Audit Phase 1–8 `res://tests/phase_audit.tscn`: headless `PASS` 53/53 exit 0; windowed `PASS` 59/59 exit 0. Mencakup alur menu/arena/pause/restart/game over/redeploy, `time_scale` & `paused`, skor/ricochet/floating text, HUD shield, i-frame, ricochet nyata di arena, enemy bullet, sandbag, mud, Dreadnought, dan visibilitas cursor. RED cursor: windowed `FAIL 2/47` (pause & game over) → GREEN.
- Windowed startup `--quit-after 120`: exit 0, tanpa ERROR/WARNING. Harness audit dihapus; `tests/` bersih.
- `--headless --editor --quit` → exit 0, tanpa `ERROR`/`Parse Error`/`WARNING`.
- `--headless --quit` → exit 0 setelah `run/main_scene` diisi.
- Harness Phase 3, 4, 5, 6, 7 & 8 dihapus; `tests/` bersih; hanya file §2 + `docs/` yang tersisa.

### Ruling yang perlu diingat
- Folder ini **bukan git repo** → aturan "one task = one commit" tidak berlaku; validasi + ledger menggantikan commit.
- Autoload tidak hidup di mode `--script`; tes autoload harus dijalankan sebagai scene.
- Headless memakai audio driver dummy → playback nyata tidak terjadi; fix audio diverifikasi pada data waveform. Uji dengar dilakukan di windowed run (Phase 8).
- `WARNING: 1–3 ObjectDB instances were leaked` saat exit adalah artefak shutdown `AudioStreamGeneratorPlayback`, bukan node game; exit code tetap 0.
- Phase 2: rotasi hull, jejak roda, dan audio engine memakai `has_input`, bukan `velocity`; recoil tidak boleh memutar hull atau mencetak jejak palsu.
- Phase 2: `player.gd` memakai `class_name PlayerTank` dan `motion_mode = MOTION_MODE_FLOATING` (default `GROUNDED` mengganggu gerak top-down).
- Phase 2: posisi dasar barrel disimpan sekali (`_turret_base_x`) agar recoil tidak bergeser saat tween lama di-kill.
- Phase 3: `direction` peluru diisi sebelum `add_child`; `_ready()` peluru berjalan sinkron dan menghitung `velocity`.
- Phase 3: sparks pantulan hanya dari `EventBus.bullet_ricocheted` (VFXManager); memanggil `spawn_ricochet_sparks` lagi akan menggandakan efek.
- Phase 3: damage memakai `collider.call("take_damage", 1, false)` agar kompatibel dengan player (arg kedua opsional) dan sandbag Phase 5 (arg kedua wajib).
- Phase 4: verifikasi memakai fake player (grup `"player"`, `take_damage`) agar tes kontak/peluru terisolasi; player asli tidak diinstansiasi.
- Phase 4: pengukuran velocity harus menunggu 2 `physics_frame`; `SceneTree.physics_frame` diemit sebelum `_physics_process`.
- Phase 4: timer tembak dipercepat ke 0.1 s hanya di harness; interval 2.5/3.5 s tetap diverifikasi lewat `FireTimer.wait_time`.
- Phase 4: `collision_mask` 61 → 47 sesuai §1.6; `FireTimer.autostart` true → false sesuai design (engine otomatis mereset autostart saat masuk tree).
- Phase 4: `get_player() -> Node2D` mengikuti plan; design menulis `-> PlayerTank`, tidak diubah karena hanya lookup grup.
- Phase 5: polygon bunker dibalik ke `[(-48,48),(48,48),(48,-48)]` agar peluru dari kiri mengenai hypotenuse 45° lebih dulu, bukan sisi kiri.
- Phase 5: `_destroy()` sandbag menyembunyikan `Visual`, bukan root, supaya partikel debris tetap terlihat.
- Phase 5: tes mud memakai `FakeTank` (`StaticBody2D` + `speed_multiplier`); jalur properti sama dengan Player/Enemy yang sudah diverifikasi di Phase 2/4.
- Phase 5: `MudCrater` memakai `body.get("speed_multiplier")` sebelum `set`, agar aman untuk body yang tidak punya properti itu.
- Phase 6: gate entry diuji sebagai "jarak ke center turun ≥ 40 px dan enemy tetap di koridor gate 90 px", karena Artillery berhenti di jarak tembak 350 px — untuk gate atas/bawah itu tepat di mulut gate, bukan tertahan dinding.
- Phase 6: `_random_gate_position()` memfilter `"spawn_gate"` dengan `_arena.is_ancestor_of(node)` agar spawn tidak lintas arena saat ada lebih dari satu arena (mis. harness).
- Phase 6: shake memakai vektor unit acak sehingga magnitudo offset persis `intensity × falloff`; arah tetap acak.
- Phase 6: `t=0 always spawns a scout` memeriksa `scene_file_path`, bukan `get_script().resource_path` (itu path script, bukan scene).
- Phase 6: satu run harness sempat exit `0xC0000005` setelah PASS; run berikutnya exit 0. Dianggap race shutdown Godot saat node/timer queued dibersihkan; final run bersih.
- Phase 7: HUD/menu ditempel di `arena.tscn`; menu utama scene terpisah, jadi restart = `reload_current_scene()` dan semua node dinamis (enemy, peluru, partikel, scorch, tread mark) hilang bersama scene lama.
- Phase 7: `ArenaController._ready()` selalu `reset_run()` + `change_state(PLAYING)`, sehingga deploy dan redeploy sama-sama memulai run baru tanpa jalur inisialisasi ganda.
- Phase 7: shutdown/restart memakai `get_parent().call("restart_run")` / `return_to_menu()` dari menu; tidak menambah signal EventBus karena ini komunikasi scene-local.
- Phase 7: headless dummy display mengabaikan `Input.mouse_mode` (read-back selalu VISIBLE); verifikasi headless mengecek read-back lalu source `MOUSE_MODE_HIDDEN`, sedangkan perilaku kursor nyata masuk QA windowed Phase 9.
- Phase 7: restart harness memakai `Engine.set_meta` sebagai counter lintas reload (bukan static var) agar tidak bisa hilang saat script reload.
- Phase 8: `play_engine()` menyimpan `_engine_moving`, jadi resume setelah pause memulihkan pitch moving/idle yang benar tanpa voice kedua.
- Phase 8: harness menunggu voice pool idle sebelum tes BGM; tes SFX memulai belasan one-shot dalam beberapa milidetik dan 8 voice masih terpakai, sehingga `_play()` sah-sah saja mengembalikan `null` (isu starvation voice lama tetap backlog).
- Phase 8: `EnemyScout._ready()` memaksa `max_hp = 1`; tes non-fatal harus menaikkan `hp` setelah `_ready`, bukan `max_hp` sebelum `add_child`.
- Phase 8: isi `last_sfx` di-set sebelum `_play()`, jadi tetap terdeteksi walau tidak ada voice bebas.
- Phase 8: `_play()` mereset `volume_db` ke `0.0` supaya voice yang dipinjam BGM (-12 dB) tidak meninggalkan atenuasi pada one-shot berikutnya.
- Phase 8: `_retry_playback()` mencoba engine/BGM lagi hanya saat `PLAYING` dan ada voice bebas; tidak menambah voice atau mengubah prioritas, jadi starvation sesaat tidak lagi permanen.
- Phase 8 review minor ditunda: render BGM sinkron di `_ready` (biaya startup sekali), `Bumper` Scout menutup ujung outline (kosmetik), `_fire()` memutar suara sebelum validasi `BULLET_SCENE` (tidak tercapai dengan zero-asset).
- Audit Phase 1–8: cursor dikelola di layer menu (pause/game over) masing-masing, bukan di `GameManager`, karena hanya menu yang butuh pointer terlihat; arena dan main menu sudah memiliki mode play/menu sendiri.
- Audit Phase 1–8: harness memakai arena sebagai `current_scene` sementara dan root harness tetap hidup di bawah `root`, sehingga `reload_current_scene()`/`change_scene_to_file()` bisa diuji tanpa mematikan test.

### Detail lengkap
- Rencana & langkah: `docs/superpowers/plans/2026-11-06-phase1-autoloads.md`
- Ledger eksekusi + ruling: `docs/superpowers/plans/2026-11-06-phase1-autoloads.progress.md`
- Desain + kontrak T-030: `docs/superpowers/specs/2026-11-06-phase1-autoloads-design.md`
- Rencana Phase 2: `docs/superpowers/plans/2026-11-06-phase2-player.md`
- Ledger Phase 2: `docs/superpowers/plans/2026-11-06-phase2-player.progress.md`
- Desain Phase 2: `docs/superpowers/specs/2026-11-06-phase2-player-design.md`
- Rencana Phase 3: `docs/superpowers/plans/2026-11-06-phase3-projectiles.md`
- Ledger Phase 3: `docs/superpowers/plans/2026-11-06-phase3-projectiles.progress.md`
- Desain Phase 3: `docs/superpowers/specs/2026-11-06-phase3-projectiles-design.md`
- Rencana Phase 4: `docs/superpowers/plans/2026-11-06-phase4-enemies.md`
- Ledger Phase 4: `docs/superpowers/plans/2026-11-06-phase4-enemies.progress.md`
- Desain Phase 4: `docs/superpowers/specs/2026-11-06-phase4-enemies-design.md`
- Rencana Phase 5: `docs/superpowers/plans/2026-11-08-phase5-environment.md`
- Ledger Phase 5: `docs/superpowers/plans/2026-11-08-phase5-environment.progress.md`
- Desain Phase 5: `docs/superpowers/specs/2026-11-08-phase5-environment-design.md`
- Rencana Phase 6: `docs/superpowers/plans/2026-11-08-phase6-arena.md`
- Ledger Phase 6: `docs/superpowers/plans/2026-11-08-phase6-arena.progress.md`
- Desain Phase 6: `docs/superpowers/specs/2026-11-08-phase6-arena-design.md`
- Rencana Phase 7: `docs/superpowers/plans/2026-11-08-phase7-ui.md`
- Ledger Phase 7: `docs/superpowers/plans/2026-11-08-phase7-ui.progress.md`
- Desain Phase 7: `docs/superpowers/specs/2026-11-08-phase7-ui-design.md`
- Rencana Phase 8: `docs/superpowers/plans/2026-11-08-phase8-audio.md`
- Ledger Phase 8: `docs/superpowers/plans/2026-11-08-phase8-audio.progress.md`
- Desain Phase 8: `docs/superpowers/specs/2026-11-08-phase8-audio-design.md`

---

## 1. GLOBAL CONSTANTS (Single Source of Truth)

### 1.1 Colors
| Element | Hex |
|---|---|
| Ground | `#4A3B32` |
| Dark Mud | `#2E241E` |
| Player | `#556B2F` (+ white star) |
| Enemy | `#8B3A3A`, `#36393F` |
| Normal Bullet | `#FFD700` |
| Ricochet Bullet | `#FF5500` |
| Enemy Bullet | `#FF2222` |
| Ricochet Sparks | `#FFD700` |
| Explosion | `#FF5500` + black smoke |

### 1.2 Player
`MAX_HP=3` · `BASE_SPEED=220.0` · `TURN_SPEED=10.0` · `FIRE_COOLDOWN=0.45` · `RECOIL_FORCE=40.0` · `IFRAME_DURATION=1.2` · Hitbox `36x36`

### 1.3 Enemies
| Type | HP | Speed | Fire Interval | Bullet Speed | Score |
|---|---|---|---|---|---|
| Scout | 1 | 250 | — | — | 100 |
| Artillery | 1 | 110 | 2.5s | 400 | 200 |
| Dreadnought | 2 | 70 | 3.5s | 350 | 500 |

### 1.4 Player Bullet
`SPEED=650.0` · `MAX_BOUNCES=1` · after bouncing → color `#FF5500` + 2x score

### 1.5 Screen Shake `(intensity px, duration s)`
Firing `(2, 0.1)` · Enemy explosion `(5, 0.2)` · Player damaged `(12, 0.35)` + hit-stop `0.05s`

### 1.6 Physics Layers
| Layer | Name | Objects | Mask |
|---|---|---|---|
| 1 | Player | Player | 2,3,5,6 |
| 2 | Enemy | 3 enemy types | 1,2,3,4,6 |
| 3 | Environment | Walls, SteelBunker, Sandbag | — |
| 4 | PlayerBullet | PlayerBullet | 2,3 |
| 5 | EnemyBullet | EnemyBullet | 1,3 |
| 6 | TerrainHazard | MudCrater (Area2D) | 1,2 |

### 1.7 Node Groups
`"player"` (Player root) · `"bouncy_surface"` (Perimeter Walls + SteelBunker) · `"destructible_cover"` (SandbagBarricade)

### 1.8 Input Map
`move_up`=W/Up · `move_down`=S/Down · `move_left`=A/Left · `move_right`=D/Right · `shoot`=LMB · `pause`=Esc

---

## 2. DIRECTORY STRUCTURE (MANDATORY)

```text
res://
├── project.godot
├── autoloads/        event_bus.gd  game_manager.gd  vfx_manager.gd  audio_manager.gd
├── scenes/
│   ├── main_menu.tscn   arena.tscn
│   ├── player/        player.tscn  tread_mark.tscn
│   ├── projectiles/   player_bullet.tscn  enemy_bullet.tscn
│   ├── enemies/       enemy_scout.tscn  enemy_artillery.tscn  enemy_dreadnought.tscn
│   ├── environment/   steel_bunker.tscn  sandbag_barricade.tscn  mud_crater.tscn
│   └── ui/            hud.tscn  pause_menu.tscn  game_over_menu.tscn  floating_text.tscn
└── scripts/
    ├── arena/         arena_controller.gd  camera_shake.gd  wave_director.gd
    ├── player/        player.gd
    ├── projectiles/   player_bullet.gd  enemy_bullet.gd
    ├── enemies/       base_enemy.gd  enemy_scout.gd  enemy_artillery.gd  enemy_dreadnought.gd
    ├── environment/   sandbag_barricade.gd  mud_crater.gd
    └── ui/            main_menu.gd  hud.gd  pause_menu.gd  game_over_menu.gd  floating_text.gd
```

---

## PHASE 0 — Project Setup

- [x] **T-001** Create `project.godot` and the folders specified in §2 (empty/placeholder files are allowed).
  - Viewport `1280x720`, stretch mode `canvas_items`, aspect `keep`, physics ticks `60`.
  - Rendering: `Forward+` or `Compatibility`.
  - **DoD:** The project opens in Godot without errors.
- [x] **T-002** Define the Input Map (§1.8) in `project.godot`.
  - **DoD:** All 6 actions are registered with the correct keys/mouse inputs.
- [x] **T-003** Name the 6 Physics Layers (§1.6) in Project Settings → Layer Names → 2D Physics.
- [x] **T-004** Register 4 Autoloads: `EventBus`, `GameManager`, `VFXManager`, `AudioManager` (paths `res://autoloads/*.gd`).
  - **Depends:** T-005..T-008 (temporary stubs are allowed).

---

## PHASE 1 — Autoload Core

- [x] **T-005** `autoloads/event_bus.gd` — signal declarations only:
  ```gdscript
  signal player_damaged(current_hp: int, max_hp: int)
  signal player_died()
  signal enemy_destroyed(enemy_position: Vector2, base_score: int, was_ricochet: bool)
  signal score_updated(new_score: int, ricochet_kills: int)
  signal camera_shake_requested(intensity: float, duration: float)
  signal bullet_ricocheted(impact_position: Vector2, impact_normal: Vector2)
  signal game_state_changed(new_state: int)
  ```
  - **DoD:** All 7 signals exist and are typed.
- [x] **T-006** `autoloads/game_manager.gd`
  - `enum State { MENU, PLAYING, PAUSED, GAME_OVER }`; variables `score:int`, `time_survived:float`, `ricochet_kills:int`.
  - Methods `change_state()`, `reset_run()`; `time_survived` increases in `_process` only while state is `PLAYING`.
  - Listen for `enemy_destroyed`: for ricochet kills → `base_score*2`, increment `ricochet_kills+=1`, call `VFXManager.spawn_floating_text(pos, "+%d RICOCHET!" % (base_score*2))`; for non-ricochet kills → `+base_score`. Emit `score_updated`.
  - Listen for `player_died` → set state to `GAME_OVER`.
  - `trigger_hit_stop(duration: float = 0.05) -> void`: set `Engine.time_scale = 0.05`, then restore it to `1.0` through `get_tree().create_timer(duration, true, false, true).timeout`.
  - Pause: `get_tree().paused` must follow the `PAUSED` state (autoload and pause menu use `process_mode = ALWAYS`).
  - **DoD:** Score and statistics are correct; `time_scale` always returns to 1.0.
- [x] **T-007** `autoloads/vfx_manager.gd` (all functions procedural, no assets):
  - `spawn_muzzle_flash(pos, rot)`: yellow-white polygon for `0.08s` + gray smoke particles.
  - `spawn_ricochet_sparks(pos, normal)`: `CPUParticles2D` lines in `#FFD700`, directed along the reflection direction.
  - `spawn_tank_explosion(pos)`: (1) transparent black polygon scorch mark on the lower ground layer, (2) `#FF5500` fire particles + black smoke, (3) 3–5 metal-plate debris fragments launched in random directions, stopping after `0.4s` and remaining on the ground for several seconds.
  - `spawn_floating_text(pos, text)`: instantiate `floating_text.tscn`.
  - Auto-subscribe: `bullet_ricocheted` → sparks; `enemy_destroyed` → explosion + shake `(5, 0.2)`.
  - **DoD:** Every function can be called independently without errors; effect nodes are `queue_free`d after completion (no leaks).
- [x] **T-008** `autoloads/audio_manager.gd`
  - Pool `AudioStreamPlayer` / `AudioStreamPlayer2D` (polyphonic).
  - `AudioStreamGenerator` fallback: white-noise burst (cannon/explosion), high sine sweep (ricochet ping, randomized pitch `0.9–1.1`).
  - API: `play_cannon()`, `play_ricochet()`, `play_explosion()`, `play_engine(moving: bool)`; BGM is optional (only if a file exists).
  - If `.wav/.ogg` files are missing from `assets/` → do not error; use the generator.
  - **DoD:** No errors occur when audio assets are missing.

---

## PHASE 2 — Player

- [x] **T-009** `scenes/player/player.tscn` — hierarchy:
  - `Player` (`CharacterBody2D`, group `"player"`, layer 1, mask 2,3,5,6)
    - `CollisionShape2D` (Rect 36x36)
    - `HullVisual` (`Node2D` → `Polygon2D` `#556B2F` + track-line details)
    - `TurretPivot` (`Node2D`) → `TurretVisual` (`Polygon2D` barrel + white star), `MuzzleMarker` (`Marker2D` at the barrel tip)
    - `TreadTimer` (`Timer`, `0.05s`)
  - **DoD:** Scene opens; hierarchy and layer/mask match the specification.
- [x] **T-010** `scripts/player/player.gd` — movement & aiming
  - `Input.get_vector(...)` × `BASE_SPEED * speed_multiplier`; `move_and_slide()`.
  - Hull: `HullVisual.rotation = lerp_angle(HullVisual.rotation, velocity.angle(), TURN_SPEED * delta)` only while moving.
  - Turret: `TurretPivot.look_at(get_global_mouse_position())`.
  - Initial position: arena center `(640, 360)`.
  - `var speed_multiplier: float = 1.0`.
  - **DoD:** 8-directional movement, smooth hull rotation, turret follows the cursor, tank is blocked by walls.
- [x] **T-011** Shooting & recoil (in `player.gd`)
  - Fire when `shoot` is pressed and the `0.45s` cooldown has elapsed → instantiate `player_bullet.tscn` at `MuzzleMarker`, direction = aim direction.
  - `velocity -= aim_direction * RECOIL_FORCE * 5.0`; tween `TurretVisual.position.x` backward and then return it to the original position.
  - Call `VFXManager.spawn_muzzle_flash`, `AudioManager.play_cannon`, `EventBus.camera_shake_requested.emit(2.0, 0.1)`.
  - **DoD:** The player cannot fire faster than the cooldown; recoil is noticeable.
- [x] **T-012** Damage & i-frames
  - `take_damage(amount: int, _is_ricochet: bool = false) -> void`: ignore the hit if `is_invulnerable`; reduce HP; emit `player_damaged`; enable `1.2s` i-frames + blink using a `modulate.a` Tween; call `GameManager.trigger_hit_stop(0.05)`; shake `(12.0, 0.35)`; white hit flash for `0.1s`.
  - HP ≤ 0 → emit `player_died`, call `VFXManager.spawn_tank_explosion`, hide/`queue_free` the visual.
  - **DoD:** No duplicate damage during i-frames; game over triggers at 0 HP.
- [x] **T-013** `scenes/player/tread_mark.tscn` (`Line2D`) + logic in `player.gd`
  - On every `TreadTimer` timeout while the player is moving → add paired track-mark points (2 dark-brown lines); fade out and disappear after `3s`.
  - **DoD:** Track marks appear only while moving and disappear automatically (they do not accumulate forever).

---

## PHASE 3 — Projectiles

- [x] **T-014** `player_bullet.tscn` + `player_bullet.gd` (`CharacterBody2D`, layer 4, mask 2,3)
  - Visual color `#FFD700`. `velocity = direction * SPEED`.
  - `_physics_process` (follow TAD §5.2):
    - If collider has `take_damage` → `take_damage(1, is_ricochet)` then `queue_free()`.
    - Else if it belongs to group `"bouncy_surface"`: if `bounce_count < MAX_BOUNCES` → `bounce_count+=1`, `is_ricochet=true`, `velocity = velocity.bounce(normal)`, `rotation = velocity.angle()`, color `#FF5500`, emit `bullet_ricocheted`, `AudioManager.play_ricochet`; if the maximum has already been reached → `spawn_ricochet_sparks` then `queue_free()`.
    - Else → `queue_free()`.
  - Destroy it if it travels far outside the screen (safety).
  - **DoD:** Bounces exactly once, turns orange, and is destroyed on the second impact; does not damage the player.
- [x] **T-015** `enemy_bullet.tscn` + `enemy_bullet.gd` (layer 5, mask 1,3)
  - Visual color `#FF2222`, travels straight, **does not ricochet**; speed is set by the shooter (400/350).
  - On player hit → `take_damage(1)` + `queue_free()`; on `destructible_cover` hit → damage the sandbag; on wall hit → `queue_free()`.
  - **DoD:** Enemy bullets are destroyed by walls and deal 1 HP damage to the player.

---

## PHASE 4 — Enemies

- [x] **T-016** `scripts/enemies/base_enemy.gd` (`CharacterBody2D`, layer 2, mask 1,2,3,4,6)
  - `@export max_hp=1`, `@export move_speed=150.0`, `@export base_score=100`, `var speed_multiplier=1.0`.
  - `take_damage(amount: int, from_ricochet: bool) -> void`: reduce HP, trigger hit flash with `modulate = Color(10,10,10,1)` for `0.1s`, call `die(from_ricochet)` if HP ≤ 0.
  - `die(from_ricochet: bool) -> void`: emit `enemy_destroyed(global_position, base_score, from_ricochet)`, then `queue_free()`.
  - Helper: `get_player()` via `get_tree().get_first_node_in_group("player")`.
  - **DoD:** Subclasses only need to override behavior; they must not duplicate damage logic.
- [x] **T-017** `enemy_scout.tscn` + `enemy_scout.gd`
  - HP 1, speed 250, score 100. Directly chases the player. Visual: dull-brown light armored car + spiked bumper.
  - On contact with Player → `player.take_damage(1)` then `die(false)`.
  - **DoD:** Normal score + explosion when shot; collision with player deals 1 damage.
- [x] **T-018** `enemy_artillery.tscn` + `enemy_artillery.gd`
  - HP 1, speed 110, score 200. If distance > 350 → move forward; if ≤ 350 → `velocity = ZERO`, and aim the barrel at the player.
  - Fire `enemy_bullet.tscn` (400 px/s) every `2.5s` (Timer). Visual: dark gray + long barrel.
  - **DoD:** Stops at ≤ 350 px and fires at the specified interval.
- [x] **T-019** `enemy_dreadnought.tscn` + `enemy_dreadnought.gd`
  - HP 2, speed 70, score 500, fires every `3.5s` (350 px/s). Large Mark V-style visual.
  - Override:
    ```gdscript
    func take_damage(amount: int, from_ricochet: bool) -> void:
        if from_ricochet:
            super.take_damage(max_hp, true)
        else:
            super.take_damage(amount, false)
    ```
  - **DoD:** Killed by 2 direct shots OR 1 ricochet shot.
- [x] **T-020** All enemies: mud slowdown must be applied through `speed_multiplier` in velocity calculations.

---

## PHASE 5 — Environment

- [x] **T-021** `steel_bunker.tscn` (`StaticBody2D`, layer 3, group `"bouncy_surface"`)
  - Angled metallic-gray polygon + rivets. Indestructible.
- [x] **T-022** `sandbag_barricade.tscn` + `sandbag_barricade.gd` (`StaticBody2D`, layer 3, group `"destructible_cover"`)
  - HP 3. `take_damage(amount: int, _is_ricochet: bool) -> void`: white hit flash, shrink/crack slightly; when HP ≤ 0 → destroy it (small particles). **Does not bounce bullets.**
  - **DoD:** Destroyed exactly on the 3rd hit (from either player or enemy bullets).
- [x] **T-023** `mud_crater.tscn` + `mud_crater.gd` (`Area2D`, layer 6, mask 1,2, `z_index=-1`)
  - `body_entered` → `body.speed_multiplier = 0.65`; `body_exited` → `1.0`. Color `#2E241E`. Bullets pass through.
  - **DoD:** Player and enemies are slowed by 35% inside the crater and return to normal speed when leaving.

---

## PHASE 6 — Arena & Wave Director

- [x] **T-024** `scenes/arena.tscn` + `arena_controller.gd`
  - Background `#4A3B32`. `Camera2D` at `(640,360)`.
  - `PerimeterWalls` on 4 sides (layer 3, group `"bouncy_surface"`) with four `80px` gate openings at the center of the Top/Bottom/Left/Right sides; place spawn `Marker2D` nodes outside the screen at each gate.
  - Place: 4× `SteelBunker` symmetrically angled at 45° (one per quadrant), 3× `SandbagBarricade` near the center, 3× `MudCrater`.
  - Ensure the player spawn path (center) and gates are not obstructed.
  - **DoD:** Layout is symmetrical; enemies can enter through all gates.
- [x] **T-025** `scripts/arena/camera_shake.gd`
  - Listen for `EventBus.camera_shake_requested(intensity, duration)`; apply a decaying random offset; return to `(0,0)` when finished. If a new shake is stronger, replace the current one.
- [x] **T-026** `scripts/arena/wave_director.gd`
  - `T_spawn = max(0.8, 3.0 - 0.15 * floor(t / 15.0))`, updated on every spawn.
  - Probabilities (roll 0–1): `t<45` → 100% Scout · `45≤t<90` → `<0.70` Scout, remainder Artillery · `t≥90` → `<0.50` Scout, `<0.85` Artillery, remainder Dreadnought.
  - Spawn at a random gate `Marker2D`; active only while state is `PLAYING`; reset on restart.
  - **DoD:** Distribution and interval match the formulas (verify using debug logs).
- [x] **T-027** Connect `enemy_destroyed` to shake `(5.0, 0.2)` if not already implemented in T-007 (avoid duplicate emission).

---

## PHASE 7 — UI & Game Flow

- [x] **T-028** `main_menu.tscn` + `main_menu.gd`: title, procedural blueprint background (lines/grid), `DEPLOY (START)` & `QUIT` buttons, control guide (`WASD`=Move, `Mouse`=Aim/Shoot). Set `main_menu.tscn` as the main scene.
- [x] **T-029** `hud.tscn` + `hud.gd`
  - Top left: 3 shield icons, broken/blackened when `player_damaged` occurs.
  - Top center: `SCORE: 004500` (6 digits, stencil/monospace fallback font) + time `MM:SS`.
  - Update through signals (`score_updated`) — do not poll the score every frame.
- [x] **T-030** `floating_text.tscn` + `floating_text.gd`: move upward by `30px` and fade `modulate.a→0` over `0.8s` using a Tween, then `queue_free()`.
- [x] **T-031** `pause_menu.tscn` + `pause_menu.gd`: `Esc` toggles; `RESUME`, `RESTART`, `MAIN MENU`; `process_mode = ALWAYS`.
- [x] **T-032** `game_over_menu.tscn` + `game_over_menu.gd`: dim sepia screen, header `TANK DESTROYED`, statistics `Final Score` / `Time Survived` / `Ricochet Kills`, buttons `REDEPLOY (SPACE / CLICK)` & `MAIN MENU`.
- [x] **T-033** Reticle: hide the system cursor (`Input.mouse_mode = HIDDEN`), draw a procedural military crosshair that follows the mouse; show the cursor again in menus.
- [x] **T-034** Complete flow: Menu → Arena → Pause/Game Over → Restart/Menu. Restart must clear all enemies, bullets, debris, scorch marks, and track marks, as well as call `reset_run()` on GameManager and reset `Engine.time_scale = 1.0`.
  - **DoD:** 5 consecutive restarts without errors, leaks, or leftover state.

---

## PHASE 8 — Audio & Juice Polish

- [x] **T-035** Engine loop: low idle sound; pitch increases while the player is moving.
- [x] **T-036** Add SFX to all events (firing, ricochet with randomized pitch 0.9–1.1, explosion, hit).
- [x] **T-037** (Optional) 120–130 BPM percussion BGM if assets are available; do not error if they are missing.
- [x] **T-038** Readability pass: ensure the player, enemies, and active bullets have sufficient contrast against the ground and smoke (check colors in §1.1; smoke must not obscure bullets — effect z-index below bullets).

---

## PHASE 9 — QA & Release

- [ ] **T-039** Playtest checklist (check manually):
  - [ ] Ricochet once, orange color, 2x score + floating text
  - [ ] Dreadnought: 2 direct hits / 1 ricochet hit
  - [ ] Sandbag destroyed on 3rd hit; bullets do not bounce
  - [ ] Mud slows player & enemies by 35%
  - [ ] I-frames 1.2s; hit-stop & shake work correctly
  - [ ] Waves: Scout only before 45s, Artillery starts at 45s, Dreadnought starts at 90s
  - [ ] Pause/Resume/Restart/Main Menu do not corrupt state
  - [ ] No errors in Output; stable 60 FPS with many enemies
- [ ] **T-040** Performance check: effect nodes are `queue_free`d; the number of active `CPUParticles2D` nodes is limited (one-shot).
- [ ] **T-041** Short `README.md`: how to run, controls, project structure. Add Windows/Linux export presets.

---

## DECISIONS & NOTES (Ambiguity Resolution)

| # | Issue | Decision |
|---|---|---|
| 1 | Recoil: GDD says "40 px" vs TAD `RECOIL_FORCE*5.0` | Follow **TAD** (`velocity -= aim * 40.0 * 5.0`). |
| 2 | Dreadnought: GDD says "ricochet from side/rear" vs TAD says "all ricochets" | Follow **TAD** (all ricochet bullets = instant kill). Direction check = backlog (nice-to-have). |
| 3 | `tread_mark.tscn` has no script in §2 | Track-mark logic belongs in `player.gd`; the scene contains only `Line2D`. |
| 4 | `player.take_damage` is not defined in TAD | Use signature `take_damage(amount: int, _is_ricochet: bool = false)` to keep it consistent with other colliders. |
| 5 | Enemy explosion screen shake `(5, 0.2)` is in GDD but not TAD | Still implement it (T-007/T-027), but emit it from only one place. |
| 6 | `assets/` folder is mentioned in TAD but not listed in §2 | It may be created (optional) for audio/images only. |

## BACKLOG (Outside MVP)
- Check Dreadnought impact angle (side/rear only).
- Persistent high score (`user://`).
- Volume settings.
- Final image/audio assets replacing procedural fallbacks.
