# TODO.md — Trench Armor Survival (Godot 4.2+, GDScript)

> This document is **self-contained**: all important numeric values are specified in each task.
> Read the GDD/TAD/UI_DESIGN only when an ambiguity needs clarification (references: `TAD §x`, `GDD §x`, `UI_DESIGN §x`).
> If documents conflict, **TAD takes precedence** for core gameplay & **UI_DESIGN takes precedence** for UI tokens, styling, and interaction rules (see "Decisions & Notes").

---

## 0. AGENT PROTOCOL (MUST READ)

1. Work through tasks **sequentially** by phase. Do not skip a phase unless its `Depends` requirements are met.
2. One task = one commit (if git repo is initialized). Format: `feat(scope): T-xxx short description`.
3. After completing a task, change `[ ]` to `[x]`. Do not delete tasks.
4. Do not create files outside the structure in **§2**. (The optional `assets/` folder is allowed for audio/images.)
5. **Strict static typing** is mandatory: every `var`, parameter, and return type must have an explicit type.
6. **Zero-asset requirement:** create all visuals using `Polygon2D` / `Line2D` / `_draw()` / `CPUParticles2D`, and all UI using `Theme` / `StyleBoxFlat` / `PanelContainer` / `Control._draw()` / `SystemFont` / `Tween`. Use `AudioStreamGenerator` as the fallback for all audio. The game must be playable without external assets.
7. Cross-system communication must happen **only through `EventBus`**. Avoid fragile paths such as `get_node("../..")`.
8. Every task has a DoD (Definition of Done). A task is not complete until its DoD is satisfied.
9. Validate each phase (if the Godot CLI is available): `godot --headless --quit` → there must be no parse errors or typing warnings.
10. If uncertain, document the assumption in `NOTES.md` (do not repeatedly ask questions), then continue with the task.

---

## PROGRESS LOG

**Snapshot:** 2026-11-25 · Engine `4.7.2.stable.steam.ed1daf0bf` · **Next: Phase 13 — Showcase Visual Polish & Rich Command UI (T-055..T-060), then Phase 9 QA (T-039..T-041)**

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
| 9 — QA & Release | T-039..T-041 | 🔄 Berjalan (manual) | Akan dikerjakan manual setelah Phase 13 Showcase UI selesai |
| 10 — Boss & Map Expansion | T-042..T-045 | ✅ Selesai + terverifikasi | Harness headless & windowed `PASS` 55/55 exit 0; `--headless --editor --quit` exit 0; `--headless --quit` exit 0 |
| 11 — Territory Invasion & Playtest UI | T-046..T-049 | ✅ Selesai + terverifikasi | Harness headless & windowed `PASS` 55/55 exit 0; `--headless --editor --quit` exit 0; `--headless --quit` exit 0 |
| 12 — Professional UI/UX Overhaul | T-050..T-054 | ✅ Selesai + terverifikasi | Editor parse exit 0; HUD harness 5/5; diegetic/menu harness 8/8 |
| 13 — Showcase Visual Polish & Rich UI | T-055..T-059 | ✅ Selesai + terverifikasi | Editor parse exit 0; T-055 7/7; T-057 6/6; T-058 6/6; T-059 9/9; headless smoke exit 0 |

### Ringkasan Foundation & Expansion (Phase 0–12)
- **Phase 0–8:** Core autoloads (`EventBus`, `GameManager`, `VFXManager`, `AudioManager`), dual-control `PlayerTank`, `PlayerBullet` 1× ricochet (`#FF5500`, 2× score), 3 standard enemy types, environment obstacles, `WaveDirector`, audio synth pool, and core UI flow.
- **Phase 10–11:** `BossGoliath` "Iron Goliath" (16 HP +4/sector, 1 direct / 2 ricochet damage), dynamic map expansion (`1280x720 -> 2560x1440`), camera follow unlock, 3 `CaptureZone` outposts (`+0.15/s`, `+500` & `+1 HP`), and `EnemyPillbox` guards.
- **Phase 12:** `UIThemeBuilder` tokens, 3-zone HUD layout, colorblind-safe zone badges, delayed Boss HP trail, diegetic reload reticle, two-step abort confirmation, and `0.8s` Game Over input lockout.

