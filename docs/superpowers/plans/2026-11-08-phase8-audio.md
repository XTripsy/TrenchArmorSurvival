# Phase 8 — Audio & Juice Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the procedural audio layer (engine pitch, hit/enemy-fire/explosion SFX, 125 BPM loop, state-aware audio) and finish the readability pass on player/enemy silhouettes and effect z-order.

**Architecture:** `AudioManager` owns all synthesis and subscribes to existing `EventBus` signals. Enemies and sandbags call `AudioManager` directly for their own fire/hit sounds. Readability is a scene-only change (colors + `Line2D` outlines); bullets already sit at `z_index = 20` above every effect layer.

**Tech Stack:** Godot 4.7 GDScript, `AudioStreamGenerator`, strict static typing, zero external assets.

**Spec:** `docs/superpowers/specs/2026-11-08-phase8-audio-design.md`

## Global Constraints

- Strict static typing on every `var`, parameter, and return type.
- Zero external assets: all audio synthesized in `audio_manager.gd`; no `.wav`/`.ogg` loading.
- No new `EventBus` signals. Use existing `player_damaged`, `player_died`, `enemy_destroyed`, `game_state_changed`.
- Headless audio uses the dummy driver: verify waveform data, player state, pitch, and wiring — not audible output.
- Folder is not a git repo: one task = ledger entry + harness run.
- Temporary harness under `tests/` is deleted before completion.
- Godot exe: `D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`.

## File Structure

- `autoloads/audio_manager.gd` — all Phase 8 audio (engine state, SFX, BGM, EventBus subscription). Single responsibility: audio.
- `scripts/enemies/base_enemy.gd` — hit SFX on damage.
- `scripts/environment/sandbag_barricade.gd` — hit SFX on damage.
- `scripts/enemies/enemy_artillery.gd`, `scripts/enemies/enemy_dreadnought.gd` — enemy cannon SFX.
- `scenes/enemies/enemy_scout.tscn`, `enemy_artillery.tscn`, `enemy_dreadnought.tscn`, `scenes/player/player.tscn` — silhouette outlines (Scout also recolored).
- `tests/phase8_check.gd` + `.tscn` — one growing harness, deleted in Task 5.

## Review Focus

1. **Rapid `play_engine` calls** must reuse the same voice and only change pitch; a second engine loop would stack volume and never stop. — pinned by Task 1.
2. **Pause then resume** must restore the exact moving/idle pitch remembered before the pause, not always idle. — pinned by Task 1.
3. **SFX voice reuse**: a BGM voice borrowed for a one-shot must not keep `-12 dB`. — pinned by Task 3 (volume reset in `_play`/`stop_bgm`).
4. **Fatal hit ordering**: a lethal `player_damaged` emits hit, then `player_died` emits explosion; the final `last_sfx` must be `explosion` and the engine must stop. — pinned by Task 2.
5. **Hit SFX isolation**: a non-fatal enemy hit must report `hit`, not the explosion of a killed enemy; a killed enemy must report `explosion`. — pinned by Task 2.

---

### Task 1: Engine loop + state-aware audio (T-035)

**Files:**
- Modify: `autoloads/audio_manager.gd`
- Create: `tests/phase8_check.gd`
- Create: `tests/phase8_check.tscn`

**Interfaces:**
- Produces: `AudioManager.play_engine(moving: bool) -> void` reuses one voice; `AudioManager.stop_engine() -> void`; `AudioManager._on_game_state_changed(new_state: int) -> void`.
- Produces (internal, read by harness): `_engine_player: AudioStreamPlayer`, `_engine_moving: bool`.

- [ ] **Step 1: Write the harness skeleton with engine tests**

`tests/phase8_check.gd` extends `Node`, collects `_checks`/`_failures`, prints `PHASE8_CHECK: PASS (N checks)` or FAIL, `get_tree().quit(0/1)`. Helpers: `_check`, `_approx`, `_engine_player() -> AudioStreamPlayer` (via `AudioManager.get("_engine_player")`), `_playing_count() -> int` (players in `AudioManager.get("_players")` with `playing`).

