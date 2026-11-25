# TODO.md — Trench Armor Survival (Godot 4.2+, GDScript)

> This document is **self-contained**: all important numeric values are specified in each task.
> Read the GDD/TAD only when an ambiguity needs clarification (references: `TAD §x`, `GDD §x`).
> If documents conflict, **TAD takes precedence** (see "Decisions & Notes").

---

## 0. AGENT PROTOCOL (MUST READ)

1. Work through tasks **sequentially** by phase. Do not skip a phase unless its `Depends` requirements are met.
2. One task = one commit (if git repo is initialized). Format: `feat(scope): T-xxx short description`.
3. After completing a task, change `[ ]` to `[x]`. Do not delete tasks.
4. Do not create files outside the structure in **§2**. (The optional `assets/` folder is allowed for audio/images.)
5. **Strict static typing** is mandatory: every `var`, parameter, and return type must have an explicit type.
6. **Zero-asset requirement:** create all visuals using `Polygon2D` / `Line2D` / `_draw()` / `CPUParticles2D`. Use `AudioStreamGenerator` as the fallback for all audio. The game must be playable without external assets.
7. Cross-system communication must happen **only through `EventBus`**. Avoid fragile paths such as `get_node("../..")`.
8. Every task has a DoD (Definition of Done). A task is not complete until its DoD is satisfied.
9. Validate each phase (if the Godot CLI is available): `godot --headless --quit` → there must be no parse errors or typing warnings.
10. If uncertain, document the assumption in `NOTES.md` (do not repeatedly ask questions), then continue with the task.

---

## PROGRESS LOG

**Snapshot:** 2026-11-25 · Engine `4.7.2.stable.steam.ed1daf0bf` · **Next: Phase 9 QA (T-039..T-041) — manual**

| Phase | Tasks | Status | Bukti |
|---|---|---|---|
| 0 — Project Setup | T-001..T-004 | ✅ Selesai | `project.godot` valid; autoloads terdaftar; `--headless --editor --quit` exit 0 |
| 1 — Autoload Core | T-005..T-008 | ✅ Selesai + review fixed | Harness headless `PASS` exit 0 (2×); `--headless --editor --quit` exit 0 |
| 2 — Player | T-009..T-013 | ✅ Selesai + review fixed | Harness headless `PASS` exit 0 (3×); `--headless --editor --quit` exit 0 |
| 3 — Projectiles | T-014..T-015 | ✅ Selesai | Harness headless `PASS` exit 0 (3×); `--headless --editor --quit` exit 0 |
| 4 — Enemies | T-016..T-020 | ✅ Selesai + terverifikasi | Harness headless `PASS` 50/50 exit 0; `--headless --editor --quit` exit 0 |
| 5 — Environment | T-021..T-023 | ✅ Selesai + terverifikasi | Harness headless `PASS` 40/40 exit 0; `--headless --editor --quit` exit 0 |
| 6 — Arena & Wave Director | T-024..T-027 | ✅ Selesai + terverifikasi | Harness headless `PASS` 167/167 exit 0; `--headless --editor --quit` exit 0 |
| 7 — UI & Game Flow | T-028..T-034 | ✅ Selesai + terverifikasi | Harness headless `PASS` 93/93 + restart 5/5 exit 0; `--headless --editor --quit` exit 0 |
| 8 — Audio & Juice Polish | T-035..T-038 | ✅ Selesai + review fixed | Harness headless `PASS` 74/74 + retry 4/4 exit 0; `--headless --editor --quit` exit 0 |
| 9 — QA & Release | T-039..T-041 | 🔄 Berjalan (manual) | Akan dikerjakan manual setelah Phase 10 & 11 selesai |
| 10 — Boss & Map Expansion | T-042..T-045 | ✅ Selesai + terverifikasi | Harness headless & windowed `PASS` 55/55 exit 0; `--headless --editor --quit` exit 0; `--headless --quit` exit 0 |
| 11 — Territory Invasion & Playtest UI | T-046..T-049 | ✅ Selesai + terverifikasi | Harness headless & windowed `PASS` 55/55 exit 0; `--headless --editor --quit` exit 0; `--headless --quit` exit 0 |

