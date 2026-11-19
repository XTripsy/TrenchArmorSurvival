class_name ArenaController
extends Node2D

const PLAYER_SPAWN: Vector2 = Vector2(640.0, 360.0)
const MAIN_MENU_SCENE: String = "res://scenes/main_menu.tscn"

func _ready() -> void:
	GameManager.reset_run()
	GameManager.change_state(GameManager.State.PLAYING)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_snap_player_to_spawn()

func _snap_player_to_spawn() -> void:
	var player: Node2D = get_node_or_null("Player") as Node2D
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		player.global_position = PLAYER_SPAWN

func reset_arena() -> void:
	GameManager.reset_run()
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
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
