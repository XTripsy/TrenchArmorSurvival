class_name ArenaController
extends Node2D

const PLAYER_SPAWN: Vector2 = Vector2(640.0, 360.0)
const MAIN_MENU_SCENE: String = "res://scenes/main_menu.tscn"
const INNER_BOUNDS: Rect2 = Rect2(0.0, 0.0, 1280.0, 720.0)
const EXPANDED_BOUNDS: Rect2 = Rect2(-640.0, -360.0, 2560.0, 1440.0)
const CAPTURE_ZONE_SCENE: String = "res://scenes/environment/capture_zone.tscn"
const PILLBOX_SCENE: String = "res://scenes/enemies/enemy_pillbox.tscn"
const ZONE_POSITIONS: Array[Vector2] = [
	Vector2(-320.0, -140.0),
	Vector2(1600.0, -140.0),
	Vector2(1600.0, 900.0),
]
const PILLBOX_OFFSETS: Array[Vector2] = [
	Vector2(120.0, 0.0),
	Vector2(-120.0, 0.0),
	Vector2(0.0, 120.0),
]
const SECTOR_CLEAR_BONUS: int = 1000

var active_bounds: Rect2 = INNER_BOUNDS
var _expansion_started: bool = false
var _sector_transition: bool = false

@onready var expansion_barriers: Node2D = $ExpansionBarriers
@onready var invasion_sector: Node2D = $InvasionSector

func _ready() -> void:
	GameManager.reset_run()
	active_bounds = INNER_BOUNDS
	_expansion_started = false
	_sector_transition = false
	GameManager.change_state(GameManager.State.PLAYING)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_snap_player_to_spawn()
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.capture_zone_captured.connect(_on_capture_zone_captured)

func _snap_player_to_spawn() -> void:
	var player: Node2D = get_node_or_null("Player") as Node2D
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		player.global_position = PLAYER_SPAWN

func get_active_bounds() -> Rect2:
	return active_bounds

func reset_arena() -> void:
	GameManager.reset_run()
	active_bounds = INNER_BOUNDS
	_expansion_started = false
	_sector_transition = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	var director: Node = get_node_or_null("WaveDirector")
	if director != null and director.has_method("reset"):
		director.call("reset")

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
	AudioManager.stop_engine()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_boss_defeated(_boss_position: Vector2, _base_score: int) -> void:
	if _expansion_started:
		return
	_expansion_started = true
	_open_expansion()

func _open_expansion() -> void:
	for barrier: Node in expansion_barriers.get_children():
		var barrier_2d: Node2D = barrier as Node2D
		if barrier_2d != null:
			VFXManager.spawn_tank_explosion(barrier_2d.global_position)
		barrier.queue_free()
	active_bounds = EXPANDED_BOUNDS
	EventBus.map_expanded.emit(EXPANDED_BOUNDS)
	GameManager.set_phase(GameManager.Phase.INVASION)
	_spawn_invasion_sector()

func _spawn_invasion_sector() -> void:
	_clear_invasion_sector()
	var zone_scene: PackedScene = _load_scene(CAPTURE_ZONE_SCENE)
	var pillbox_scene: PackedScene = _load_scene(PILLBOX_SCENE)
	if zone_scene == null:
		return
	for i: int in ZONE_POSITIONS.size():
		var position: Vector2 = ZONE_POSITIONS[i]
		var zone: Area2D = zone_scene.instantiate() as Area2D
		if zone != null:
			zone.set("zone_id", i + 1)
			invasion_sector.add_child(zone)
			zone.global_position = position
		if pillbox_scene == null:
			continue
		var pillbox: Node2D = pillbox_scene.instantiate() as Node2D
		if pillbox != null:
			invasion_sector.add_child(pillbox)
			pillbox.global_position = position + PILLBOX_OFFSETS[i]

func _clear_invasion_sector() -> void:
	for child: Node in invasion_sector.get_children():
		child.queue_free()

func _load_scene(path: String) -> PackedScene:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as PackedScene

func _on_capture_zone_captured(_zone_id: int, captured_count: int, total_count: int) -> void:
	if GameManager.current_phase != GameManager.Phase.INVASION:
		return
	if captured_count < total_count or _sector_transition:
		return
	_sector_transition = true
	EventBus.sector_cleared.emit(GameManager.sector_index, SECTOR_CLEAR_BONUS)
	GameManager.add_score(SECTOR_CLEAR_BONUS)
	EventBus.camera_shake_requested.emit(14.0, 0.5)
	GameManager.begin_next_sector()
	_spawn_invasion_sector()
	_sector_transition = false
