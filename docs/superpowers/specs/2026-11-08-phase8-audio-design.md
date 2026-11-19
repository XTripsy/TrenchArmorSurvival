# Phase 8 — Audio & Juice Polish Design (T-035..T-038)

Status: approved for implementation.
Scope: `autoloads/audio_manager.gd`, enemy/sandbag fire-hit wiring, readability changes in player/enemy scenes, BGM.

## Intent

Turn the already-working procedural SFX into a complete audio layer: engine pitch feedback, hits, enemy fire, explosions, a 125 BPM war-drum loop, and state-aware audio (pause/menu/game over). Finish with a readability pass so player, enemies, and bullets stay legible above smoke.

Recon: `AudioManager` already synthesizes cannon, ricochet (pitch 0.9–1.1), explosion, and an engine loop (idle 0.85 / moving 1.15). Player fire, ricochet, and engine calls are wired. Missing: explosion on death, hit SFX, enemy fire SFX, BGM, pause/menu audio handling, and Scout contrast.

## Goals

### T-035 — Engine loop
- `AudioManager` tracks `_engine_moving: bool`.
- `play_engine(moving)` stores the flag and sets pitch `0.85` idle / `1.15` moving on the same voice.
- `game_state_changed`:
  - `PLAYING` → start BGM; if the engine voice is absent, `play_engine(_engine_moving)`.
  - `PAUSED`, `MENU`, `GAME_OVER` → `stop_engine()` and `stop_bgm()`.
- `stop_engine()` keeps existing behavior: stop voice, clear `_engine_player`.

### T-036 — SFX to all events
- New `const`/methods:
  - `play_hit()` — short metallic clank (`_render_hit()`: noise burst + 520 Hz ring, ~0.18 s).
  - `play_enemy_cannon()` — cannon sample at pitch `0.8`.
- `var last_sfx: StringName = &""` set by every `play_*` for verification.
- Event wiring in `AudioManager._ready()`:
  - `EventBus.player_damaged` → `play_hit()`.
  - `EventBus.enemy_destroyed` → `play_explosion()`.
  - `EventBus.player_died` → `stop_engine()`, `play_explosion()`, `stop_bgm()`.
  - `EventBus.game_state_changed` → engine/BGM rules above.
- Call sites:
  - `BaseEnemy.take_damage()` → `AudioManager.play_hit()` before the death check.
  - `SandbagBarricade.take_damage()` → `AudioManager.play_hit()`.
  - `EnemyArtillery._fire()` and `EnemyDreadnought._fire()` → `AudioManager.play_enemy_cannon()`.
  - Player cannon/ricochet calls stay as they are.

### T-037 — Procedural BGM
- `const BGM_BPM: float = 125.0`, `const BGM_BARS: int = 2`, `const BGM_VOLUME_DB: float = -12.0`.
- `_render_bgm() -> PackedVector2Array`:
  - 2 bars of 4/4 at 125 BPM = 3.84 s = `int(MIX_RATE * 3.84)` frames.
  - Kick on every beat, snare on beats 2 and 4, hi-hat on every half beat, low 55/82.5 Hz drone underneath.
  - Soft clip to `[-1, 1]` and short fade at both ends to avoid loop clicks.
- `start_bgm()` / `stop_bgm()` use a dedicated loop flag through the existing voice pool (`_play(_bgm, 1.0, true)`), set `volume_db = BGM_VOLUME_DB`, and no-op when already playing.
- Started/stopped only by `game_state_changed` (and player death).
- No file loading; missing assets can never cause an error.

### T-038 — Readability
- Scout `Visual` color → `#8B3A3A` (GDD enemy rust red) so it separates from ground `#4A3B32`.
- Add `Outline` `Line2D` (closed silhouette, color `#D9C9A3`, width `1.5`) to Scout, Artillery, and Dreadnought `Visual`.
- Add `Outline` `Line2D` (color `#E8D9A0`, width `1.5`) around the player hull under `HullVisual`.
- Keep bullet layers at `z_index = 20`; verify fire `10`, black smoke `9`, sparks `15`, debris `5`, scorch `-1` all render below bullets.
- Player color stays `#556B2F`; bullets stay `#FFD700` / `#FF2222` / `#FF5500`.

