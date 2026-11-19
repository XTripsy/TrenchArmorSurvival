# SDD ledger — plan: docs/superpowers/plans/2026-11-08-phase6-arena.md

Pre-flight: shared file is `scenes/arena.tscn`; Task 1 creates it, Tasks 2 and 3 attach scripts to existing child nodes. The harness `tests/phase6_check.tscn` is shared and extended per task. Shared interfaces: `Arena/Enemies`, `Arena/Camera2D`, `Arena/WaveDirector.spawn_interval/pick_enemy_type/reset`.

Task tracker:
- [x] Task 1 — `scenes/arena.tscn` + `arena_controller.gd` (T-024) + harness skeleton
- [x] Task 2 — `camera_shake.gd` (T-025)
- [x] Task 3 — `wave_director.gd` (T-026)
- [x] Task 4 — T-027 single-shake verification + full verification + docs + cleanup

## Execution log

- Task 1: complete (tests: `phase6_check` arena + gate checks → PASS 119/119, exit 0)
  - Ruling: artillery stops at its 350 px engage range, which for top/bottom gates is exactly the gate mouth (`y ≈ 10`), not a wall collision. The gate-entry assertion therefore measures "distance to center decreased ≥ 40 px and the enemy stayed inside the 90 px gate corridor", which proves the opening is traversable without requiring artillery to cross the inner wall plane. Cost if wrong: an enemy could theoretically path through a gap without reaching deep into the arena.
- Task 2: complete (tests: `phase6_check` camera shake checks → PASS 127/127, exit 0)
  - Ruling: the offset uses a random unit vector (`Vector2.from_angle(randf() * TAU)`), so the offset magnitude equals `intensity * falloff` exactly. The harness can assert magnitude deterministically while the direction stays random. Cost if wrong: direction is still random, so no behavior change.
- Task 3: complete (tests: `phase6_check` wave director checks → PASS 164/164, exit 0)
  - Ruling: gate markers are filtered with `_arena.is_ancestor_of(node)` instead of taking every `"spawn_gate"` node in the tree. This keeps spawns inside the owning arena when a harness or later UI instantiates more than one. Cost if wrong: gates placed outside the arena root would be ignored.
  - Ruling: `t=0 always spawns a scout` asserts `scene_file_path`, because `get_script().resource_path` points at the enemy script, not the scene. Cost if wrong: none.
  - Note: one harness run exited with a Windows access violation (`0xC0000005`) after printing PASS; an immediate rerun exited 0. Treated as a Godot shutdown race while queued nodes/timers are freed, and rechecked in the final full run.
- Task 4: complete (tests: full `phase6_check` → PASS 167/167, exit 0; `--headless --editor --quit` → exit 0; harness deleted)
  - Ruling: T-027 needed no code. `VFXManager` has exactly one `enemy_destroyed` handler, and one emission produced exactly one `camera_shake_requested(5.0, 0.2)`. No second connection was added.
  - Final full run after adding T-027 exited 0, so the earlier access violation did not recur.