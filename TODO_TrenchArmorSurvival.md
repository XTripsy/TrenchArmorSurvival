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

**Snapshot:** 2026-11-25 · Engine `4.7.2.stable.steam.ed1daf0bf` · **Next: Phase 12 — Professional UI/UX Overhaul (T-050..T-054), then Phase 9 QA (T-039..T-041)**

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
| 9 — QA & Release | T-039..T-041 | 🔄 Berjalan (manual) | Akan dikerjakan manual setelah Phase 12 UI Overhaul selesai |
| 10 — Boss & Map Expansion | T-042..T-045 | ✅ Selesai + terverifikasi | Harness headless & windowed `PASS` 55/55 exit 0; `--headless --editor --quit` exit 0; `--headless --quit` exit 0 |
| 11 — Territory Invasion & Playtest UI | T-046..T-049 | ✅ Selesai + terverifikasi | Harness headless & windowed `PASS` 55/55 exit 0; `--headless --editor --quit` exit 0; `--headless --quit` exit 0 |
| 12 — Professional UI/UX Overhaul | T-050..T-054 | ✅ Selesai + terverifikasi | Editor parse exit 0; HUD harness 5/5; diegetic/menu harness 8/8; Phase 9 tetap manual |

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

### 1.2 UI Design Tokens (`UI_DESIGN §2` — Single Source of Truth)
| Token Name | Hex Code | RGBA (`Color`) | Usage & Semantic Role |
|---|---|---|---|
| `UI_BG_DARK` | `#141618` | `(0.078, 0.086, 0.094, 0.90)` | Base surface for HUD cards & modals |
| `UI_SURFACE` | `#22262A` | `(0.133, 0.149, 0.165, 0.95)` | Normal buttons, empty bar tracks, neutral nodes |
| `UI_SURFACE_HOVER` | `#2E343B` | `(0.180, 0.204, 0.231, 1.0)` | Interactive hover / focus background |
| `UI_BORDER_STEEL` | `#4D5660` | `(0.302, 0.337, 0.376, 1.0)` | Panel & button border (`border_width = 2px`) |
| `UI_BORDER_ACTIVE` | `#E0AF3E` | `(0.878, 0.686, 0.243, 1.0)` | Hover/Focus border & tactical accent |
| `UI_TEXT_PRIMARY` | `#F4F1EA` | `(0.957, 0.945, 0.918, 1.0)` | Primary text, score digits, screen titles |
| `UI_TEXT_MUTED` | `#A8B2BC` | `(0.659, 0.698, 0.737, 1.0)` | Secondary labels, timer, hotkey hints |
| `UI_TEXT_DANGER` | `#FF6B6B` | `(1.000, 0.420, 0.420, 1.0)` | Boss warning text & Game Over header |
| `SEMANTIC_ALLY` | `#5E943B` | `(0.369, 0.580, 0.231, 1.0)` | Active HP segments, `CAPTURED` zone |
| `SEMANTIC_WARN` | `#E59528` | `(0.898, 0.584, 0.157, 1.0)` | Threat meter, `CAPTURING` zone |
| `SEMANTIC_DANGER` | `#D13B3B` | `(0.820, 0.231, 0.231, 1.0)` | Boss HP fill, critical HP (`HP == 1`), `CONTESTED` zone |
| `SEMANTIC_CRIT` | `#FF6A1A` | `(1.000, 0.416, 0.102, 1.0)` | Floating combat text for `2x RICOCHET KILL` |