## Non-goals

- No external `.wav`/`.ogg` files; no asset scanning.
- No new EventBus signals.
- No positional `AudioStreamPlayer2D` panning; the arena is fixed-camera and mono is acceptable.
- No changes to combat, scoring, or UI flow.

## Approaches Considered

1. **SFX wiring:** AudioManager subscribes to existing EventBus signals and enemies call the SFX methods directly (selected). Alternative: move every call into the caller — scattered, and explosion/hit would depend on remembering each death path.
2. **BGM:** procedural 125 BPM loop (selected) vs. skipping the optional task. Procedural keeps the zero-asset promise and adds the requested juice; skipping is legal but leaves the phase half-done.
3. **Verification:** `last_sfx` diagnostic field (selected) vs. counting active voices. Counting voices cannot prove which sound fired.
4. **Readability:** recolor + outlines (selected) vs. z-order verification only. Verification alone leaves the brown-on-brown Scout hard to read.
5. **Pause audio:** stop engine/BGM on pause (selected) vs. let them run. Stopping matches the frozen simulation.

## Contracts

### `audio_manager.gd` additions
```gdscript
const BGM_BPM: float = 125.0
const BGM_BARS: int = 2
const BGM_VOLUME_DB: float = -12.0

var last_sfx: StringName = &""
var _engine_moving: bool = false
var _bgm: PackedVector2Array
var _bgm_player: AudioStreamPlayer = null

func play_hit() -> void
func play_enemy_cannon() -> void
func start_bgm() -> void
func stop_bgm() -> void
func _render_hit() -> PackedVector2Array
func _render_bgm() -> PackedVector2Array
func _on_player_damaged(current_hp: int, max_hp: int) -> void
func _on_enemy_destroyed(enemy_position: Vector2, base_score: int, was_ricochet: bool) -> void
func _on_game_state_changed(new_state: int) -> void
```

- `play_engine(moving)`:
  - `_engine_moving = moving`.
  - if the engine voice exists but is inactive, clear `_engine_player`; then start or update pitch.
- `play_*` methods set `last_sfx` to `&"cannon"`, `&"enemy_cannon"`, `&"ricochet"`, `&"explosion"`, `&"hit"`, `&"engine"`, `&"bgm"`.

### BGM timing
- Frame count = `int(MIX_RATE * float(BGM_BARS * 4) * 60.0 / BGM_BPM)` = `84672` at 22050 Hz.
- The buffer must have peak amplitude > `0.05` and audible energy near beat starts (kick) and off-beats (hats).

### Call-site edits
- `base_enemy.gd` → `AudioManager.play_hit()` at the start of `take_damage` after the alive check.
- `sandbag_barricade.gd` → `AudioManager.play_hit()` after the alive check.
- `enemy_artillery.gd` / `enemy_dreadnought.gd` → `AudioManager.play_enemy_cannon()` inside `_fire`.

### Readability scene nodes
- `enemy_scout.tscn`: Visual color `Color(0.545098, 0.227451, 0.227451, 1)`; `Visual/Outline` Line2D closed polygon.
- `enemy_artillery.tscn` and `enemy_dreadnought.tscn`: `Visual/Outline` Line2D added; colors unchanged.
- `player.tscn`: `HullVisual/Outline` Line2D closed hull polygon.

## Review Focus

1. `play_engine(true)` reuses the same voice and only changes pitch; it must not create a second engine loop.
2. Pausing stops engine and BGM; resuming restarts both without a second engine voice.
3. One `enemy_destroyed` produces one explosion SFX; one fatal `player_damaged`/`player_died` produces hit then explosion.
4. Enemy and sandbag hits produce the hit SFX; enemy `_fire` produces the enemy cannon SFX.
5. BGM runs only during `PLAYING`, loops without clicks, and restarts after game over → redeploy.
6. Bullets (`z=20`) stay above smoke/fire/sparks/debris; enemy and player silhouettes have outlines and the Scout is rust red.