Engine assertions:
- `AudioManager.play_engine(false)` → engine player non-null, `pitch_scale ≈ 0.85`, `_playing_count() == 1`.
- `AudioManager.play_engine(true)` → same player instance, `pitch_scale ≈ 1.15`, `_playing_count() == 1`.
- `GameManager.change_state(PAUSED)` → `_engine_player() == null` and `_playing_count() == 0`.
- `GameManager.change_state(PLAYING)` → engine player non-null, `pitch_scale ≈ 1.15` (moving remembered).
- `GameManager.change_state(MENU)` → engine null; `GameManager.change_state(PLAYING)` → engine non-null idle only after `play_engine(false)` (assert pitch ≈ 1.15 before that call, since `_engine_moving` is still true).
- `GameManager.change_state(GAME_OVER)` → engine null.
- Restore: `GameManager.change_state(MENU)`, `AudioManager.stop_engine()`.

Wire `_run_all()` to call `await _test_engine()`.

- [ ] **Step 2: Run harness to verify it fails**

Run: `& $GODOT --headless --path . res://tests/phase8_check.tscn`
Expected: FAIL — `_engine_player` is not stopped on state change.

- [ ] **Step 3: Implement engine state in `audio_manager.gd`**

- Add `var _engine_moving: bool = false`.
- `play_engine(moving)` stores `_engine_moving = moving`; if `_engine_player` exists but `not _active.has(_engine_player)`, clear it; if present, set `pitch_scale` and return; otherwise `_engine_player = _play(_engine, pitch, true)`.
- `stop_engine()` unchanged (stop, erase from `_active`, null out).
- `_ready()`: replace `EventBus.player_died.connect(stop_engine)` with `EventBus.player_died.connect(_on_player_died)` and `EventBus.game_state_changed.connect(_on_game_state_changed)`. Add `_on_player_died()` that calls `stop_engine()` (Task 2 extends it).
- `_on_game_state_changed(new_state: int)`:
  - `PLAYING` → if `_engine_player == null`, `play_engine(_engine_moving)`.
  - any other state → `stop_engine()`.

Do not add BGM here; Task 3 extends this handler.

- [ ] **Step 4: Run harness to verify it passes**

Expected: engine checks PASS, exit 0.

- [ ] **Step 5: Ledger**

`Task 1: complete (tests: phase8_check engine → PASS)`.

---

### Task 2: SFX wiring + `last_sfx` (T-036)

**Files:**
- Modify: `autoloads/audio_manager.gd`
- Modify: `scripts/enemies/base_enemy.gd`
- Modify: `scripts/environment/sandbag_barricade.gd`
- Modify: `scripts/enemies/enemy_artillery.gd`
- Modify: `scripts/enemies/enemy_dreadnought.gd`
- Modify: `tests/phase8_check.gd`

**Interfaces:**
- Produces: `AudioManager.play_hit() -> void`, `AudioManager.play_enemy_cannon() -> void`, `AudioManager.last_sfx: StringName`, `AudioManager._on_player_damaged(current_hp: int, max_hp: int) -> void`, `AudioManager._on_enemy_destroyed(enemy_position: Vector2, base_score: int, was_ricochet: bool) -> void`.
- Produces: `_render_hit() -> PackedVector2Array`.

- [ ] **Step 1: Add SFX tests**

