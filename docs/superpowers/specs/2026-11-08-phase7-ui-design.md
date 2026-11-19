# Phase 7 — UI & Game Flow Design (T-028..T-034)

Status: approved for implementation.
Scope: `main_menu.tscn` + `main_menu.gd`, `hud.tscn` + `hud.gd`, `floating_text.tscn` + `floating_text.gd`, `pause_menu.tscn` + `pause_menu.gd`, `game_over_menu.tscn` + `game_over_menu.gd`, arena flow integration, main-scene setting.

Acuan: TODO T-028..T-034 dan GDD §9 (TAD tidak punya §7).

## Intent

Make the game playable end-to-end: Title → Arena → Pause/Game Over → Restart/Menu, with procedural military UI (zero assets) and a clean restart that leaves no enemies, bullets, debris, scorch marks, or tread marks behind.

## Goals

- `scenes/main_menu.tscn`:
  - Root `Control`, full rect, blueprint grid built procedurally with `Line2D` (40 px spacing, low-alpha blue-gray).
  - Title `TRENCH ARMOR SURVIVAL`, control guide `WASD = MOVE`, `MOUSE = AIM / SHOOT`.
  - Buttons `DEPLOY (START)` and `QUIT`.
  - `_ready()`: `GameManager.change_state(MENU)`, `Input.mouse_mode = VISIBLE`, `AudioManager.stop_engine()`, build grid.
  - Deploy → `get_tree().change_scene_to_file("res://scenes/arena.tscn")`; Quit → `get_tree().quit()`.
  - `project.godot` gets `application/run/main_scene="res://scenes/main_menu.tscn"`.
- `scenes/ui/hud.tscn` + `hud.gd` (CanvasLayer, layer 10):
  - Top-left: 3 shield icons (`Node2D` + `Polygon2D` + border `Line2D` + `Crack` `Line2D`).
  - Top-center: `SCORE: %06d` and `TIME: %02d:%02d`.
  - Score updates only via `EventBus.score_updated`; shields via `EventBus.player_damaged(current_hp, max_hp)`; time updated once per `_process` from `GameManager.time_survived`.
  - Reticle (`Node2D` with 4 `Line2D` + center dot) follows `get_viewport().get_mouse_position()` every frame; visible only while `GameManager.state == PLAYING`.
- `scenes/ui/floating_text.tscn` + `floating_text.gd`:
  - Root `Node2D`, child `Label`, yellow `#FFD700`, font size 16.
  - `setup(text: String) -> void` fills the label and starts a Tween: `global_position.y - 30`, `modulate.a → 0` over `0.8 s`, then `queue_free()`.
  - This is the contract `VFXManager.spawn_floating_text()` already probes with `has_method("setup")`.
- `scenes/ui/pause_menu.tscn` + `pause_menu.gd` (CanvasLayer, layer 20, `process_mode = ALWAYS`, hidden overlay):
  - `Esc` (`pause` action) toggles `PLAYING ↔ PAUSED`; ignored in other states.
  - Buttons `RESUME`, `RESTART`, `MAIN MENU`.
  - Restart → `ArenaController.restart_run()`; Main Menu → `ArenaController.return_to_menu()`.
- `scenes/ui/game_over_menu.tscn` + `game_over_menu.gd` (CanvasLayer, layer 30, `process_mode = ALWAYS`):
  - Listens to `game_state_changed`; shows on `GAME_OVER`.
  - Sepia overlay `#3A2A1E` alpha ~0.78, header `TANK DESTROYED`.
  - Stats: `FINAL SCORE: %06d`, `TIME SURVIVED: %02d:%02d`, `RICOCHET KILLS: %d` read from `GameManager` on show.
  - Buttons `REDEPLOY (SPACE / CLICK)` and `MAIN MENU`; `ui_accept` also redeploys.
- `arena_controller.gd` flow additions:
  - `_ready()`: `GameManager.reset_run()`, `GameManager.change_state(PLAYING)`, `Input.mouse_mode = HIDDEN`, snap player to `(640,360)`.
  - `restart_run() -> void`: `reset_run()`, `Engine.time_scale = 1.0`, unpause, `get_tree().reload_current_scene()`.
  - `return_to_menu() -> void`: `reset_run()`, `Engine.time_scale = 1.0`, unpause, `change_state(MENU)`, `change_scene_to_file("res://scenes/main_menu.tscn")`.
- `scenes/arena.tscn` instantiates `hud.tscn`, `pause_menu.tscn`, `game_over_menu.tscn`.

## Non-goals

- No audio changes beyond stopping the engine loop on the main menu.
- No new EventBus signals; menus talk to their parent `ArenaController`, which is scene-local, not cross-system.
- No external fonts or textures. Default font is the documented fallback.
- No changes to scoring, waves, or combat.

## Approaches Considered

1. **Scene ownership (selected A):**
   - A: `main_menu.tscn` is the main scene; gameplay UI lives inside `arena.tscn`; navigation uses `change_scene_to_file`. Restart reloads the arena, which structurally guarantees cleanup (T-034).
   - B: persistent `main.tscn` orchestrator that swaps content. Not listed in TAD §2 and adds a layer the spec does not ask for.
   - C: UI as autoloads. Hard to reset cleanly and mixes UI lifetime with gameplay state.
