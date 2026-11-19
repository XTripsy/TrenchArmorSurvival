# SDD ledger — plan: docs/superpowers/plans/2026-11-06-project-setup.md

Pre-flight: Tasks 1-4 semuanya mengubah `project.godot` dan `verify_setup.gd` secara berurutan; tidak ada interface yang saling bertabrakan.

Ruling: folder ini bukan git repo dan desain menetapkan `git init` sebagai non-goal — tidak ada worktree, dan langkah commit diganti validasi + ledger. Biaya jika salah: tidak ada riwayat commit; bisa di-init kapan saja tanpa kehilangan file.

Task 1: Ruling: `const EXPECTED_FOLDERS: PackedStringArray = PackedStringArray([...])` bukan constant expression di GDScript 4.7 — diganti `const EXPECTED_FOLDERS: Array[String] = [...]`. Biaya jika salah: tidak ada, hanya tipe koleksi.

Task 1: complete (no commits — bukan git repo; `verify_setup.gd` → PASS exit 0; `--editor --quit` → EXIT=0 tanpa parse error)

Task 2: complete (no commits; `verify_setup.gd` → PASS exit 0; 6 action + 8 key + LMB terverifikasi)

Task 3: complete (no commits; `verify_setup.gd` → PASS exit 0; 6 layer name terverifikasi)

Task 4: complete (no commits; `verify_setup.gd` → PASS exit 0 dengan 4 autoload terdaftar & file ada; `--editor --quit` → EXIT=0; `verify_setup.gd` + `.uid` dihapus)

Final review: fresh subagent reviewer, no Critical/Important findings, verdict "Ready to merge: Yes".

Final: minor (deferred): AGENT PROTOCOL TODO item 9 (`godot --headless --quit`) belum bisa jadi smoke test sampai T-028 punya main scene — pakai `--headless --editor --quit` dulu.
Final: minor (deferred): `physics/2d/default_gravity` masih 980; tidak dipakai Phase 0, tapi debris RigidBody2D nanti akan jatuh ke bawah layar.
Final: minor (deferred): `*.gd.uid` adalah metadata engine 4.7 di luar daftar §2 — harus dipertahankan, jangan dihapus, dan di-commit saat git di-init.

Final: Ruling: ledger ini tidak dihapus setelah review (padahal executing-plans menyarankan workspace dihapus) karena tidak ada riwayat git yang menggantikannya. Biaya jika salah: satu file dokumentasi tambahan di `docs/`.