---

## 1. GLOBAL CONSTANTS (Single Source of Truth)

### 1.1 Gameplay & World Colors
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

### 1.2 UI Design Tokens (`UI_DESIGN v3.0 §2` — Single Source of Truth)
| Token Name | Hex Code | RGBA (`Color`) | Usage & Semantic Role |
|---|---|---|---|
| `UI_BG_DARK` | `#141618` | `(0.078, 0.086, 0.094, 0.92)` | Base surface for HUD cards & modals |
| `UI_BG_ELEVATED` | `#1B1E22` | `(0.106, 0.118, 0.133, 0.95)` | Sub-cards, alternating AAR table rows, keycaps |
| `UI_SURFACE` | `#22262A` | `(0.133, 0.149, 0.165, 0.95)` | Normal buttons, empty bar tracks, neutral nodes |
| `UI_SURFACE_HOVER` | `#2E343B` | `(0.180, 0.204, 0.231, 1.0)` | Interactive hover / focus background |
| `UI_BORDER_STEEL` | `#4D5660` | `(0.302, 0.337, 0.376, 1.0)` | Panel & button border (`border_width = 2px`) |
| `UI_ORNAMENT_DIM` | `#6E7A87` | `(0.431, 0.478, 0.529, 0.75)` | Corner L-brackets, internal dividers, radar ticks |
| `UI_BORDER_ACTIVE` | `#E0AF3E` | `(0.878, 0.686, 0.243, 1.0)` | Hover/Focus border, command accent, Rank S stamp |
| `UI_TEXT_PRIMARY` | `#F4F1EA` | `(0.957, 0.945, 0.918, 1.0)` | Primary text, score digits, screen titles |
| `UI_TEXT_MUTED` | `#A8B2BC` | `(0.659, 0.698, 0.737, 1.0)` | Secondary labels, timer, hotkey hints |
| `UI_TEXT_DANGER` | `#FF6B6B` | `(1.000, 0.420, 0.420, 1.0)` | Boss warning text & Game Over header |
| `SEMANTIC_ALLY` | `#5E943B` | `(0.369, 0.580, 0.231, 1.0)` | Active HP segments, `CAPTURED` zone, `READY` status |
| `SEMANTIC_WARN` | `#E59528` | `(0.898, 0.584, 0.157, 1.0)` | Threat meter, `CAPTURING` zone, tactical warning |
| `SEMANTIC_DANGER` | `#D13B3B` | `(0.820, 0.231, 0.231, 1.0)` | Boss HP fill, critical HP (`HP == 1`), `CONTESTED` zone |
| `SEMANTIC_CRIT` | `#FF6A1A` | `(1.000, 0.416, 0.102, 1.0)` | Floating combat text & streak for `RICOCHET KILL` |

### 1.3 Typography, Spacing & Viewport Rules (`UI_DESIGN v3.0 §1 & §2.2–2.3`)
* **Viewport & Scaling:** Base resolution `1280x720`, Stretch Mode `canvas_items`, Stretch Aspect `expand`. HUD on `CanvasLayer (layer = 1)`, Phase Banners & Vignette on `CanvasLayer (layer = 2)`, Modals/Overlays on `CanvasLayer (layer = 3)`.
* **Font:** `SystemFont` fallback chain `["JetBrains Mono", "Consolas", "Liberation Mono", "Courier New"]`, `font_weight = 700` (Bold), `outline_size = 2`, `outline_color = #0B0C0E`.
* **Scale:** `TYPE_HERO = 52 px` (`+3 px` letter spacing), `TYPE_DISPLAY = 44 px` (`+2 px` letter spacing), `TYPE_METRIC = 24 px` (`%06d`), `TYPE_HEADER = 18 px`, `TYPE_LABEL = 14 px`, `TYPE_MICRO = 11–12 px`.
* **Grid & Ornamentation:** `8 px` base grid, `24 px` safe screen margin, `8x8 px` corner L-brackets, `4 px` interval subtle scanlines (`alpha = 0.03`), `45°` diagonal hazard stripes (`alpha = 0.18`), and keycap badges for hotkeys.

