# SDD ledger — plan: docs/superpowers/plans/2026-11-08-phase8-audio.md

Pre-flight: every task edits `autoloads/audio_manager.gd`, so tasks run in order 1→2→3. Task 4 touches only scenes and can run after the audio tasks because the harness already exists. The single harness `tests/phase8_check.tscn` grows with each task and is deleted in Task 5.

Task tracker:
- [x] Task 1 — engine state + state-aware audio (T-035)
- [x] Task 2 — hit/enemy-fire/explosion SFX + `last_sfx` (T-036)
- [x] Task 3 — procedural 125 BPM BGM (T-037)
- [x] Task 4 — readability pass (T-038)
- [x] Task 5 — full verification + docs + cleanup

## Execution log

- Task 1: complete (tests: `phase8_check` engine → PASS 14/14, exit 0)
  - Ruling: engine state tracks `_engine_moving` so pausing/resuming restores the moving/idle pitch accurately without resetting to idle. Cost if wrong: none.
- Task 2: complete (tests: `phase8_check` SFX → PASS 32/32, exit 0)
  - RED: 5/32 failed — `play_engine` did not set `last_sfx`, and the four call sites (BaseEnemy, Sandbag, Artillery, Dreadnought) did not call `AudioManager`.
  - Ruling: harness fixed, not production — `EnemyScout._ready()` forces `max_hp = 1`, so the non-fatal test must set `hp` after `_ready` (setting `max_hp` before `add_child` was overwritten). Cost if wrong: the test would keep exploding the scout instead of exercising a survivable hit.
  - Ruling: the `last_sfx initial empty` check moved to the start of `_run_all`, before the engine tests — Task 1's `play_engine` now legitimately sets `last_sfx = &"engine"`. Cost if wrong: none.
- Task 3: complete (tests: `phase8_check` BGM → PASS 58/58, exit 0)
  - RED: 3 BGM buffer checks failed, then after the method-existence guards the missing `start_bgm` was the expected failure.
  - Ruling: harness waits for the voice pool to go idle before BGM assertions (`_wait_for_idle_voices`). The SFX tests start ~15 one-shots inside a few milliseconds; with 8 voices and real-time dummy playback the pool is still busy, so `_play` legitimately returns null and BGM never starts. The wait isolates the test instead of changing the voice count. Cost if wrong: BGM assertions become timing-dependent (3 s ceiling, then fail loudly).
  - Ruling: BGM render adds per-beat kick/snare/hat into a zero-filled buffer, then adds the drone and a 0.01 s edge fade in one final pass. Keeps the loop click-free and the beat transients measurable. Cost if wrong: none.
- Task 4: complete (tests: `phase8_check` readability → PASS 74/74, exit 0)
  - RED: 7/74 failed — Scout still brown, and no `Outline` on Scout/Artillery/Dreadnought/player hull.
  - Ruling: outlines are the first child of each enemy `Visual` and the last child of `HullVisual`, so the enemy barrel still draws over its plate and the player outline draws over both tracks. Cost if wrong: purely draw-order, no behavior.
- Task 5: complete — final harness `phase8_check` → PASS 74/74, exit 0; `--headless --editor --quit` exit 0 (no ERROR/WARNING); `--headless --quit` exit 0; TODO snapshot/table/summary/evidence/rulings/links updated. After the review fix, `phase8_retry_check` → PASS 4/4, `tests/` deleted again, and both headless validations re-run clean.
- Final review (subagent, fresh context): 0 Critical, 1 Important, 3 Minor.
- Final: fixed voice-pool recovery — a busy redeploy could leave engine and BGM silent for the whole run because `start_bgm`/`play_engine` fail once and never retry. `tests/phase8_retry_check.tscn` RED (recovery failed) → GREEN 4/4, exit 0; fix is `AudioManager._retry_playback()` (retries engine/BGM while `PLAYING` as soon as `_find_voice()` returns one).
- Final: minor (deferred): BGM is synthesized synchronously in `_ready` and the buffer zero-fill loop is redundant — one-time startup cost only.
- Final: minor (deferred): Scout `Bumper` draws over the nose of the closed outline — cosmetic.
- Final: minor (deferred): enemy `_fire()` plays the cannon before validating `BULLET_SCENE` — a dry shot if the scene ever disappears, unreachable under the zero-asset guarantee.
- Post-plan audit (2026-11-09): full Phase 1–8 flow audit found one user-facing bug outside Phase 8 — the system cursor stayed hidden while paused and on game over, leaving no visible pointer over menu buttons. Fixed in `scripts/ui/pause_menu.gd` (show on pause, hide on resume) and `scripts/ui/game_over_menu.gd` (show when stats appear). Windowed `phase_audit` RED 2/47 (pause + game over) → GREEN 59/59; headless 53/53; editor/main/windowed startup clean; `tests/` deleted.