### 1.3 Typography, Spacing & Viewport Rules (`UI_DESIGN §1 & §2.2–2.3`)
* **Viewport & Scaling:** Base resolution `1280x720`, Stretch Mode `canvas_items`, Stretch Aspect `expand`. HUD on `CanvasLayer (layer = 1)`, Modals/Overlays on `CanvasLayer (layer = 2)`.
* **Font:** `SystemFont` fallback chain `["JetBrains Mono", "Consolas", "Liberation Mono", "Courier New"]`, `font_weight = 700` (Bold), `outline_size = 2`, `outline_color = #0B0C0E`.
* **Scale:** `TYPE_DISPLAY = 48 px` (`+2 px` letter spacing), `TYPE_METRIC = 24 px` (`%06d`), `TYPE_HEADER = 18 px`, `TYPE_LABEL = 14 px`, `TYPE_MICRO = 12 px`.
* **Grid & Radius:** `8 px` base grid (margins/paddings multiples of `4 px` / `8 px`), `24 px` safe screen margin, `12 px` horizontal / `8 px` vertical panel padding, `2 px` corner radius for micro bars, `4 px` corner radius for panels & buttons.

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
    └── ui/            ui_theme_builder.gd  main_menu.gd  hud.gd  pause_menu.gd  game_over_menu.gd  floating_text.gd
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

## PHASE 12 — Professional UI/UX Overhaul (`UI_DESIGN__TrenchArmorSurvival.md`)

- [x] **T-050** Create `scripts/ui/ui_theme_builder.gd` (`UIThemeBuilder`) & Button Pivot Helper (`UI_DESIGN §2 & §4.1`)
  - Define static/constant design tokens matching §1.2 (`UI_BG_DARK`, `UI_SURFACE`, `UI_SURFACE_HOVER`, `UI_BORDER_STEEL`, `UI_BORDER_ACTIVE`, `UI_TEXT_PRIMARY`, `UI_TEXT_MUTED`, `UI_TEXT_DANGER`, `SEMANTIC_ALLY`, `SEMANTIC_WARN`, `SEMANTIC_DANGER`, `SEMANTIC_CRIT`) and typography scale constants (`TYPE_DISPLAY = 48`, `TYPE_METRIC = 24`, `TYPE_HEADER = 18`, `TYPE_LABEL = 14`, `TYPE_MICRO = 12`).
  - Implement procedural `SystemFont` builder (`["JetBrains Mono", "Consolas", "Liberation Mono", "Courier New"]`, weight `700`, `outline_size = 2`, `outline_color = #0B0C0E`) and `StyleBoxFlat` generators for panels (`4 px` radius, `2 px` border, `12 px` H / `8 px` V padding) and buttons across all 4 states: Normal, Hover/Focus (`UI_BORDER_ACTIVE`), Pressed (`UI_BG_DARK`), and Disabled (`modulate.a = 0.45`).
  - Provide a reusable button attachment helper (`setup_tactical_button(btn: Button) -> void`) that enforces `pivot_offset = size / 2` on `ready` and `resized`, connects `mouse_entered` / `focus_entered` / `mouse_exited` / `focus_exited` / `button_down` / `button_up` scale tweens (`1.03` hover, `0.97` pressed, `0.1s`), and triggers metallic click SFX via `AudioManager`.
  - **DoD:** `UIThemeBuilder` compiles with strict static typing and generates consistent `Theme` / `StyleBoxFlat` resources and symmetric button pivot scaling with zero external font/image assets.