- `last_sfx` starts `&""`; after `play_cannon()` → `&"cannon"`; `play_explosion()` → `&"explosion"`; `play_ricochet()` → `&"ricochet"`; `play_engine(false)` → `&"engine"`.
- `play_hit()` → `&"hit"` and the hit buffer has peak > 0.05.
- `play_enemy_cannon()` → `&"enemy_cannon"` and its voice pitch ≈ 0.8.
- Emit `EventBus.player_damaged.emit(2, 3)` → `&"hit"`.
- Emit `EventBus.enemy_destroyed.emit(Vector2(100, 100), 100, false)` → `&"explosion"`.
- Fatal: `AudioManager.play_engine(true)` then `EventBus.player_died.emit()` → `last_sfx == &"explosion"`, engine null. Restore state `MENU`.
- Call sites (instantiate under the harness root, await one frame):
  - Scout with `hp = 3` → `take_damage(1)` → `last_sfx == &"hit"` (survives, so no explosion overwrites it). Set `hp = 1` → `take_damage(1)` → `last_sfx == &"explosion"`.
  - Sandbag → `take_damage(1)` → `&"hit"`.
  - Artillery → `_fire(player_stub)` → `&"enemy_cannon"`.
  - Dreadnought → `_fire(player_stub)` → `&"enemy_cannon"`.
  - Free every spawned node and every spawned bullet (`scripts/projectiles/enemy_bullet.gd`) afterwards.

`player_stub` is a `Node2D` added under the harness root at `Vector2(100, 100)`.

- [ ] **Step 2: Run harness to verify it fails**

Expected: FAIL — `play_hit`/`play_enemy_cannon`/`last_sfx` missing.

- [ ] **Step 3: Implement SFX in `audio_manager.gd`**

- `var last_sfx: StringName = &""`.
- Add `_hit: PackedVector2Array`; in `_ready`: `_hit = _render_hit()`.
- `_render_hit()`: 0.18 s + `ONE_SHOT_TAIL`; noise burst with `exp(-t / 0.03)` envelope plus `sin(TAU * 520.0 * t) * 0.3`, clamped, seeded RNG.
- `play_cannon/play_ricochet/play_explosion` set `last_sfx` before `_play` (`&"cannon"`, `&"ricochet"`, `&"explosion"`).
- `play_hit()` → `last_sfx = &"hit"`, `_play(_hit, randf_range(0.95, 1.05), false)`.
- `play_enemy_cannon()` → `last_sfx = &"enemy_cannon"`, `_play(_cannon, 0.8, false)`.
- `play_engine` sets `last_sfx = &"engine"`.
- `_ready()`: connect `player_damaged` → `_on_player_damaged`, `enemy_destroyed` → `_on_enemy_destroyed`. `_on_player_damaged` calls `play_hit()`; `_on_enemy_destroyed` calls `play_explosion()`.
- `_on_player_died()`: `stop_engine()` then `play_explosion()`.

- [ ] **Step 4: Wire call sites**

- `base_enemy.gd` `take_damage()`: after the `_alive` guard, `AudioManager.play_hit()`.
- `sandbag_barricade.gd` `take_damage()`: after the `_alive` guard, `AudioManager.play_hit()`.
- `enemy_artillery.gd` `_fire()` and `enemy_dreadnought.gd` `_fire()`: first line `AudioManager.play_enemy_cannon()`.

Do not add a hit call inside `die()`.

- [ ] **Step 5: Run harness to verify it passes**

Expected: SFX checks PASS, exit 0.

- [ ] **Step 6: Ledger**

`Task 2: complete (tests: phase8_check SFX → PASS)`.

---

### Task 3: Procedural 125 BPM BGM (T-037)

**Files:**
- Modify: `autoloads/audio_manager.gd`
- Modify: `tests/phase8_check.gd`

**Interfaces:**
- Produces: `AudioManager.start_bgm() -> void`, `AudioManager.stop_bgm() -> void`, `AudioManager.is_bgm_playing() -> bool`, `_render_bgm() -> PackedVector2Array`.
- Produces: constants `BGM_BPM = 125.0`, `BGM_BARS = 2`, `BGM_VOLUME_DB = -12.0`; fields `_bgm: PackedVector2Array`, `_bgm_player: AudioStreamPlayer`.
- Consumes: Task 1 `_on_game_state_changed`.

