class_name WaveDirector
extends Node

const ENEMY_SCENES: Dictionary = {
	"scout": "res://scenes/enemies/enemy_scout.tscn",
	"artillery": "res://scenes/enemies/enemy_artillery.tscn",
	"dreadnought": "res://scenes/enemies/enemy_dreadnought.tscn",
}
const BOSS_SCENE: String = "res://scenes/enemies/boss_goliath.tscn"
const MIN_INTERVAL: float = 0.65
const BASE_INTERVAL: float = 3.0
const INTERVAL_STEP: float = 0.15
const INTERVAL_PERIOD: float = 15.0
const SECTOR_INTERVAL_STEP: float = 0.1
const SCOUT_ONLY_UNTIL: float = 45.0
const DREADNOUGHT_FROM: float = 90.0
const SCOUT_CUTOFF_MID: float = 0.70
const SCOUT_CUTOFF_LATE: float = 0.50
const ARTILLERY_CUTOFF_LATE: float = 0.85
const BOSS_INTERVAL_MULTIPLIER: float = 2.0
const BOSS_SPAWN_POSITION: Vector2 = Vector2(640.0, 140.0)
const INVASION_PATROL_COUNT: int = 2

var _arena: Node2D = null
var _enemies: Node2D = null
var _last_state: int = 0
var _boss_spawned: bool = false

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	_arena = get_parent() as Node2D
	_enemies = _arena.get_node_or_null("Enemies") as Node2D
	_last_state = int(GameManager.state)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	EventBus.game_state_changed.connect(_on_game_state_changed)
	EventBus.phase_changed.connect(_on_phase_changed)
	if GameManager.state == GameManager.State.PLAYING:
		spawn_timer.start(spawn_interval(GameManager.time_survived))

func spawn_interval(t: float) -> float:
	var steps: float = floorf(maxf(t, 0.0) / INTERVAL_PERIOD)
	var interval: float = BASE_INTERVAL - INTERVAL_STEP * steps
	interval -= SECTOR_INTERVAL_STEP * float(maxi(0, GameManager.sector_index - 1))
	if GameManager.current_phase == GameManager.Phase.BOSS:
		interval *= BOSS_INTERVAL_MULTIPLIER
	return maxf(MIN_INTERVAL, interval)

func pick_enemy_type(t: float, roll: float) -> String:
	if t < SCOUT_ONLY_UNTIL:
		return "scout"
	if t < DREADNOUGHT_FROM:
		return "scout" if roll < SCOUT_CUTOFF_MID else "artillery"
	if roll < SCOUT_CUTOFF_LATE:
		return "scout"
	if roll < ARTILLERY_CUTOFF_LATE:
		return "artillery"
	return "dreadnought"

func spawn_enemy(scene_path: String, use_outer_gates: bool = false) -> Node2D:
	var enemy: Node2D = _instantiate_enemy(scene_path)
	if enemy == null:
		return null
	enemy.global_position = _random_gate_position(use_outer_gates)
	return enemy

func spawn_enemy_at(scene_path: String, position: Vector2) -> Node2D:
	var enemy: Node2D = _instantiate_enemy(scene_path)
	if enemy == null:
		return null
	enemy.global_position = position
	return enemy

func _instantiate_enemy(scene_path: String) -> Node2D:
	if not ResourceLoader.exists(scene_path):
		return null
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		return null
	var enemy: Node2D = packed.instantiate() as Node2D
	if enemy == null:
		return null
	var container: Node2D = _enemies if _enemies != null else _arena
	container.add_child(enemy)
	return enemy

func spawn_wave() -> Node2D:
	if GameManager.state != GameManager.State.PLAYING:
		return null
	var t: float = GameManager.time_survived
	var enemy_type: String = pick_enemy_type(t, randf())
	var use_outer: bool = GameManager.current_phase == GameManager.Phase.INVASION
	return spawn_enemy(ENEMY_SCENES[enemy_type] as String, use_outer)

func spawn_boss() -> Node2D:
	if _boss_spawned or not get_tree().get_nodes_in_group("boss").is_empty():
		return null
	var boss: Node2D = spawn_enemy_at(BOSS_SCENE, BOSS_SPAWN_POSITION)
	if boss != null:
		_boss_spawned = true
	return boss

func _spawn_invasion_patrols() -> void:
	for i: int in INVASION_PATROL_COUNT:
		var enemy_type: String = "scout" if i == 0 else "artillery"
		spawn_enemy(ENEMY_SCENES[enemy_type] as String, true)

func reset() -> void:
	spawn_timer.stop()
	if GameManager.state == GameManager.State.PLAYING:
		spawn_timer.start(spawn_interval(GameManager.time_survived))

func _random_gate_position(use_outer: bool) -> Vector2:
	if _arena == null:
		return Vector2.ZERO
	var group_name: String = "outer_spawn_gate" if use_outer else "spawn_gate"
	var gates: Array[Node] = []
	for node: Node in get_tree().get_nodes_in_group(group_name):
		if _arena.is_ancestor_of(node):
			gates.append(node)
	if gates.is_empty():
		return _arena.global_position
	var marker: Marker2D = gates.pick_random() as Marker2D
	return marker.global_position if marker != null else _arena.global_position

func _on_spawn_timer_timeout() -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	var t: float = GameManager.time_survived
	spawn_wave()
	spawn_timer.start(spawn_interval(t))

func _on_phase_changed(new_phase: int) -> void:
	if new_phase == int(GameManager.Phase.BOSS):
		spawn_boss()
	elif new_phase == int(GameManager.Phase.INVASION):
		_spawn_invasion_patrols()
	if GameManager.state == GameManager.State.PLAYING:
		spawn_timer.start(spawn_interval(GameManager.time_survived))

func _on_game_state_changed(new_state: int) -> void:
	var playing: int = int(GameManager.State.PLAYING)
	var paused: int = int(GameManager.State.PAUSED)
	if new_state == playing:
		if _last_state != paused:
			reset()
		else:
			spawn_timer.start(spawn_interval(GameManager.time_survived))
	else:
		spawn_timer.stop()
	_last_state = new_state
