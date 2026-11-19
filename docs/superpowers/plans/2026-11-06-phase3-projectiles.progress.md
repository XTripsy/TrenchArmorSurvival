# SDD ledger — plan: docs/superpowers/plans/2026-11-06-phase3-projectiles.md

Status: complete (Phase 3 reviewed; lihat bagian akhir).

Pre-flight: Task 1 produces `PlayerBullet` (scene, class, vars) consumed by Task 2's shared harness (player checks must stay green) — no conflict; Task 2 produces `EnemyBullet` and only adds checks/helpers. `_run_checks()` is extended, not replaced. Urutan T-014 → T-015.

Ruling: bukan git repo — tidak ada worktree/commit; ledger ini menggantikan commit. Biaya jika salah: tidak ada diff per task, hanya catatan teks + hasil tes.

Ruling: satu harness bertumbuh (`tests/phase3_check.tscn`), bukan tes terpisah per task, konsisten dengan Phase 2. Biaya jika salah: kegagalan task lama ikut terlihat di run task baru (diinginkan).

Ruling: stub `class_name PlayerBullet`/`EnemyBullet` ditulis sebelum run RED karena harness memakai tipe itu; tanpa stub harness gagal parse, bukan gagal karena scene hilang. Biaya jika salah: urutan penulisan file.

Task tracker:
- [x] Task 1 — `player_bullet.tscn` + `player_bullet.gd` (T-014)
- [x] Task 2 — `enemy_bullet.tscn` + `enemy_bullet.gd` (T-015) + bersih-bersih

Task 1: Ruling: `Callable` lambda di GDScript menangkap variabel lokal by value, jadi counter `int` tidak akan terlihat berubah di luar lambda; tes memakai `Array[bool]` dan `size()`. Biaya jika salah: tidak ada — hanya cara tes menghitung sinyal.
Task 1: complete (no commits; harness → PASS exit 0; speed 650, layer 8/mask 6, pantul 1×, oranye, sinyal sekali + sparks tunggal, impact kedua hancur, damage normal/ricochet, player aman, off-screen cleanup)

Task 2: Ruling: tes integrasi `player._fire()` ditambahkan di luar daftar rencana untuk membuktikan kontrak `direction` sebelum `add_child` bekerja dengan scene nyata (sebelumnya hanya fake bullet Phase 2). Biaya jika salah: satu tes tambahan, bukan perubahan produksi.
Task 2: complete (no commits; harness → PASS exit 0 dua kali; speed dari penembak 350, layer 16/mask 5, damage player 1 HP, hancur di dinding tanpa memantul, damage cover, off-screen cleanup, player menembakkan peluru nyata 650)

Status: complete. Harness `tests/` dihapus; `--headless --editor --quit` exit 0 tanpa `ERROR`/`Parse Error`; hanya file §2 + `docs/` yang tersisa.

## Review akhir Phase 3

Reviewer fresh-context: **0 Critical, 1 Important, 2 Minor**. Verdict: *Ready to proceed (Yes)*.

### Important #1 — Viewport vs World space cleanup (DIPERBAIKI)
- Masalah: `get_viewport().get_visible_rect()` mengembalikan koordinat viewport, sedangkan peluru di world space. Kalau kamera bergeser (Phase 6), peluru bisa terhapus prematur.
- Fix: Transformasikan visible rect ke world space dengan `get_canvas_transform().affine_inverse()`.
- Verifikasi: Diimplementasikan di `player_bullet.gd` & `enemy_bullet.gd`; editor & harness PASS.

### Minor
- #1 Tunneling pada kecepatan 650 px/s (dinding arena Phase 6 harus ≥20 px).
- #2 Guard clause `collider == null` diselaraskan di `enemy_bullet.gd`.