- [x] **T-051** Upgrade `scripts/ui/hud.gd` — 3-Zone Tactical Layout, Segmented Armor Bar & Minimap (`UI_DESIGN §3.1–3.3`)
  - Ensure HUD runs on `CanvasLayer (layer = 1)` with `24 px` viewport safe margins and `8 px` grid alignment.
  - **Top-Left (`ARMOR INTEGRITY`):** Render `TYPE_MICRO` label + segmented `HBoxContainer` (`separation = 4 px`, `36x14 px` per segment, auto-scaling to `28x14 px` if `MAX_HP > 5`). Active segments use `SEMANTIC_ALLY` (`#84C458` `1 px` border), empty use `UI_SURFACE` (`UI_BORDER_STEEL` border). When `HP == 1`, switch active fill to `SEMANTIC_DANGER` with a `2 Hz` alpha pulse tween (`0.55 <-> 1.0`). On damage, flash the lost segment white (`#FFFFFF`) for `0.15s` before dimming to `UI_SURFACE`.
  - **Top-Center (Dynamic Phase & Objective Tracker):** Transition between phases using a `0.25s` fade + `8 px` vertical slide tween:
    1. `SKIRMISH`: `SECTOR %02d — THREAT LEVEL` (`TYPE_LABEL`) + `336x12 px` progress bar (`SEMANTIC_WARN`).
    2. `BOSS`: `WARNING: IRON GOLIATH` (`TYPE_HEADER`, `UI_TEXT_DANGER`) + `440x16 px` Boss HP bar (`SEMANTIC_DANGER`) with a **delayed white damage trail bar** (`#FFFFFF`, `alpha = 0.85`) that shrinks after a `0.25s` delay over `0.30s` on hit.
    3. `INVASION`: `TERRITORY INVASION — CAPTURE OUTPOSTS` + `3` colorblind-safe tactical node badges (`72x24 px`, `separation = 12 px`): `NEUTRAL` (`01 [ - ]`), `CAPTURING` (`01 [ ▲ ]` + `%`), `CONTESTED` (`01 [ ! ]` + pulsing border), `CAPTURED` (`01 [ ✓ ]`).
  - **Top-Right (Telemetry & `160x90 px` Tactical Radar):** Right-aligned `SCORE` (`%06d` `TYPE_METRIC` with `1.0 -> 1.2 -> 1.0` `0.18s` scale punch anchored at center-right) + `TIME %02d:%02d`, with a `160x90 px` (`16:9`) minimap `8 px` below rendering arena bounds/obstacles (`UI_SURFACE`), capture zones (`r = 6 px`), enemies (`r = 2.5 px` `SEMANTIC_DANGER`, Boss `r = 5 px` white outline), and player (`r = 3.5 px` `#FFFFFF` + `8 px` turret direction line).
  - **DoD:** All 3 HUD zones match exact dimensions, tokens, colorblind-safe icons, critical HP pulse, Boss damage trail, and minimap Z-order without overlapping gameplay.
- [x] **T-052** Upgrade Diegetic & World-Space UI (`hud.gd` & `floating_text.gd`) (`UI_DESIGN §3.4`)
  - **Off-Screen Objective Pointers:** Clamp pointers `32 px` from viewport edges, rotate toward off-screen priority targets (`Boss` or uncaptured `CaptureZone`), and render tactical arrow + distance readout in meters (`%dm`, `TYPE_MICRO`).
  - **Diegetic Reload Reticle:** Render custom crosshair (`2 px` center dot + `4` lines of `6 px`) during `State.PLAYING`; expand line gap by `+8 px` upon firing and contract linearly back to `0 px` tied to remaining `fire_cooldown` (`0.45s`).
  - **Floating Combat Text (`scripts/ui/floating_text.gd`):** Move upward `32 px` over `0.70s` (`ease-out`) and fade out, styled by event type: Normal Kill (`+100`, `TYPE_LABEL`, `UI_TEXT_PRIMARY`), Ricochet Kill (`+200 RICOCHET!`, `TYPE_HEADER`, `SEMANTIC_CRIT`, `1.25x` scale pop), Outpost Secured (`OUTPOST SECURED (+1 HP)`, `TYPE_HEADER`, `SEMANTIC_ALLY`).
  - **DoD:** Reticle dynamically reflects `fire_cooldown`, off-screen arrows display accurate distance `%dm`, and floating combat text reflects normal/ricochet/outpost styling.
