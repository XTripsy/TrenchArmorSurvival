extends Node

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

var state: State = State.MENU
var score: int = 0
var time_survived: float = 0.0
var ricochet_kills: int = 0

var _hit_stop_sequence: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)
	EventBus.player_died.connect(_on_player_died)

func _process(delta: float) -> void:
	if state == State.PLAYING:
		time_survived += delta

func change_state(new_state: State) -> void:
	state = new_state
	get_tree().paused = state == State.PAUSED
	EventBus.game_state_changed.emit(int(state))

func reset_run() -> void:
	score = 0
	time_survived = 0.0
	ricochet_kills = 0
	Engine.time_scale = 1.0

func trigger_hit_stop(duration: float = 0.05) -> void:
	_hit_stop_sequence += 1
	var sequence: int = _hit_stop_sequence
	Engine.time_scale = 0.05
	var timer: SceneTreeTimer = get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(func() -> void:
		if sequence == _hit_stop_sequence:
			Engine.time_scale = 1.0
	)

func _on_enemy_destroyed(enemy_position: Vector2, base_score: int, was_ricochet: bool) -> void:
	var gained: int = base_score
	if was_ricochet:
		gained = base_score * 2
		ricochet_kills += 1
		VFXManager.spawn_floating_text(enemy_position, "+%d RICOCHET!" % gained)
	score += gained
	EventBus.score_updated.emit(score, ricochet_kills)

func _on_player_died() -> void:
	change_state(State.GAME_OVER)
