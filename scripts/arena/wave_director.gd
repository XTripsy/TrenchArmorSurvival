class_name WaveDirector
extends Node

const ENEMY_SCENES: Dictionary = {
	"scout": "res://scenes/enemies/enemy_scout.tscn",
	"artillery": "res://scenes/enemies/enemy_artillery.tscn",
	"dreadnought": "res://scenes/enemies/enemy_dreadnought.tscn",
}
const MIN_INTERVAL: float = 0.8
const BASE_INTERVAL: float = 3.0
const INTERVAL_STEP: float = 0.15
const INTERVAL_PERIOD: float = 15.0
const SCOUT_ONLY_UNTIL: float = 45.0
const DREADNOUGHT_FROM: float = 90.0
const SCOUT_CUTOFF_MID: float = 0.70
const SCOUT_CUTOFF_LATE: float = 0.50
const ARTILLERY_CUTOFF_LATE: float = 0.85

var _arena: Node2D = null
var _enemies: Node2D = null
var _last_state: int = 0

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	_arena = get_parent() as Node2D
	_enemies = _arena.get_node_or_null("Enemies") as Node2D
	_last_state = int(GameManager.state)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	EventBus.game_state_changed.connect(_on_game_state_changed)
	if GameManager.state == GameManager.State.PLAYING:
		spawn_timer.start(spawn_interval(GameManager.time_survived))

func spawn_interval(t: float) -> float:
	var steps: float = floorf(maxf(t, 0.0) / INTERVAL_PERIOD)
	return maxf(MIN_INTERVAL, BASE_INTERVAL - INTERVAL_STEP * steps)

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

func spawn_enemy(scene_path: String) -> Node2D:
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
	enemy.global_position = _random_gate_position()
	return enemy

func spawn_wave() -> Node2D:
	if GameManager.state != GameManager.State.PLAYING:
		return null
	var t: float = GameManager.time_survived
	var enemy_type: String = pick_enemy_type(t, randf())
	return spawn_enemy(ENEMY_SCENES[enemy_type] as String)

func reset() -> void:
	spawn_timer.stop()
	if GameManager.state == GameManager.State.PLAYING:
		spawn_timer.start(spawn_interval(GameManager.time_survived))

func _random_gate_position() -> Vector2:
	if _arena == null:
		return Vector2.ZERO
	var gates: Array[Node] = []
	for node: Node in get_tree().get_nodes_in_group("spawn_gate"):
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
