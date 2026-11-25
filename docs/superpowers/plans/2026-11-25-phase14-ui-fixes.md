# Phase 14 UI Fixes & Polish Implementation Plan

**Goal:** Resolve AAR modal overlap, Game Over loop state, HUD icon/color readability, and Main Menu Field Manual diagram confusion.

**Architecture:**
- **Modal Repair:** Adjust Game Over UI layout and reset state management during retry.
- **Visuals:** Convert radar/HUD markers to circular procedural drawing, improve high-contrast typography, fix diagram logic.

## Tasks
1. **T-061: UI Fixes (Game Over & Modal)**
   - Fix Game Over overlap (anchor resizing or layout container adjustment).
   - Fix Game Over reset loop (ensure state logic doesn't re-trigger).
2. **T-062: Radar & Icon Refactor**
   - Circle radar icons, distinction via color/size (Player=White/Circle, Enemy=Red/Circle, Boss=Red/Large Circle).
3. **T-063: Field Manual Fixes & Contrast**
   - Separate visualization logic for manual tabs, verify contrast ratio.

## Ledger
- None.

---

### Task 1: T-061 UI Fixes (Game Over & Modal)
- Read `game_over_menu.tscn` to adjust layout or offsets.
- Ensure `_on_redeploy_pressed` triggers a clean state reset in `GameManager`.
- Commit `fix(ui): T-061 fix game over modal overlap and state reset loop`.

### Task 2: T-062 Radar & Icon Refactor
- Update `scripts/ui/hud.gd`'s `_draw_minimap` to use circle shapes only.
- Differentiate Player, Enemy, Boss by color/size.
- Commit `feat(ui): T-062 switch radar to circular icons with visual distinction`.

### Task 3: T-063 Field Manual Fixes & Contrast
- Update `scripts/ui/main_menu.gd` manual logic.
- Audit `UIThemeBuilder` colors against `UI_DESIGN` contrast requirements (WCAG AAA).
- Commit `fix(ui): T-063 fix field manual logic and contrast ratios`.

### Task 4: T-064 Final Verification
- Verify all fixes.
- Commit `docs(todo): T-064 verify ui fixes`.
