# Phase 13 Showcase Visual Polish & Rich Command UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform Main Menu, HUD, and Modals into a polished showcase-ready tactical command center following `UI_DESIGN__TrenchArmorSurvival.md (v3.0)`, with zero external assets and full procedural ornamentation.

**Architecture:** 
- `UIThemeBuilder` extended with Phase 13 tokens (`UI_BG_ELEVATED`, `UI_ORNAMENT_DIM`, `TYPE_HERO`, `TYPE_DISPLAY`) and keycap badge generator.
- `TacticalFrame` (`scripts/ui/tactical_frame.gd`) reusable control component for L-brackets, scanlines, and hazard stripes.
- `main_menu.gd` upgraded with live battle backdrop, military crest emblem, and auto-cycling interactive Field Manual tabs.
- `hud.gd` upgraded with chassis status card, rotating mini tank icon, chamfered armor plates, phase milestone ticks, ricochet streak pill, sweeping radar scope, and Phase Transition Banner overlay (`CanvasLayer layer = 2`).
- `pause_menu.gd` & `game_over_menu.gd` upgraded with AAR table layout, procedural Rank Stamp (`S/A/B/C`), and intact safety guards.

**Tech Stack:** Godot 4.7 GDScript, Control._draw(), StyleBoxFlat, Theme, SystemFont, Tween.
**Spec:** `UI_DESIGN__TrenchArmorSurvival.md (v3.0)`, TODO Phase 13 T-055..T-059.

## Global Constraints
- Strict static typing for every variable, parameter, and return type.
- Zero external visual assets; procedural UI only.
- Layer hierarchy: HUD (`CanvasLayer 1`), Phase Banners & Vignette (`CanvasLayer 2`), Modals (`CanvasLayer 3`).
- Phase 9 must remain untouched.

---

### Task 1: T-055 TacticalFrame and UIThemeBuilder Extension
- Create `scripts/ui/tactical_frame.gd` extending `Control` with properties: `show_brackets: bool = true`, `show_scanlines: bool = true`, `show_hazard_stripes: bool = false`, `accent_color: Color = UIThemeBuilder.UI_BORDER_STEEL`. Implement `_draw()` to render 8x8 corner L-brackets, horizontal scanlines every 4px, and 45° hazard stripes.
- Extend `UIThemeBuilder` with `UI_BG_ELEVATED` (`#1B1E22`), `UI_ORNAMENT_DIM` (`#6E7A87`), `TYPE_HERO` (52), `TYPE_DISPLAY` (44), and `create_keycap_badge(key_text: String, action_text: String) -> Control`.
- Test with temporary harness and commit `feat(ui): T-055 add tactical frame and keycap badges`.

### Task 2: T-056 Showcase Main Menu War-Room Console
- Modify `scripts/ui/main_menu.gd` and `scenes/main_menu.tscn`:
  - Background live battle preview / coordinate grid vignette overlay.
  - Left command column (`width = 480 px`): procedural military emblem (`72x72 px` `_draw()` shield, tank, star, chevrons), hero title `TRENCH ARMOR` (`TYPE_HERO`), subtitle strip, and action stack (`DEPLOY TO SECTOR` with hover chevrons, `TACTICAL INTEL`, `QUIT`).
  - Right interactive Field Manual card (`width = 440 px`, `TacticalFrame`) with 3 auto-cycling/clickable tabs (`[1] COMBAT`, `[2] ESCALATION`, `[3] INVASION`) and `140 px` vector diagrams (`_draw()`).
  - Bottom telemetry footer with physical keycap badges and best record.
- Test main menu layout and tabs; commit `feat(ui): T-056 upgrade main menu to tactical war-room console`.

### Task 3: T-057 Enrich HUD Visuals, Chassis Silhouette & Radar Sweep
- Modify `scripts/ui/hud.gd`:
  - Wrap top HUD cards in `TacticalFrame`.
  - Top-Left: `CHASSIS // VANGUARD-01` header, status pill (`NOMINAL/CAUTION/CRITICAL`), rotating mini tank icon (`36x36 px` `_draw()`), and chamfered parallelogram armor plates (`38x16 px`).
  - Top-Center: Phase counter (`PHASE 01/03`), Skirmish threat bar with `25/50/75%` milestone ticks, Boss bar with hazard stripes & ricochet weakness subtitle, and 3 Invasion outpost badges with mini `3 px` progress bars.
  - Top-Right: Ricochet Streak pill (`SEMANTIC_CRIT`), minimap upgraded to `168x94 px` with `A1-B2` grid lines and rotating radar sweep line (`0.5 rev/s`), and custom reticle reload arc.
  - CanvasLayer layer 2 Phase Transition Banner (`1.8s` slide-in) and HP==1 crimson vignette.
- Test HUD features; commit `feat(ui): T-057 enrich hud visuals, chamfered armor and radar sweep`.

### Task 4: T-058 Upgrade Pause & Game Over After-Action Report Modals
- Modify `scripts/ui/pause_menu.gd/.tscn` and `scripts/ui/game_over_menu.gd/.tscn`:
  - Place modals on `CanvasLayer (layer = 3)` with `TacticalFrame`.
  - Pause: hazard header bar, quick controls strip, audio toggle, resume, and two-step abort (`CONFIRM ABORT?` 3.0s).
  - Game Over: 0.6s dramatic delay, AAR combat report 4-row alternating table (`UI_BG_ELEVATED`), `NEW RECORD!` badge, procedural Rank Stamp (`76x76 px` `_draw()` S/A/B/C rank with `2.2x -> 1.0x` impact tween), and `0.8s` input lockout.
- Test modal flows and rank stamp; commit `feat(ui): T-058 upgrade pause and game over after-action report modals`.

### Task 5: T-059 Phase 13 Showcase Verification
- Create automated harness for Main Menu -> HUD -> Phase Banner -> Pause -> Game Over Rank Stamp.
- Run headless engine check, editor scan, and smoke test. Clean up test files, update TODO progress log, and commit `docs(todo): T-059 verify showcase visual polish and rich command UI`.