2. **Restart (selected A):**
   - A: `reset_run()` + `time_scale = 1.0` + unpause + `reload_current_scene()`. All bullets, enemies, particles, scorch marks, tread marks disappear with the old scene.
   - B: manually delete every dynamic node. Fragile and easy to miss effect classes.
3. **Reticle (selected A):**
   - A: part of `hud.gd`; a `Node2D` moved in `_process`. No extra script outside TAD §2.
   - B: separate `reticle.gd`. Not in the listed file structure.

## Contracts

### `main_menu.gd`
```gdscript
extends Control

const ARENA_SCENE: String = "res://scenes/arena.tscn"
const GRID_STEP: float = 40.0

@onready var blueprint_grid: Node2D = $BlueprintGrid
@onready var deploy_button: Button = $DeployButton
@onready var quit_button: Button = $QuitButton

func _ready() -> void:
	GameManager.change_state(GameManager.State.MENU)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.stop_engine()
	_build_blueprint_grid()
	deploy_button.pressed.connect(_on_deploy_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _build_blueprint_grid() -> void:
	# vertical/horizontal Line2D, step 40, color #2B4A5A alpha 0.22, width 1

func _on_deploy_pressed() -> void:
	get_tree().change_scene_to_file(ARENA_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()
```

### `hud.gd`
```gdscript
extends CanvasLayer

const MAX_SHIELDS: int = 3
const SHIELD_BROKEN_COLOR: Color = Color("#2A2A2A")

@onready var score_label: Label = $HUDRoot/ScoreLabel
@onready var time_label: Label = $HUDRoot/TimeLabel
@onready var shields: Node2D = $HUDRoot/Shields
@onready var reticle: Node2D = $HUDRoot/Reticle

func _ready() -> void:
	EventBus.score_updated.connect(_on_score_updated)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.game_state_changed.connect(_on_game_state_changed)
	_refresh_score(GameManager.score)
	_refresh_shields(3)

func _process(_delta: float) -> void:
	_refresh_time()
	reticle.position = get_viewport().get_mouse_position()
	reticle.visible = GameManager.state == GameManager.State.PLAYING

func _on_score_updated(new_score: int, _ricochet_kills: int) -> void:
	_refresh_score(new_score)

func _on_player_damaged(current_hp: int, _max_hp: int) -> void:
	_refresh_shields(current_hp)

func _on_game_state_changed(_new_state: int) -> void:
	reticle.visible = GameManager.state == GameManager.State.PLAYING

func _refresh_score(value: int) -> void:
	score_label.text = "SCORE: %06d" % value

func _refresh_time() -> void:
	var total: int = maxi(0, int(floor(GameManager.time_survived)))
	time_label.text = "TIME: %02d:%02d" % [total / 60, total % 60]

func _refresh_shields(current_hp: int) -> void:
	# visible intact icons = clamp(current_hp, 0, 3); broken ones get dark modulate + crack
```

### `floating_text.gd`
```gdscript
class_name FloatingText
extends Node2D

@onready var label: Label = $Label

func setup(text: String) -> void:
	label.text = text
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", global_position + Vector2(0.0, -30.0), 0.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(queue_free)
```

### `pause_menu.gd`
```gdscript
extends CanvasLayer

@onready var overlay: Control = $Overlay
@onready var resume_button: Button = $Overlay/ResumeButton
@onready var restart_button: Button = $Overlay/RestartButton
@onready var menu_button: Button = $Overlay/MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if GameManager.state == GameManager.State.PLAYING:
		_pause()
		get_viewport().set_input_as_handled()
	elif GameManager.state == GameManager.State.PAUSED:
		_resume()
		get_viewport().set_input_as_handled()

func _pause() -> void:
	overlay.visible = true
	GameManager.change_state(GameManager.State.PAUSED)

func _resume() -> void:
	overlay.visible = false
	GameManager.change_state(GameManager.State.PLAYING)
```

### `game_over_menu.gd`
```gdscript
extends CanvasLayer

@onready var overlay: Control = $Overlay
@onready var stats_label: Label = $Overlay/StatsLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	EventBus.game_state_changed.connect(_on_game_state_changed)
	# buttons: redeploy, menu

func _on_game_state_changed(new_state: int) -> void:
	if new_state == int(GameManager.State.GAME_OVER):
		_show_stats()
	else:
		overlay.visible = false
```

### `arena_controller.gd` additions
```gdscript
func restart_run() -> void:
	GameManager.reset_run()
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()

func return_to_menu() -> void:
	GameManager.reset_run()
	Engine.time_scale = 1.0
	get_tree().paused = false
	GameManager.change_state(GameManager.State.MENU)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
```

## Review Focus

1. Deploying from the menu starts a fresh run (score/time/ricochet reset) and waves begin.
2. Score updates only through `score_updated`; no per-frame polling of `GameManager.score`.
3. Shields break in order on each `player_damaged`; three hits show three broken shields.
4. Floating text uses `setup()` so `VFXManager` picks the scene instead of the procedural fallback, and it frees itself after 0.8 s.
5. `Esc` pauses/resumes only during gameplay; the pause overlay is clickable while the tree is paused.
6. Game over appears on `GAME_OVER` with the correct score/time/ricochet values.
7. Reticle is hidden in menus and while paused; the OS cursor is visible in menus and hidden in the arena.
8. Five consecutive restarts leave zero enemies/bullets/effects and a reset `GameManager`, with exit code 0 and no leaked game nodes.