### Ringkasan Foundation (Phase 0–8)
- **Phase 0–3:** `project.godot` (`1280×720`, 60 Hz, 6 physics layers, 4 autoloads), `EventBus`, `GameManager` (`MENU/PLAYING/PAUSED/GAME_OVER`, score, hit-stop), `VFXManager`, `AudioManager` (`AudioStreamGenerator` 8-voice pool + BGM), `PlayerTank` (hull/turret, recoil, i-frames, tread marks), `PlayerBullet` (1× ricochet `#FF5500` 2× score), `EnemyBullet`.
- **Phase 4–6:** `BaseEnemy`, `EnemyScout`, `EnemyArtillery`, `EnemyDreadnought`, `SteelBunker`, `SandbagBarricade`, `MudCrater`, `ArenaController`, `CameraShake`, `WaveDirector`.
- **Phase 7–8:** `MainMenu`, `HUD`, `FloatingText`, `PauseMenu`, `GameOverMenu`, custom crosshair reticle (cursor restored in menus), audio polish & readability outlines.

### Ringkasan Expansion (Phase 10–11)
- **Boss:** `BossGoliath` "Iron Goliath" (16 HP +4/sector), spread volley 3 arah, mortar telegraph 1.1 s, advance; 1 damage direct / 2 ricochet; `boss_spawned`, `boss_hp_changed`, `boss_defeated`.
- **Expansion:** `ExpansionBarriers` hancur saat Boss mati, arena aktif membesar ke `Rect2(-640, -360, 2560, 1440)`, outer `PerimeterWalls`, outer gates + cover, kamera berpindah dari fixed ke follow.
- **Invasion:** 3 `CaptureZone` (radius 180, `+0.15/s`, contested pause, `+1 HP` & `+500`), 3 `EnemyPillbox` penjaga, wave patrol di outer gate, `sector_cleared` +1000 lalu sektor berikutnya.
- **HUD:** objective tracker (`THREAT` → `IRON GOLIATH HP` → `ZONES CAPTURED`), panah off-screen untuk Boss/zone, minimap sudut kanan atas.

---

## 1. GLOBAL CONSTANTS (Single Source of Truth)

### 1.1 Colors
| Element | Hex |
|---|---|
| Ground | `#4A3B32` |
| Dark Mud | `#2E241E` |
| Player | `#556B2F` (+ white star) |
| Enemy & Boss | `#8B3A3A`, `#36393F` |
| Normal Bullet | `#FFD700` |
| Ricochet Bullet | `#FF5500` |
| Enemy Bullet | `#FF2222` |
| Ricochet Sparks | `#FFD700` |
| Explosion | `#FF5500` + black smoke |
| Capture Zone (Neutral / Capturing / Contested / Captured) | `#D9A738` / `#E5C158` / `#FF4444` / `#6B8E23` |

### 1.2 Player
`MAX_HP=3` · `BASE_SPEED=220.0` · `TURN_SPEED=10.0` · `FIRE_COOLDOWN=0.45` · `RECOIL_FORCE=40.0` · `IFRAME_DURATION=1.2` · Hitbox `36x36` · `heal(1)` on Capture Zone completion (clamped to `MAX_HP`).

### 1.3 Enemies & Boss
| Type | HP | Speed | Fire Interval | Bullet Speed | Score |
|---|---|---|---|---|---|
| Scout | 1 | 250 | — | — | 100 |
| Artillery | 1 | 110 | 2.5s | 400 | 200 |
| Dreadnought | 2 | 70 | 3.5s | 350 | 500 |
| Pillbox (Invasion) | 3 | 0 | 2.2s | 400 | 300 |
| Boss: Iron Goliath | 16 (+4/sector) | 65 | Cycle (Spread/Mortar/Advance) | 380 | 1500 |

