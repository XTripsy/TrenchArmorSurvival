# Phase 4 — Enemies Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement BaseEnemy class and the three enemy types (Scout, Artillery, Dreadnought) with movement, attack patterns, hit/damage logic, ricochet instant-kill override, and mud slowdown support.

**Architecture:** `BaseEnemy` (`CharacterBody2D`) provides shared HP, hit flash, and `die()` logic. `EnemyScout`, `EnemyArtillery`, and `EnemyDreadnought` inherit from `BaseEnemy` and override unique behaviors (chasing/contact damage, range stopping/firing, 2 HP + ricochet instakill).

**Tech Stack:** Godot 4.2+ GDScript (Strict static typing).

**Spec:** `docs/superpowers/specs/2026-11-06-phase4-enemies-design.md`

## Global Constraints

- Strict static typing on all `var`, parameters, and return types.
- Node groups: `"player"` for player target lookup.
- Layers: Enemy on Layer 2, mask 1, 2, 3, 4, 6.
- Cross-system communication via `EventBus` only (`EventBus.enemy_destroyed`).

---

### Task 1: Base Enemy (`scripts/enemies/base_enemy.gd`) (T-016)

**Files:**
- Create: `scripts/enemies/base_enemy.gd`

**Interfaces:**
- Produces: `class_name BaseEnemy extends CharacterBody2D` with `@export var max_hp: int`, `@export var move_speed: float`, `@export var base_score: int`, `var hp: int`, `var speed_multiplier: float`, `take_damage(amount: int, from_ricochet: bool)`, `die(from_ricochet: bool)`, `get_player() -> Node2D`.

- [x] **Step 1: Implement `scripts/enemies/base_enemy.gd`**
  Write `BaseEnemy` with HP initialization, hit flash via modulate tween, `take_damage()`, `die()` emitting `EventBus.enemy_destroyed`, and `get_player()` helper.

- [x] **Step 2: Verify `BaseEnemy` script structure**
  Check that script exists and has strict typing without parse errors.

---

### Task 2: Enemy Scout (`enemy_scout.tscn` + `enemy_scout.gd`) (T-017)

**Files:**
- Create: `scenes/enemies/enemy_scout.tscn`
- Create: `scripts/enemies/enemy_scout.gd`

**Interfaces:**
- Consumes: `BaseEnemy` from Task 1.
- Produces: `class_name EnemyScout extends BaseEnemy`.

- [x] **Step 1: Implement `scripts/enemies/enemy_scout.gd`**
  Set `max_hp = 1`, `move_speed = 250.0`, `base_score = 100`. In `_physics_process()`, move directly toward player applying `speed_multiplier`. Check slide collisions for `PlayerTank` / `"player"` group to deal 1 damage and `die(false)`.

- [x] **Step 2: Create `scenes/enemies/enemy_scout.tscn`**
  Node root `EnemyScout` (`CharacterBody2D`, layer 2, mask 1,2,3,4,6, FLOATING, script `enemy_scout.gd`). `CollisionShape2D` (Circle r14), `Polygon2D` visual (`#8B5A2B` light car + spiked bumper).

---

### Task 3: Enemy Artillery (`enemy_artillery.tscn` + `enemy_artillery.gd`) (T-018)

**Files:**
- Create: `scenes/enemies/enemy_artillery.tscn`
- Create: `scripts/enemies/enemy_artillery.gd`

**Interfaces:**
- Consumes: `BaseEnemy` from Task 1, `enemy_bullet.tscn` from Phase 3.
- Produces: `class_name EnemyArtillery extends BaseEnemy`.

- [x] **Step 1: Implement `scripts/enemies/enemy_artillery.gd`**
  Set `max_hp = 1`, `move_speed = 110.0`, `base_score = 200`. Rotate toward player. If `distance > 350.0`, move forward using `speed_multiplier`; if `≤ 350.0`, set `velocity = Vector2.ZERO`. Fire `enemy_bullet.tscn` (speed 400.0) every 2.5s using `FireTimer`.

- [x] **Step 2: Create `scenes/enemies/enemy_artillery.tscn`**
  Node root `EnemyArtillery` (`CharacterBody2D`, layer 2, mask 1,2,3,4,6, FLOATING, script `enemy_artillery.gd`). `CollisionShape2D` (Rectangle 36×24), `Polygon2D` visual (`#36393F` dark gray), `MuzzleMarker` (`Marker2D` at (24, 0)), `FireTimer` (`Timer`).

---

### Task 4: Enemy Dreadnought & Mud Integration (`enemy_dreadnought.tscn` + `enemy_dreadnought.gd`) (T-019, T-020)

**Files:**
- Create: `scenes/enemies/enemy_dreadnought.tscn`
- Create: `scripts/enemies/enemy_dreadnought.gd`

**Interfaces:**
- Consumes: `BaseEnemy` from Task 1, `enemy_bullet.tscn` from Phase 3.
- Produces: `class_name EnemyDreadnought extends BaseEnemy`.

- [x] **Step 1: Implement `scripts/enemies/enemy_dreadnought.gd`**
  Set `max_hp = 2`, `move_speed = 70.0`, `base_score = 500`. Fire `enemy_bullet.tscn` (speed 350.0) every 3.5s. Override `take_damage(amount, from_ricochet)`: if `from_ricochet` is true, call `super.take_damage(max_hp, true)` to instantly destroy it; else call `super.take_damage(amount, false)`.

- [x] **Step 2: Create `scenes/enemies/enemy_dreadnought.tscn`**
  Node root `EnemyDreadnought` (`CharacterBody2D`, layer 2, mask 1,2,3,4,6, FLOATING, script `enemy_dreadnought.gd`). `CollisionShape2D` (Rectangle 44×32), `Polygon2D` visual (`#8B3A3A` dark red Mark V shape), `MuzzleMarker` (`Marker2D` at (26, 0)), `FireTimer` (`Timer`).

- [x] **Step 3: Verify all 3 enemy types with temporary test harness `tests/phase4_check.tscn`**
  Run headless verification of:
  - Base enemy HP / death signal
  - Scout chasing & contact damage
  - Artillery distance threshold & firing timer
  - Dreadnought 2 HP direct hit vs 1 ricochet instakill
  - Mud slowdown (`speed_multiplier`)
  Clean up temporary test harness upon completion.