- [ ] **Step 1: Add BGM tests**

- `_bgm.size() == 84672`.
- Peak sample absolute value > 0.05.
- For each of the 8 beat starts (`i * 10584`), RMS over the first 1102 frames > 0.02 (kick/hat transient present).
- `start_bgm()` → `is_bgm_playing()` true, `last_sfx == &"bgm"`, `_bgm_player.volume_db ≈ -12.0`, and `_active[_bgm_player]["loop"] == true`.
- `start_bgm()` again → same `_bgm_player` instance (no second BGM voice).
- `stop_bgm()` → `is_bgm_playing()` false, `_bgm_player == null`, and the freed voice has `volume_db ≈ 0.0`.
- State flow: `change_state(PLAYING)` → BGM playing and engine non-null; `change_state(PAUSED)` → both stopped; `change_state(PLAYING)` → both playing; `change_state(GAME_OVER)` → both stopped; `change_state(MENU)` → both stopped.
- Voice reuse: after `stop_bgm()`, `play_cannon()` still reports `last_sfx == &"cannon"` and the cannon voice is at `volume_db ≈ 0.0`.

- [ ] **Step 2: Run harness to verify it fails**

Expected: FAIL — `start_bgm` missing.

- [ ] **Step 3: Implement BGM in `audio_manager.gd`**

- `_play()`: set `player.volume_db = 0.0` before `player.play()` so a recycled voice never inherits BGM attenuation.
- `start_bgm()`: if `is_bgm_playing()` return; `last_sfx = &"bgm"`; `_bgm_player = _play(_bgm, 1.0, true)`; if non-null set `volume_db = BGM_VOLUME_DB`.
- `stop_bgm()`: if `_bgm_player == null` return; `volume_db = 0.0`, `stop()`, erase from `_active`, set null.
- `is_bgm_playing()`: `_bgm_player != null and _active.has(_bgm_player)`.
- `_exit_tree()`: also stop/null `_bgm_player`.
- `_on_player_died()`: add `stop_bgm()` after `stop_engine()`.
- `_on_game_state_changed`: `PLAYING` → resume engine if needed, then `start_bgm()`; other states → `stop_engine()` and `stop_bgm()`.
- `_render_bgm()`: frame count `int(MIX_RATE * float(BGM_BARS * 4) * 60.0 / BGM_BPM)`; kick (60→45 Hz sweep, `exp(-t/0.06)`, amp 0.55) on every beat; snare (seeded noise, `exp(-t/0.05)`, amp 0.35) on beats 2 and 4 of each bar; hi-hat (seeded noise, `exp(-t/0.015)`, amp 0.16) every half beat; drone `sin(55 Hz)*0.12 + sin(82.5 Hz)*0.08`; sum, `clampf` to `[-1, 1]`; 0.01 s fade-in/out at both ends.

- [ ] **Step 4: Run harness to verify it passes**

Expected: BGM checks PASS, exit 0.

- [ ] **Step 5: Ledger**

`Task 3: complete (tests: phase8_check BGM → PASS)`.

---

### Task 4: Readability pass (T-038)

**Files:**
- Modify: `scenes/enemies/enemy_scout.tscn`
- Modify: `scenes/enemies/enemy_artillery.tscn`
- Modify: `scenes/enemies/enemy_dreadnought.tscn`
- Modify: `scenes/player/player.tscn`
- Modify: `tests/phase8_check.gd`

**Interfaces:**
- Produces: `Visual/Outline` (`Line2D`) in all three enemy scenes; `HullVisual/Outline` (`Line2D`) in the player scene.
- Consumes: `VFXManager.spawn_tank_explosion()`, `VFXManager.spawn_ricochet_sparks()` for z-order sampling.

- [ ] **Step 1: Add readability tests**

