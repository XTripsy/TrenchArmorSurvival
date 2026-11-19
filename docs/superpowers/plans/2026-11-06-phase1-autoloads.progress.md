# SDD ledger — plan: docs/superpowers/plans/2026-11-06-phase1-autoloads.md

Status: **Phase 1 complete + review fixed** (2026-11-06). Verified: harness PASS exit 0 ×2, editor exit 0. Next: Phase 2 (T-009..T-013).

Pre-flight: Task 2 memakai `EventBus.bullet_ricocheted`/`enemy_destroyed` dari Task 1; Task 3 memakai `VFXManager.spawn_floating_text` dari Task 2 — urutan T-005 → T-007 → T-006 → T-008 sudah menyesuaikan.

Ruling: tidak ada git repo (sama seperti Phase 0) — tidak ada worktree/commit; validasi + ledger menggantikan commit.

Ruling: autoload tidak di-instantiate pada mode `--script`, terbukti lewat probe `get_root().get_node_or_null()` → null. Tes phase 1 dijalankan sebagai scene (`res://tests/phase1_check.tscn`) supaya autoload hidup.

Task 1: complete (no commits — bukan git repo; `res://tests/phase1_check.tscn` → PASS exit 0, 7 signal + tipe argumen)

Task 2: Ruling: muzzle flash menyertakan asap berumur 0.8 s, jadi cek pembersihan di harness menunggu 1.2 s (bukan 0.2 s seperti di plan). Biaya jika salah: tes 1 detik lebih lambat.
Task 2: complete (no commits; harness → PASS exit 0; 4 API, auto-subscribe spark + explosion + shake (5.0, 0.2), floating text fallback, 20× muzzle flash tidak menumpuk)

Task 3: complete (no commits; harness → PASS exit 0; skor 100/300, ricochet_kills 1, floating text "+200 RICOCHET!", pause/unpause, hit-stop tunggal + bertumpuk + saat pause, state GAME_OVER)

Task 4: Ruling: `AudioStreamGeneratorPlayback` di 4.7 tidak punya `can_push_frame()`; dipakai `get_frames_available()` + `push_frame()` yang mengembalikan bool. Biaya jika salah: tidak ada, sudah diverifikasi lulus.
Task 4: Ruling: `_free_after` di VFXManager memakai child `Timer` (bukan `SceneTreeTimer`) supaya timer mati bersama node dan ikut pause. Biaya jika salah: perilaku pause sama, hanya sumber timer berbeda.
Task 4: Ruling: `play_engine(true/false)` menjaga loop tetap berbunyi dan hanya mengubah pitch (idle 0.85 / moving 1.15) sesuai GDD §8.1, bukan menghentikan loop. Biaya jika salah: gampang disesuaikan di T-035.
Task 4: Ruling: sisa `WARNING: 2 ObjectDB instances were leaked` adalah `AudioStreamGeneratorPlayback` milik AudioServer saat proses keluar, bukan node game; exit code tetap 0 dan tidak ada ERROR. Biaya jika salah: hanya noise di shutdown.
Task 4: complete (no commits; harness → PASS exit 0, 4 API terpanggil tanpa error di headless)

Review follow-up (2026-11-06):
Ruling: bukan git repo — bukti RED/GREEN memakai harness sementara `tests/phase1_review_check.tscn` + fixture `tests/floating_text_probe.gd`, keduanya dihapus setelah verifikasi.
Final: fixed (Important #1) `audio_manager.gd` — one-shot diakhiri `ONE_SHOT_TAIL` 0.25 s senyap (> `buffer_length` 0.2 s), jadi `stop()` di ujung array hanya membuang senyap. RED: cannon/ricochet/explosion "tail senyap hilang". GREEN: PASS.
Final: fixed (Important #2) `vfx_manager.gd` — semua `CPUParticles2D` memakai `GradientTexture2D` prosedural + `color_ramp` alpha→0; sparks memakai streak 8×32 + `particle_flag_align_y`. RED: 4 emitter tanpa texture/color_ramp, 0 emitter align_y. GREEN: PASS.
Final: fixed (Important #3) `vfx_manager.gd` — `setup()` dipanggil setelah `add_child` + `global_position`. RED: fixture melihat `is_inside_tree() == false`. GREEN: true.
Final: fixed (Important #4) `audio_manager.gd` — `stop_engine()` ditambahkan dan terhubung ke `EventBus.player_died`. RED: method hilang. GREEN: PASS.
Final: minor (fixed opportunistically): #5 instance `floating_text.tscn` yang melanggar kontrak di-`free()` sebelum fallback; #6 normal ZERO di-fallback ke `Vector2.UP`.
Final: minor (deferred): #7 kontrak z-order untuk T-038; #8 skor setelah GAME_OVER; #9 cakupan `reset_run()`; #10 engine kehabisan voice; #11 generator baru per pemutaran. Diserahkan ke phase pemiliknya (T-025/T-034/T-038) atau dianggap optimasi.
Final: verification — `res://tests/phase1_review_check.tscn` PASS exit 0 dua kali; `--headless --editor --quit` exit 0 tanpa ERROR/WARNING; harness, probe, dan fixture dihapus; tidak ada file baru di luar §2 + `docs/`.