### 1.4 Player Bullet & Capture Zones
* **Player Bullet:** `SPEED=650.0` · `MAX_BOUNCES=1` · after bouncing → color `#FF5500` + 2x score (`2` damage vs Boss, instakill vs Dreadnought).
* **Capture Zone:** Radius `180.0 px` · Capture rate `+0.15/s` (~`6.7s`) when player inside & `0` enemies inside · `CONTESTED` if enemies inside · `+500` score & `+1 HP` on capture · `3` zones per expansion sector.

### 1.5 Screen Shake `(intensity px, duration s)`
Firing `(2, 0.1)` · Enemy explosion `(5, 0.2)` · Player damaged `(12, 0.35)` + hit-stop `0.05s` · Boss defeated / Map expansion `(14, 0.5)`.

### 1.6 Physics Layers
| Layer | Name | Objects | Mask |
|---|---|---|---|
| 1 | Player | Player | 2,3,5,6 |
| 2 | Enemy | Standard enemies, Pillbox, BossGoliath | 1,2,3,4,6 |
| 3 | Environment | Perimeter Walls, Expansion Barriers, SteelBunker, Sandbag | — |
| 4 | PlayerBullet | PlayerBullet | 2,3 |
| 5 | EnemyBullet | EnemyBullet | 1,3 |
| 6 | TerrainHazard | MudCrater (Area2D), CaptureZone (Area2D) | 1,2 |

### 1.7 Node Groups
`"player"` (Player root) · `"enemy"` (All enemies & Boss) · `"boss"` (BossGoliath root) · `"bouncy_surface"` (Perimeter Walls + Expansion Barriers + SteelBunker) · `"destructible_cover"` (SandbagBarricade) · `"capture_zone"` (CaptureZone roots)

### 1.8 Input Map
`move_up`=W/Up · `move_down`=S/Down · `move_left`=A/Left · `move_right`=D/Right · `shoot`=LMB · `pause`=Esc

---

## 2. DIRECTORY STRUCTURE (MANDATORY)

```text
res://
├── project.godot
├── autoloads/        event_bus.gd  game_manager.gd  vfx_manager.gd  audio_manager.gd
├── scenes/
│   ├── main_menu.tscn   arena.tscn
│   ├── player/        player.tscn  tread_mark.tscn
│   ├── projectiles/   player_bullet.tscn  enemy_bullet.tscn
│   ├── enemies/       enemy_scout.tscn  enemy_artillery.tscn  enemy_dreadnought.tscn  enemy_pillbox.tscn  boss_goliath.tscn
│   ├── environment/   steel_bunker.tscn  sandbag_barricade.tscn  mud_crater.tscn  capture_zone.tscn
│   └── ui/            hud.tscn  pause_menu.tscn  game_over_menu.tscn  floating_text.tscn
└── scripts/
    ├── arena/         arena_controller.gd  camera_shake.gd  wave_director.gd
    ├── player/        player.gd
    ├── projectiles/   player_bullet.gd  enemy_bullet.gd
    ├── enemies/       base_enemy.gd  enemy_scout.gd  enemy_artillery.gd  enemy_dreadnought.gd  enemy_pillbox.gd  boss_goliath.gd
    ├── environment/   sandbag_barricade.gd  mud_crater.gd  capture_zone.gd
    └── ui/            main_menu.gd  hud.gd  pause_menu.gd  game_over_menu.gd  floating_text.gd
```

---

## PHASE 0–8 — Base Game & Polish (Completed)