- [x] **T-053** Overhaul `main_menu.gd`, `pause_menu.gd` & `game_over_menu.gd` with Safety Guards (`UI_DESIGN §4.2`)
  - Place modal overlays on `CanvasLayer (layer = 2)` and apply `UIThemeBuilder` styles and `setup_tactical_button` to all buttons (`DEPLOY`, `RESUME`, `REDEPLOY`, `ABORT TO MENU`).
  - **Main Menu (`scripts/ui/main_menu.gd`):** Live battlefield backdrop with dark vignette (`alpha = 0.45`), `TYPE_DISPLAY` title with military accent rule, auto-focused `DEPLOY` button, and bottom control strip (`[WASD] DRIVE  |  [MOUSE] AIM & FIRE  |  [ESC] PAUSE`).
  - **Pause Overlay (`scripts/ui/pause_menu.gd`):** Full-screen dimmer `Color(0.04, 0.05, 0.06, 0.78)`, centered `360 px` tactical card (`TACTICAL PAUSE`, current run stats, quick `AUDIO: ON/OFF` toggle button, `RESUME`, and `ABORT TO MENU` with **Two-Step Abort Protection**: first click switches text to `CONFIRM ABORT?` with `SEMANTIC_DANGER` border for `3.0s`; second click within window exits to Main Menu).
  - **Game Over / Debriefing (`scripts/ui/game_over_menu.gd`):** Trigger after a `0.6s` dramatic delay post-player explosion; show `ARMOR DESTROYED` (`TYPE_DISPLAY`, `UI_TEXT_DANGER`), debriefing stats card (*Final Score*, *Sector Reached*, *Outposts Captured*, *Ricochet Kills*), and `REDEPLOY` button with **`0.8s` Input Lockout Protection** (both `REDEPLOY` button and `Space`/`Enter` shortcuts remain disabled for the first `0.8s` to prevent accidental skip while firing).
  - **DoD:** Two-step abort confirmation and `0.8s` Game Over input lockout work reliably, buttons scale cleanly from center, and `project.godot` stretch settings (`canvas_items` / `expand`) are verified.
- [x] **T-054** UI & Full-Loop Verification (`--headless` + Windowed Visual Check)
  - Run `godot --headless --quit` and automated harness checks covering `MainMenu -> Skirmish HUD -> Boss Damage Trail -> Invasion Zone Badges -> Pause 2-Step Abort -> Game Over 0.8s Lockout -> Redeploy`.
  - **DoD:** Exit code `0`, zero parse/typing/runtime errors, and all `UI_DESIGN` tokens & interactions verified.

---

## PHASE 9 — QA & Final Release

- [ ] **T-039** Playtest checklist (verify all base, expansion & UI mechanics):
  - [ ] Ricochet once, orange color, 2x score + floating text (`+200 RICOCHET!`)
  - [ ] Dreadnought: 2 direct hits / 1 ricochet hit
  - [ ] Sandbag destroyed on 3rd hit; bullets do not bounce
  - [ ] Mud slows player & enemies by 35%
  - [ ] I-frames 1.2s; hit-stop & shake work correctly
  - [ ] Threat reaches 100% -> Boss "Iron Goliath" spawns (1 direct / 2 ricochet damage) + delayed white damage trail bar
  - [ ] Defeating Boss expands arena `1280x720 -> 2560x1440` and unlocks camera follow
  - [ ] 3 Capture Zones capture/contest properly, show colorblind-safe HUD badges (`[-]`, `[▲]`, `[!]`, `[✓]`), restore +1 HP, and clear sector
  - [ ] Off-screen zone arrows (`%dm`), diegetic reload reticle, and `160x90` minimap accurately reflect state
  - [ ] Pause two-step abort (`CONFIRM ABORT?` 3.0s) and Game Over `0.8s` input lockout prevent accidental resets
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
| 6 | UI Implementation Order & Precedence | Execute **Phase 12 (`T-050..T-054`)** before final manual QA (`T-039..T-041`). Follow `UI_DESIGN__TrenchArmorSurvival.md` for all UI colors, typography, `CanvasLayer` z-separation, and menu safety guards. |