### 1.4 Player
`MAX_HP=3` · `BASE_SPEED=220.0` · `TURN_SPEED=10.0` · `FIRE_COOLDOWN=0.45` · `RECOIL_FORCE=40.0` · `IFRAME_DURATION=1.2` · Hitbox `36x36` · `heal(1)` on Capture Zone completion (clamped to `MAX_HP`).

### 1.5 Enemies & Boss
| Type | HP | Speed | Fire Interval | Bullet Speed | Score |
|---|---|---|---|---|---|
| Scout | 1 | 250 | — | — | 100 |
| Artillery | 1 | 110 | 2.5s | 400 | 200 |
| Dreadnought | 2 | 70 | 3.5s | 350 | 500 |
| Pillbox (Invasion) | 3 | 0 | 2.2s | 400 | 300 |
| Boss: Iron Goliath | 16 (+4/sector) | 65 | Cycle (Spread/Mortar/Advance) | 380 | 1500 |

### 1.6 Player Bullet & Capture Zones
* **Player Bullet:** `SPEED=650.0` · `MAX_BOUNCES=1` · after bouncing → color `#FF5500` + 2x score (`2` damage vs Boss, instakill vs Dreadnought).
* **Capture Zone:** Radius `180.0 px` · Capture rate `+0.15/s` (~`6.7s`) when player inside & `0` enemies inside · `CONTESTED` if enemies inside · `+500` score & `+1 HP` on capture · `3` zones per expansion sector.

### 1.7 Screen Shake `(intensity px, duration s)`
Firing `(2, 0.1)` · Enemy explosion `(5, 0.2)` · Player damaged `(12, 0.35)` + hit-stop `0.05s` · Boss defeated / Map expansion `(14, 0.5)`.

### 1.8 Physics Layers
| Layer | Name | Objects | Mask |
|---|---|---|---|
| 1 | Player | Player | 2,3,5,6 |
| 2 | Enemy | Standard enemies, Pillbox, BossGoliath | 1,2,3,4,6 |
| 3 | Environment | Perimeter Walls, Expansion Barriers, SteelBunker, Sandbag | — |
| 4 | PlayerBullet | PlayerBullet | 2,3 |
| 5 | EnemyBullet | EnemyBullet | 1,3 |
| 6 | TerrainHazard | MudCrater (Area2D), CaptureZone (Area2D) | 1,2 |

### 1.9 Node Groups
`"player"` (Player root) · `"enemy"` (All enemies & Boss) · `"boss"` (BossGoliath root) · `"bouncy_surface"` (Perimeter Walls + Expansion Barriers + SteelBunker) · `"destructible_cover"` (SandbagBarricade) · `"capture_zone"` (CaptureZone roots)

### 1.10 Input Map
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
    └── ui/            ui_theme_builder.gd  tactical_frame.gd  main_menu.gd  hud.gd  pause_menu.gd  game_over_menu.gd  floating_text.gd
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

## PHASE 10 — Boss Encounter & Dynamic Map Expansion (Completed)