- [x] **T-001..T-004** Project Setup (`project.godot`, Input Map, 6 Physics Layers, 4 Autoloads).
- [x] **T-005..T-008** Autoload Core (`event_bus.gd`, `game_manager.gd`, `vfx_manager.gd`, `audio_manager.gd`).
- [x] **T-009..T-013** Player Tank (`player.tscn`, `player.gd`, movement/aim, shooting/recoil, damage/i-frames, `tread_mark.tscn`).
- [x] **T-014..T-015** Projectiles (`player_bullet.tscn/.gd`, `enemy_bullet.tscn/.gd`).
- [x] **T-016..T-020** Standard Enemies (`base_enemy.gd`, `enemy_scout`, `enemy_artillery`, `enemy_dreadnought`, mud slowdown).
- [x] **T-021..T-023** Environment (`steel_bunker.tscn`, `sandbag_barricade.tscn/.gd`, `mud_crater.tscn/.gd`).
- [x] **T-024..T-027** Arena & Wave Director (`arena.tscn`, `arena_controller.gd`, `camera_shake.gd`, `wave_director.gd`).
- [x] **T-028..T-034** UI & Game Flow (`main_menu`, `hud`, `floating_text`, `pause_menu`, `game_over_menu`, reticle, restart cleanup).
- [x] **T-035..T-038** Audio & Juice Polish (engine loop, SFX, procedural BGM, readability outlines & z-order).

---

## PHASE 10 — Boss Encounter & Dynamic Map Expansion (Playtest Update)

- [x] **T-042** Extend `autoloads/event_bus.gd` & `autoloads/game_manager.gd`
  - Add signals in `event_bus.gd`: `phase_changed(new_phase: int)`, `threat_updated(current_threat: float, max_threat: float)`, `boss_spawned(boss_name: String, current_hp: int, max_hp: int)`, `boss_hp_changed(current_hp: int, max_hp: int)`, `boss_defeated(boss_position: Vector2, base_score: int)`, `map_expanded(new_bounds: Rect2)`, `capture_zone_updated(zone_id: int, progress: float, state_name: String)`, `capture_zone_captured(zone_id: int, captured_count: int, total_count: int)`, `sector_cleared(sector_num: int, bonus_score: int)`.
  - Add `enum Phase { SKIRMISH, BOSS, INVASION }`, `current_phase: Phase`, `sector_index: int`, `threat_progress: float`, `zones_captured: int`, `zones_total: int` in `game_manager.gd`, and reset all of them in `reset_run()`.
  - Increment `threat_progress` on `enemy_destroyed` during `SKIRMISH` (`+10` for `base_score <= 100`, `+15` for `<= 200`, `+25` for `> 200`); at `100.0`, switch to `Phase.BOSS` and emit `phase_changed`.
  - **DoD:** `SKIRMISH -> BOSS` transition triggers deterministically at `100.0` threat and resets cleanly on `reset_run()`.
- [x] **T-043** `scenes/enemies/boss_goliath.tscn` + `scripts/enemies/boss_goliath.gd`
  - Inherit `BaseEnemy` (`CharacterBody2D`, Layer `2`, Mask `1,2,3,4,6`, groups `"enemy"` and `"boss"`).
  - Visual: procedural ~`2.4x` heavy armored tank (`Polygon2D` `#36393F` & `#8B3A3A` + high-contrast `#D9C9A3` `Line2D` outline).
  - Stats: `max_hp = 16 + 4 * (GameManager.sector_index - 1)`, `move_speed = 65.0`, `base_score = 1500`.
  - Override `take_damage(amount: int, from_ricochet: bool) -> void`: deal `2` damage if `from_ricochet` is `true`, else `1`; emit `EventBus.boss_hp_changed.emit(hp, max_hp)`.
  - Attack AI: cycle between (1) 3-way spread volley (`enemy_bullet.tscn`, `380 px/s`), (2) telegraphed mortar circle (`1.1s` visual warning ring before area detonation dealing `1` damage), and (3) advancing toward the player.
  - On defeat (`hp <= 0`): emit `EventBus.boss_defeated.emit(global_position, base_score)`, trigger shake `(14.0, 0.5)`, and `queue_free()`.
  - **DoD:** Boss takes `1` direct / `2` ricochet damage, executes all 3 attack patterns, and emits `boss_defeated` on death.