- Scout `Visual.color` ≈ `Color("#8B3A3A")`; `Visual/Outline` exists with ≥ 6 points, closed (first == last), `default_color ≈ #D9C9A3`, `width ≈ 1.5`.
- Artillery and Dreadnought `Visual/Outline` exist, closed, same color/width; their `Visual.color` unchanged (`#36393F`, `#8B3A3A`).
- Player `HullVisual/Outline` exists, closed, `default_color ≈ #E8D9A0`; `HullBody.color ≈ #556B2F`.
- Player bullet and enemy bullet roots have `z_index == 20`; visual colors `≈ #FFD700` and `≈ #FF2222`.
- Z-order: snapshot every existing `CanvasItem` instance ID under the harness root, call `VFXManager.spawn_tank_explosion(Vector2(300, 300))` and `VFXManager.spawn_ricochet_sparks(Vector2(320, 300), Vector2.UP)`, await one frame, then collect `z_index` only from `CanvasItem` nodes whose ID is new; assert the set contains `{-1, 5, 9, 10, 15}` and `max(effect_z) < 20`. Free all new effect nodes afterwards.

- [ ] **Step 2: Run harness to verify it fails**

Expected: FAIL — Scout is brown and outlines are missing.

- [ ] **Step 3: Update enemy scenes**

- Scout `Visual.color = Color(0.545098, 0.227451, 0.227451, 1)`.
- Add a `Line2D` named `Outline` as the first child of each `Visual`, points equal to the visual polygon plus the first point repeated, `width = 1.5`, `default_color = Color(0.85098, 0.788235, 0.639216, 1)` (`#D9C9A3`).

Polygons:
- Scout: `(-16,-12),(12,-12),(20,0),(12,12),(-16,12),(-12,0),(-16,-12)`.
- Artillery: `(-18,-12),(12,-12),(18,-6),(18,6),(12,12),(-18,12),(-18,-12)`.
- Dreadnought: `(-24,-18),(20,-18),(24,-8),(24,8),(20,18),(-24,18),(-24,-18)`.

- [ ] **Step 4: Update the player scene**

Add `Outline` (`Line2D`) under `HullVisual` with points `(18,-14),(18,14),(-16,14),(-18,10),(-18,-10),(-16,-14),(18,-14)`, `width = 1.5`, `default_color = Color(0.909804, 0.85098, 0.627451, 1)` (`#E8D9A0`). Insert it after `TrackRight` so it draws over both the hull and the tracks.

- [ ] **Step 5: Run harness to verify it passes**

Expected: readability checks PASS, exit 0.

- [ ] **Step 6: Ledger**

`Task 4: complete (tests: phase8_check readability → PASS)`.

---

### Task 5: Final verification, docs, cleanup

**Files:**
- Delete: `tests/`
- Modify: `TODO_TrenchArmorSurvival.md`
- Modify: `docs/superpowers/plans/2026-11-08-phase8-audio.progress.md`

- [ ] **Step 1: Run the harness one final time**

Run: `& $GODOT --headless --path . res://tests/phase8_check.tscn`
Expected: `PHASE8_CHECK: PASS (N checks)`, exit 0.

- [ ] **Step 2: Delete the harness**

Remove `tests/`. Expected: `tests/` absent.

- [ ] **Step 3: Editor validation**

Run: `& $GODOT --headless --path . --editor --quit`
Expected: exit 0, no `ERROR`/`Parse Error`/`WARNING`.

- [ ] **Step 4: Main-scene validation**

Run: `& $GODOT --headless --path . --quit`
Expected: exit 0.

- [ ] **Step 5: Update `TODO_TrenchArmorSurvival.md`**

- Mark T-035..T-038 `[x]`.
- Snapshot → `2026-11-08 · Engine 4.7.2.stable.steam.ed1daf0bf · Next: Phase 9 (T-039..T-046)`.
- Add the Phase 8 table row, summary, verification evidence, rulings, and links to the Phase 8 spec/plan/ledger.

- [ ] **Step 6: Final ledger entry**

Record harness result, editor validation, main-scene validation, and harness removal.
