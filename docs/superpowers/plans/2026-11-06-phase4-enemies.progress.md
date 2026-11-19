# SDD ledger — plan: docs/superpowers/plans/2026-11-06-phase4-enemies.md

Pre-flight: `BaseEnemy` produced by Task 1 is consumed by Task 2 (`EnemyScout`), Task 3 (`EnemyArtillery`), and Task 4 (`EnemyDreadnought`). `enemy_bullet.tscn` from Phase 3 is consumed by Task 3 & 4. All signatures match design spec.

Task tracker:
- [x] Task 1 — `scripts/enemies/base_enemy.gd` (T-016)
- [x] Task 2 — `enemy_scout.tscn` + `enemy_scout.gd` (T-017)
- [x] Task 3 — `enemy_artillery.tscn` + `enemy_artillery.gd` (T-018)
- [x] Task 4 — `enemy_dreadnought.tscn` + `enemy_dreadnought.gd` (T-019, T-020) + test verification

## Execution log

Code Task 1–4 already existed from the 2026-11-06 session; Task 4 was left unverified and the tracker stopped at `[ ]`. This session verified all of Phase 4 against the plan/spec and fixed the deviations the harness exposed.

- 2026-11-08 — Created temporary harness `tests/phase4_check.tscn` + `tests/phase4_check.gd` per plan Task 4 Step 3.
- Run 1: `9 of 48 checks failed`. 6 were harness timing bugs (`await get_tree().physics_frame` resumes before `_physics_process`, so velocity was sampled before the tick); 3 were real `collision_mask` deviations.
- Run 2 (timing fixed): `3 of 50 checks failed`, all `collision_mask == 47`.
- Fixed `collision_mask = 61` → `47` on all three enemy scenes; aligned `FireTimer.autostart` `true` → `false` with the design.
- Run 3: `PHASE4_CHECK: PASS (50 checks)`, exit 0.
- `--headless --editor --quit` → exit 0, no `ERROR` / `Parse Error` / `WARNING`.
- Harness deleted; `tests/` removed.

Task 4: complete (tests: `godot --headless --path . res://tests/phase4_check.tscn` → PASS 50/50, exit 0)

## Rulings

- Ruling: Verify with a fake player (`StaticBody2D`, group `"player"`, `take_damage`) instead of the real `PlayerTank` — isolates contact/bullet behaviour from player movement, i-frames, and VFX, and keeps the harness deterministic — cost if wrong: player-specific integration (i-frames, death) is not exercised here, but it is covered by Phase 2 tests.
- Ruling: Sample velocity after two `physics_frame` awaits — `SceneTree.physics_frame` is emitted immediately before `_physics_process`, so a single await reads the value from before the tick — cost if wrong: velocity assertions could be off by one tick.
- Ruling: Accelerate `FireTimer` to 0.1 s only inside the harness — avoids waiting 2.5/3.5 s per test; the real intervals are verified separately via `FireTimer.wait_time` — cost if wrong: the timer's real cadence is not observed in real time, only its configured value and the firing path.
- Ruling: `collision_mask 61` → `47` (layers 1,2,3,4,6) on all enemy scenes — TODO §1.6 and the Phase 4 design are the binding authority — cost if wrong: if the intended mask really included EnemyBullet and excluded Enemy, enemies would now collide with each other as specified.
- Ruling: `FireTimer.autostart` `true` → `false` — matches the design; Godot auto-resets `autostart` to false when the timer enters the tree and `_ready()` calls `start()` anyway, so behaviour is unchanged — cost if wrong: none observed.
- Ruling: Keep `get_player() -> Node2D` — the implementation plan (Task 1 Interfaces) says `Node2D`; the design writes `-> PlayerTank`. The helper only needs group lookup — cost if wrong: a caller expecting a `PlayerTank`-typed return must cast.