- [x] **T-044** `scenes/arena.tscn` & `scripts/arena/arena_controller.gd` — Dynamic Map Expansion (`1280x720 -> 2560x1440`)
  - Structure `arena.tscn` with Inner Sector (`Rect2(0, 0, 1280, 720)`) bounded by removable/destructible `ExpansionBarriers` (Layer `3`, group `"bouncy_surface"`) and Outer Expansion Sector (`Rect2(-640, -360, 2560, 1440)`) enclosed by outer `PerimeterWalls` with outer spawn gates and additional `SteelBunker` / `MudCrater` cover.
  - Also add `heal(amount: int) -> void` to `scripts/player/player.gd` (`hp = mini(MAX_HP, hp + amount)` + emit `player_damaged`).
  - When `EventBus.boss_defeated` fires: destroy/remove `ExpansionBarriers` with explosion VFX, expand active arena bounds to `Rect2(-640, -360, 2560, 1440)`, emit `EventBus.map_expanded.emit(new_bounds)`, and switch `GameManager` to `Phase.INVASION`.
  - **DoD:** Inner barriers open upon Boss defeat and the player can drive across the full `2560x1440` arena without escaping outer perimeter walls.
- [x] **T-045** `scripts/arena/camera_shake.gd` & `scripts/arena/wave_director.gd` — Expansion Camera & Phase Spawning
  - Update `camera_shake.gd`: stay fixed at `(640, 360)` during `SKIRMISH`/`BOSS`, then on `EventBus.map_expanded(new_bounds)` update `limit_left/right/top/bottom` to `new_bounds` and smoothly follow the player while preserving shake offsets.
  - Update `wave_director.gd`: spawn `BossGoliath` when `phase_changed` enters `Phase.BOSS`, reduce regular spawn rate during `BOSS`, and spawn patrols at outer expansion gates during `INVASION`.
  - **DoD:** Camera transitions smoothly from fixed arena to player-follow within expanded bounds, and Boss spawns reliably on phase change.

---

## PHASE 11 — Territory Invasion & Playtest Navigation UI

- [x] **T-046** `scenes/environment/capture_zone.tscn` + `scripts/environment/capture_zone.gd`
  - `Area2D` (Layer `6`, Mask `1,2`, `z_index = -1`, group `"capture_zone"`) with `CircleShape2D` radius `180.0 px` and procedural `_draw()` circular ring + radial/fill progress gauge.
  - Track `"player"` and `"enemy"` bodies inside the zone:
    - If player inside and `0` enemies inside: `progress += 0.15 * delta` (`CAPTURING`).
    - If enemies inside while `progress < 1.0`: pause progress (`CONTESTED`).
    - When `progress >= 1.0`: lock as `CAPTURED`, call `player.call("heal", 1)`, spawn floating text `"+500 ZONE CAPTURED!"`, and emit `EventBus.capture_zone_captured`.
  - **DoD:** Capture progress advances when uncontested, pauses when contested by enemies, and heals `+1 HP` upon completion.
- [x] **T-047** `scenes/enemies/enemy_pillbox.tscn` + `scripts/enemies/enemy_pillbox.gd` & Invasion Loop
  - Inherit `BaseEnemy` (`max_hp = 3`, `move_speed = 0.0`, `base_score = 300`); stationary turret that aims at the player and fires `enemy_bullet.tscn` (`400 px/s`) every `2.2s`.
  - When `Phase.INVASION` begins in `arena_controller.gd`, instantiate `3` `CaptureZone` nodes in distinct outer quadrants (`(-320, -140)`, `(1600, -140)`, `(1600, 900)`) alongside guarding `EnemyPillbox` turrets.
  - When all `3` zones are captured (`zones_captured >= zones_total`), emit `EventBus.sector_cleared(sector_index, 1000)`, increment `sector_index += 1`, clean up captured zone nodes, and start the next sector escalation cycle.
  - **DoD:** Full `Skirmish -> Boss -> Map Expansion -> 3 Capture Zones -> Sector Clear Loop` plays end-to-end without errors.
