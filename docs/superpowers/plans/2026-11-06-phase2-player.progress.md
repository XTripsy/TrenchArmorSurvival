# SDD ledger — plan: docs/superpowers/plans/2026-11-06-phase2-player.md

Status: complete (Phase 2 reviewed; 1 Important fixed).

Pre-flight: Task 1 produces `player.tscn` + hierarki + `class_name PlayerTank` yang dipakai Task 2..5; Task 2 produces `_physics_process`/`has_input` yang diperluas Task 3; Task 3 produces `_fire`/`_fire_cooldown_left` yang dipakai harness Task 4; Task 4 produces `take_damage`/`_alive`/`tread_timer` yang dipakai Task 5. Tidak ada kontradiksi interface; urutan T-009 → T-010 → T-011 → T-012 → T-013.

Ruling: bukan git repo — tidak ada worktree/commit; ledger ini menggantikan commit. Biaya jika salah: tidak ada diff per task, hanya catatan teks + hasil tes.

Ruling: harness tetap satu scene bertumbuh (`tests/phase2_check.tscn`) seperti Phase 1, bukan tes terpisah per task. Biaya jika salah: kegagalan task lama ikut terlihat di run task baru (justru diinginkan).

Task 1: Ruling: stub `class_name PlayerTank` dibuat sebelum run RED karena harness memakai tipe itu (tanpa stub, harness gagal parse, bukan gagal karena scene hilang). Tes tetap RED pada `player.tscn belum ada`. Biaya jika salah: urutan pembuatan file, bukan perilaku.
Task 1: complete (no commits; `res://tests/phase2_check.tscn` → PASS exit 0; hierarki, grup, layer 1, mask 54, hitbox 36×36, motion FLOATING, Timer 0.05, posisi (640,360))

Task 2: Ruling: deklarasi state (`hp`, `speed_multiplier`) ditambahkan sebelum run RED karena GDScript bertipe statis tidak bisa mengompilasi akses member yang belum ada; perilaku tetap belum diimplementasikan sehingga RED gagal pada gerak, bukan parse. Biaya jika salah: urutan penulisan file.
Task 2: complete (no commits; harness → PASS exit 0; gerak 8 arah, hull hanya berputar saat input, aim kursor, speed_multiplier 0.5, tertahan dinding layer 3, diam saat pause)

Task 3: Ruling: posisi dasar barrel disimpan sekali (`_turret_base_x`) saat `_ready`, bukan diambil dari posisi saat ini tiap tembakan; kalau tween lama di-kill di tengah recoil, base yang bergeser membuat barrel melayang mundur. Biaya jika salah: recoil terlihat sedikit meleset setelah tembakan cepat.
Task 3: complete (no commits; harness → PASS exit 0; cooldown 0.45, recoil 200, barrel kembali, shake (2.0,0.1), VFX/audio, aman tanpa `player_bullet.tscn`)

Task 4: complete (no commits; harness → PASS exit 0; hp 3→2→0, damage ganda diabaikan, hit-stop 0.05, shake (12.0,0.35), hit flash 0.1s, `player_died` sekali, visual hilang, tidak bisa menembak setelah mati)

Task 5: Ruling: harness menghitung jejak roda lewat `Line2D.z_index == -2`, bukan prefix nama node. Godot mengganti nama sibling duplikat menjadi `@TreadMark@N`, sehingga hitungan berbasis prefix hanya menemukan satu node walau jejak benar-benar ada. Biaya jika salah: tidak ada — ini hanya cara tes menghitung, scene tetap memakai nama `TreadMark`.
Task 5: complete (no commits; harness → PASS exit 0 dua kali; jejak hanya saat bergerak, 2 titik/potongan, parent world bukan player, z -2, width 5.0, warna #2E241E, hilang setelah ~3 s, tidak bertambah saat idle)

Status: complete (Phase 2 reviewed; 1 Important fixed). Harness `tests/` dihapus; `--headless --editor --quit` exit 0 tanpa `ERROR`/`Parse Error`; hanya file §2 + `docs/` yang tersisa.

## Review akhir Phase 2

Reviewer fresh-context: **0 Critical, 1 Important, 7 Minor**. Verdict: *with fixes*.

### Important #1 — urutan `direction` vs `add_child` (DIPERBAIKI, RED→GREEN)
- Masalah: `direction` diisi setelah `add_child`; `_ready()` peluru berjalan sinkron di dalam `add_child`, jadi T-014 yang menghitung `velocity = direction * SPEED` di `_ready()` akan mendapat `Vector2.ZERO`.
- RED: harness sementara + fake `player_bullet.tscn` → `FAIL: peluru tidak menerima direction sebelum _ready (velocity=(0.0, 0.0))`, exit 1.
- Fix: `player.gd` mengisi `direction` sebelum `add_child`, lalu position/rotation setelah masuk tree.
- GREEN: harness yang sama → `PASS`, exit 0. Fake bullet + harness dihapus; `scenes/projectiles/` kembali tidak ada.
- Bukti tambahan di harness yang sama: dua `take_damage` seframe → hp turun sekali; `look_at()` tepat di tank → recoil tetap 200 tanpa NaN; `CollisionShape2D.disabled` true setelah mati; jejak saat berbelok tetap 2 titik/segmen dan habis setelah 3.4 s.

### Minor — ruling
- #1 `IFRAME_DURATION` tidak dipakai → **diperbaiki**: jumlah siklus blink dihitung dari `IFRAME_DURATION / 0.2` (hasil tetap 6).
- #2 `_die()` belum meng-kill `_recoil_tween` / reset modulate & barrel → **ditunda ke T-034**. Alasan: tidak ada leak (tween selesai sendiri), visual langsung disembunyikan, dan T-034 memang mengurus reset state saat restart. Biaya jika salah: satu tween 0.17 s berjalan pada node tak terlihat.
- #3 parent `current_scene` bergantung pada root identity → **ditunda ke T-024**. Alasan: arena Phase 6 adalah `current_scene` di `(0,0)`, sehingga koordinat world benar; kasus F6 langsung hanya terjadi saat debug scene tunggal. T-024 sebaiknya menambah node world/effects atau `top_level`.
- #4 `is_invulnerable` diset setelah emit → **ditunda**. Alasan: tidak ada listener `player_damaged` yang memanggil `take_damage`; pemanggilan berurutan sudah aman karena `_start_iframes()` selesai sebelum call berikutnya. Biaya jika salah: hanya bila Phase 7 HUD/award menambah listener reentrant.
- #5 fallback aim-on-tank berbeda dari desain → **diperbaiki di dokumen**: `look_at()` vektor nol adalah no-op (sudut terakhir dipertahankan), bukan reset ke kanan; tidak ada NaN. Desain diperbarui.
- #6 celah bukti tes → **sebagian ditutup** oleh harness review (lihat Important #1). Sisa: cooldown/posisi saat hit-stop belum diuji langsung → dicatat untuk QA Phase 9.
- #7 status/checkbox/wording dokumen → **diperbaiki**: ledger `Status: complete`, plan diberi baris status, wording hit-stop dikoreksi.

### Verdict setelah fix
Important #1 selesai dan diverifikasi; tidak ada Critical. Phase 2 siap dilanjutkan ke Phase 3 (T-014..T-015).

- [x] Task 1 — `player.tscn` + stub `PlayerTank` (T-009)
- [x] Task 2 — gerak/aim (T-010)
- [x] Task 3 — tembakan/recoil (T-011)
- [x] Task 4 — damage/i-frames (T-012)
- [x] Task 5 — jejak roda + bersih-bersih (T-013)