- [x] **T-042** Extend `autoloads/event_bus.gd` & `autoloads/game_manager.gd` (`Phase` enum, threat escalation `SKIRMISH -> BOSS`, boss/expansion/invasion signals).
- [x] **T-043** `scenes/enemies/boss_goliath.tscn` + `scripts/enemies/boss_goliath.gd` (16 HP +4/sector, 1 direct / 2 ricochet damage, spread volley + mortar telegraph + advance).
- [x] **T-044** `scenes/arena.tscn` & `scripts/arena/arena_controller.gd` — Dynamic Map Expansion (`1280x720 -> 2560x1440`) & `player.heal(1)`.
- [x] **T-045** `scripts/arena/camera_shake.gd` & `scripts/arena/wave_director.gd` — Expansion Camera & Phase Spawning.

---

## PHASE 11 — Territory Invasion & Playtest Navigation UI (Completed)

- [x] **T-046** `scenes/environment/capture_zone.tscn` + `scripts/environment/capture_zone.gd` (radius `180 px`, `+0.15/s`, `CONTESTED` pause, `+500` & `+1 HP`).
- [x] **T-047** `scenes/enemies/enemy_pillbox.tscn` + `scripts/enemies/enemy_pillbox.gd` & Invasion Loop (3 Capture Zones + Pillboxes + `sector_cleared` loop).
- [x] **T-048** `scripts/ui/hud.gd` — Phase Objective Tracker, Off-Screen Pointers & Minimap.
- [x] **T-049** Playtest Verification (`--headless` + Windowed Playtest).

---

## PHASE 12 — Professional UI/UX Overhaul (Completed)

- [x] **T-050** `scripts/ui/ui_theme_builder.gd` (`UIThemeBuilder`) & Button Pivot Helper.
- [x] **T-051** `scripts/ui/hud.gd` — 3-Zone Tactical Layout, Segmented Armor Bar & Minimap.
- [x] **T-052** Diegetic & World-Space UI (`hud.gd` & `floating_text.gd`).
- [x] **T-053** `main_menu.gd`, `pause_menu.gd` & `game_over_menu.gd` with Safety Guards.
- [x] **T-054** UI & Full-Loop Verification (`--headless` + Windowed Visual Check).

---

## PHASE 13 — Showcase Visual Polish, Diegetic Ornamentation & Rich Command UI (`UI_DESIGN v3.0`)

- [x] **T-055** Create `scripts/ui/tactical_frame.gd` (`TacticalFrame`) & Extend `UIThemeBuilder` (`UI_DESIGN v3.0 §2.1–2.3`)
  - Add new tokens to `UIThemeBuilder`: `UI_BG_ELEVATED` (`#1B1E22`), `UI_ORNAMENT_DIM` (`#6E7A87`, `alpha = 0.75`), and `TYPE_HERO = 52`, `TYPE_DISPLAY = 44`.
  - Create reusable `TacticalFrame` (`Control` overlay or container decorator) with configurable flags: `show_brackets: bool` (`8x8 px` corner L-brackets `3 px` inset), `show_scanlines: bool` (`4 px` vertical interval, `alpha = 0.03`), `show_hazard_stripes: bool` (`45°` diagonal stripes, `alpha = 0.18`), and `accent_color: Color`.
  - Add helper methods in `UIThemeBuilder` to generate **Physical Keycap Badges** (`create_keycap_badge(key_text: String, action_text: String) -> Control`) styled with `UI_BG_ELEVATED` and `2 px` bottom bevel border.
  - **DoD:** `TacticalFrame` renders crisp procedural corner brackets, scanlines, hazard stripes, and keycap badges with zero external textures and zero parse/typing warnings.