- [x] **T-048** `scripts/ui/hud.gd` — Phase Objective Tracker, Off-Screen Pointers & Minimap
  - Update top-center HUD to show active phase status: `THREAT: XX%` (`SKIRMISH`) → `IRON GOLIATH HP` bar (`BOSS`) → `ZONES CAPTURED: X/3` (`INVASION`).
  - Draw procedural edge-of-screen directional arrows pointing to active uncaptured `"capture_zone"` nodes (and `"boss"` when off-screen).
  - Draw a compact procedural corner minimap showing active arena bounds, player dot, uncaptured/captured zones, and boss/enemy blips.
  - **DoD:** Player can clearly locate Boss and all 3 Capture Zones across the `2560x1440` map during playtest.
- [x] **T-049** Playtest Verification (`--headless` + Windowed Playtest)
  - Run `godot --headless --quit` and automated harness checks for `SKIRMISH -> BOSS -> MAP EXPANSION -> CAPTURE ZONES -> SECTOR CLEAR -> RESTART`.
  - **DoD:** Exit code `0`, zero parse/typing/runtime errors, and smooth playtest flow.

---

## PHASE 9 — QA & Final Release

- [ ] **T-039** Playtest checklist (verify all base + expansion mechanics):
  - [ ] Ricochet once, orange color, 2x score + floating text
  - [ ] Dreadnought: 2 direct hits / 1 ricochet hit
  - [ ] Sandbag destroyed on 3rd hit; bullets do not bounce
  - [ ] Mud slows player & enemies by 35%
  - [ ] I-frames 1.2s; hit-stop & shake work correctly
  - [ ] Threat reaches 100% -> Boss "Iron Goliath" spawns (1 direct / 2 ricochet damage)
  - [ ] Defeating Boss expands arena `1280x720 -> 2560x1440` and unlocks camera follow
  - [ ] 3 Capture Zones capture/contest properly, restore +1 HP, and clear sector
  - [ ] Off-screen zone arrows and minimap accurately reflect positions
  - [ ] Pause/Resume/Restart/Main Menu do not corrupt state
  - [ ] No errors in Output; stable 60 FPS
- [ ] **T-040** Performance check: effect nodes are `queue_free`d; active `CPUParticles2D` nodes are bounded (one-shot).
- [ ] **T-041** Update `README.md` with playtest controls, Boss/Expansion/Invasion loop guide, and export presets.

---

## DECISIONS & NOTES (Ambiguity Resolution)

| # | Issue | Decision |
|---|---|---|
| 1 | Recoil: GDD says "40 px" vs TAD `RECOIL_FORCE*5.0` | Follow **TAD** (`velocity -= aim * 40.0 * 5.0`). |
| 2 | Dreadnought: GDD says "ricochet from side/rear" vs TAD says "all ricochets" | Follow **TAD** (all ricochet bullets = instant kill). |
| 3 | Boss ricochet bonus | Follow **TAD §5.3** (`2` damage from ricochet, `1` damage from direct hit). |
| 4 | Arena coordinate origin on expansion | Keep Inner Sector at `Rect2(0, 0, 1280, 720)` so existing player spawn `(640, 360)` and inner obstacle coordinates remain untouched; expand symmetrically to `Rect2(-640, -360, 2560, 1440)`. |
| 5 | `player.take_damage` signature | Keep `take_damage(amount: int, _is_ricochet: bool = false)` and add `heal(amount: int) -> void` for Capture Zone rewards. |