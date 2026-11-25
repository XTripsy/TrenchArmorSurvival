# Phase 12 Professional UI/UX Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the legacy HUD and menu presentation with the procedural tactical UI specified by `UI_DESIGN__TrenchArmorSurvival.md`, including accessible button states and safety guards.

**Architecture:** `UIThemeBuilder` owns tokens, fonts, styles, and button behavior. HUD remains an event-driven CanvasLayer and uses procedural Control drawing for minimap, pointers, badges, armor, and reticle. Menus consume the shared builder and keep state transitions through existing arena/GameManager interfaces.

**Tech Stack:** Godot 4.7 GDScript, SystemFont, Theme, StyleBoxFlat, Control._draw(), Tween, AudioStreamGenerator.

**Spec:** `UI_DESIGN__TrenchArmorSurvival.md`, TODO Phase 12 T-050..T-054.

## Global Constraints
- Strict static typing for every variable, parameter, and return type.
- Zero external visual assets; procedural UI only.
- UI CanvasLayer HUD layer 1, modal overlays layer 2.
- Use UI tokens exactly as specified; no Phase 9 work.
- Cross-system gameplay communication continues through EventBus.
- Keyboard activation and visible focus states must remain functional.

## Review Focus
1. Button resize after layout must preserve centered pivot and not accumulate signal connections; pinned by T-050 harness.
2. Boss HP damage trail must never exceed current/max bounds and must converge after repeated hits; pinned by T-051 harness.
3. Capture badge state must use symbols plus text, not color alone; pinned by T-051 harness.
4. Two-step abort must expire after 3 seconds and reject stale confirmation; pinned by T-053 harness.
5. Game-over shortcuts must remain blocked for 0.8 seconds, including repeated input; pinned by T-053 harness.

### Task 1: T-050 UIThemeBuilder and Button Helper
- Create `scripts/ui/ui_theme_builder.gd` with exact UI color and typography constants, `build_system_font()`, `panel_style()`, `button_theme()`, and `setup_tactical_button(btn: Button) -> void`.
- Test with a temporary Godot harness for token values, generated styles, pivot centering, hover/pressed scales, and idempotent resize wiring.
- Commit `feat(ui): T-050 add tactical theme builder and button helper`.

### Task 2: T-051 HUD v2
- Modify `scripts/ui/hud.gd` and `scenes/ui/hud.tscn` to layer 1, safe margins, segmented armor, phase transitions, threat/boss bars with delayed white trail, invasion badges, right telemetry, 160x90 radar, and token styling.
- Preserve existing minimap/objective data sources and EventBus subscriptions.
- Test HUD phase transitions, armor critical state, badge symbols, score punch, radar bounds, and boss trail convergence.
- Commit `feat(ui): T-051 overhaul tactical HUD layout and radar`.

### Task 3: T-052 Diegetic Feedback
- Modify `scripts/ui/hud.gd` for 32px-clamped objective pointers, meter labels, and fire-linked reticle spread.
- Modify `scripts/ui/floating_text.gd` and VFXManager call metadata so normal, ricochet, sector/outpost messages use specified colors, sizes, scale pop, and 32px/0.70s motion.
- Test pointer clamping, reticle cooldown recovery, and floating text style metadata.
- Commit `feat(ui): T-052 add diegetic reticle pointers and combat text`.

### Task 4: T-053 Menu Safety Guards
- Modify `main_menu.gd/.tscn`, `pause_menu.gd/.tscn`, and `game_over_menu.gd/.tscn` to use layer 2 overlays, shared styles, focus, controls, audio toggle, two-step abort, dramatic 0.6s game-over delay, and 0.8s redeploy lockout.
- Add real stats for sector and zones captured.
- Test all button behavior, keyboard flow, abort expiry, audio toggle, and game-over lockout.
- Commit `feat(ui): T-053 overhaul menus with safety guards`.

### Task 5: T-054 Verification and Documentation
- Create a temporary `tests/phase12_check.gd/.tscn` harness covering menu -> HUD -> boss trail -> invasion badges -> pause abort -> game over lockout -> redeploy.
- Run harness, editor scan, headless quit, and windowed smoke test; fix failures using TDD.
- Delete temporary tests, update TODO progress and Phase 12 checklist, commit `docs(todo): T-054 verify professional UI overhaul`.