- [x] **T-056** Upgrade `scripts/ui/main_menu.gd` to Showcase Tactical War-Room Console (`UI_DESIGN v3.0 §3`)
  - **Live Attract-Mode Battlefield Backdrop:** Render a live AI demo skirmish (or automated tank patrol + wall-bouncing tracer fire + smoke VFX) behind a radial edge vignette (`alpha = 0.55` edges, `0.18` center) and a `128 px` coordinate grid overlay (`alpha = 0.06`) with sector coordinate ticks.
  - **Left Command Column (`x = 56 px`, `width = 480 px`):**
    - Draw procedural **Military Crest Emblem** (`72x72 px` `_draw()`: hexagonal steel shield, olive tank silhouette, white star, twin gold chevrons).
    - Render `● FIELD COMMAND TERMINAL // BUILD 1.0`, hero title `TRENCH ARMOR` (`TYPE_HERO`), and highlighted subtitle strip `SURVIVAL // RICOCHET TACTICS`.
    - Build action stack (`DEPLOY TO SECTOR` `52 px` height with animated `>>` hover chevrons and auto-focus, `TACTICAL INTEL` `44 px`, `QUIT TO DESKTOP` `44 px`).
  - **Right Interactive Field Manual Card (`width = 440 px`, `TacticalFrame`):**
    - Implement 3 interactive tabs (`[1] COMBAT`, `[2] ESCALATION`, `[3] INVASION`) that auto-cycle every `6.0s` (pausing when clicked) with a `140 px` procedural `_draw()` tactical diagram illustrating: (1) yellow-to-orange `1x` wall ricochet `2x` score/piercing, (2) `100%` threat -> `Iron Goliath` boss, and (3) `1280x720 -> 2560x1440` 3-outpost capture expansion.
  - **Bottom Telemetry Footer (`height = 44 px`):** Display physical keycap badges (`[W][A][S][D] DRIVE`, `[MOUSE] AIM`, `[LMB] FIRE`, `[ESC] PAUSE`) on the left and persisted/session `BEST RECORD: %06d` + `STATUS: COMBAT READY` on the right.
  - **DoD:** Main Menu looks full, animated, and showcase-ready with live background action, procedural military emblem, interactive visual Field Manual diagrams, and keycap footer.
- [x] **T-057** Enrich In-Game HUD Visuals, Chassis Silhouette & Radar Sweep (`scripts/ui/hud.gd`) (`UI_DESIGN v3.0 §4.1–4.4`)
  - Wrap all 3 top HUD cards in `TacticalFrame` corner L-brackets and scanline ornamentation.
  - **Top-Left Armor Card:** Add header `CHASSIS // VANGUARD-01` + live status pill (`NOMINAL` / `CAUTION` / `CRITICAL`), a `36x36 px` procedural top-down mini tank icon (`_draw()`) rotating with the player turret and flashing on hit, and upgrade HP bars to **chamfered parallelogram armor plates** (`38x16 px`) with top specular line and rivets.
  - **Top-Center Phase Tracker:** Add phase counter (`PHASE 01/03`), `25% / 50% / 75%` milestone ticks on the Skirmish Threat bar, `45°` diagonal hazard stripes + `RICOCHET WEAKNESS [2X DMG]` subtitle on the Boss bar, and `3 px` bottom mini progress bars inside each of the 3 Invasion outpost badges.
  - **Top-Right Telemetry & Radar Scope:** Add a dynamic **Ricochet Streak Pill** (`RICOCHET STREAK x%d` in `SEMANTIC_CRIT`) when chaining `>= 2` ricochet kills, upgrade the minimap (`168x94 px`) with `A1–B2` quadrant grid lines and a rotating radar sweep line (`0.5 rev/s`, `alpha = 0.08`), and add a subtle reload readiness arc under the custom crosshair reticle.
  - **Phase Transition Banner & Critical Vignette (`CanvasLayer layer = 2`):** Add a `1.8s` slide-in tactical banner on phase changes (`WARNING: IRON GOLIATH APPROACHING`, `PERIMETER BREACHED — SECTOR EXPANDED`, `SECTOR CLEARED`) and a subtle pulsing crimson screen-edge vignette (`alpha = 0.16`) when `HP == 1`.
  - **DoD:** HUD displays rich military telemetry, rotating mini tank silhouette, chamfered HP plates, radar sweep, phase transition banners, and ricochet streak feedback without obstructing center-screen visibility.
