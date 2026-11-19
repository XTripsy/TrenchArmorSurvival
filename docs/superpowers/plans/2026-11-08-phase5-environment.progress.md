# SDD ledger — plan: docs/superpowers/plans/2026-11-08-phase5-environment.md

Pre-flight: no shared interfaces between the three tasks; SteelBunker, SandbagBarricade, and MudCrater are independent scenes. The harness `tests/phase5_check.tscn` is shared and extended per task.

Task tracker:
- [x] Task 1 — `scenes/environment/steel_bunker.tscn` (T-021) + harness skeleton
- [x] Task 2 — `sandbag_barricade.tscn` + `sandbag_barricade.gd` (T-022)
- [x] Task 3 — `mud_crater.tscn` + `mud_crater.gd` (T-023)
- [x] Task 4 — full verification + docs + harness cleanup

## Execution log

- Task 1: complete (tests: `phase5_check` bunker checks → PASS 11/11, exit 0)
  - Ruling: the plan's original triangle `[(-48,-48),(48,48),(-48,48)]` would make a rightward bullet hit the left edge, not the hypotenuse. Flipped to `[(-48,48),(48,48),(48,-48)]` so the 45° face is the first surface hit; the assertion (`velocity.x ≈ 0`) is unchanged. Cost if wrong: the bunker visual faces the other diagonal.
- Task 2: complete (tests: `phase5_check` sandbag checks → PASS 29/29, exit 0)
  - Ruling: the harness types the sandbag root as `StaticBody2D` and reads `hp`/`_alive` via `get()` instead of referencing the `SandbagBarricade` class, so the test file parses before the script exists and produces a meaningful RED. Cost if wrong: none, the scene still uses the typed script.
  - Ruling: `_destroy()` hides `Visual` instead of the root, so the child debris particles remain visible. Cost if wrong: debris would be invisible if the root were hidden.
- Task 3: complete (tests: `phase5_check` mud checks → PASS 40/40, exit 0)
  - Ruling: the mud test uses an inner `FakeTank` (`StaticBody2D` with `speed_multiplier`) instead of a real `PlayerTank`/enemy, because Phase 4 already verified that all enemies consume `speed_multiplier` and `player.gd` multiplies movement by it. Cost if wrong: the Area2D signal path against the real tank nodes is not exercised here, but the property contract is identical.
  - Ruling: the harness types the crater as `Area2D` and reads scene properties directly, so it parses before `mud_crater.gd` exists and produces a meaningful RED. Cost if wrong: none.
- Task 4: complete (tests: full `phase5_check` → PASS 40/40, exit 0; `--headless --editor --quit` → exit 0; harness deleted)