- [x] **T-058** Upgrade Pause & Game Over After-Action Report Modals (`pause_menu.gd` & `game_over_menu.gd`) (`UI_DESIGN v3.0 §5`)
  - Place modals on `CanvasLayer (layer = 3)` and decorate cards with `TacticalFrame` corner brackets and scanlines.
  - **Pause Menu:** Add diagonal hazard header bar, quick controls keycap strip (`[WASD] Drive · [LMB] Ricochet Shot`), audio toggle, resume, and two-step abort confirmation (`CONFIRM ABORT?` with hazard stripes for `3.0s`).
  - **Game Over / After-Action Report (`width = 460 px`):** Format stats as a 4-row alternating table (`UI_BG_ELEVATED` / `UI_BG_DARK`), display a `NEW RECORD!` badge when beating best score, and animate a **Procedural Performance Rank Stamp (`76x76 px` `_draw()`)** (`RANK S` >= 8000, `RANK A` >= 4500, `RANK B` >= 2000, `RANK C` < 2000) with a `2.2x -> 1.0x` (`0.22s`, `-6°` rotation) impact tween while preserving the `0.8s` `REDEPLOY` input lockout.
  - **DoD:** Pause and Game Over screens feel like authentic military After-Action Reports with animated rank stamp, record tracking, and intact safety guards.
- [x] **T-059** Showcase UI & Full-Loop Verification (`--headless` + Windowed Visual Check)
  - Run `godot --headless --quit` and automated harness checks covering `MainMenu Attract-Mode & Field Manual Tabs -> Chamfered HUD & Radar Sweep -> Phase Transition Banner -> Ricochet Streak -> Pause Quick-Ref -> Game Over Rank Stamp & 0.8s Lockout -> Redeploy`.
  - **DoD:** Exit code `0`, zero parse/typing/runtime errors, and all `UI_DESIGN v3.0` elements verified.

---

## PHASE 9 — QA & Final Release

- [ ] **T-039** Playtest checklist (verify all base, expansion & showcase UI mechanics):
  - [ ] Main Menu displays live attract-mode battle, military crest emblem, auto-cycling Field Manual diagrams, and keycap footer
  - [ ] Ricochet once, orange color, 2x score + floating text (`+200 RICOCHET!`) + Ricochet Streak pill on chains
  - [ ] HUD displays L-bracket frames, rotating mini tank silhouette, chamfered HP plates, and sweeping radar scope
  - [ ] Dreadnought: 2 direct hits / 1 ricochet hit
  - [ ] Sandbag destroyed on 3rd hit; bullets do not bounce
  - [ ] Mud slows player & enemies by 35%
  - [ ] I-frames 1.2s; hit-stop & shake work correctly
  - [ ] Threat reaches 100% -> Phase banner slides in -> Boss "Iron Goliath" spawns (1 direct / 2 ricochet damage) + delayed white damage trail bar
  - [ ] Defeating Boss triggers `PERIMETER BREACHED` banner, expands arena `1280x720 -> 2560x1440`, and unlocks camera follow
  - [ ] 3 Capture Zones capture/contest properly, show colorblind-safe HUD badges (`[-]`, `[▲]`, `[!]`, `[✓]`) + mini progress bars, restore +1 HP, and clear sector
  - [ ] Off-screen zone arrows (`%dm`) and diegetic reload reticle accurately reflect state
  - [ ] Pause two-step abort (`CONFIRM ABORT?` 3.0s) and Game Over `0.8s` input lockout + Rank Stamp (`S/A/B/C`) work cleanly
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
| 6 | Showcase UI Polish Order & Precedence | Execute **Phase 13 (`T-055..T-059`)** before final manual QA (`T-039..T-041`). Follow `UI_DESIGN__TrenchArmorSurvival.md (v3.0)` for all procedural ornaments, Main Menu attract-mode/Field Manual, HUD enrichment, and After-Action Report rank stamps. |