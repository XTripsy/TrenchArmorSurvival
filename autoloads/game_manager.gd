extends Node

enum State { MENU, PLAYING, PAUSED, GAME_OVER }
enum Phase { SKIRMISH, BOSS, INVASION }

const MAX_THREAT: float = 100.0
const ZONES_PER_SECTOR: int = 3
const ZONE_CAPTURE_SCORE: int = 500

var state: State = State.MENU
var score: int = 0
var time_survived: float = 0.0
var ricochet_kills: int = 0
var current_phase: Phase = Phase.SKIRMISH
var sector_index: int = 1
var threat_progress: float = 0.0
var zones_captured: int = 0
var zones_total: int = ZONES_PER_SECTOR

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
	current_phase = Phase.SKIRMISH
	sector_index = 1
	threat_progress = 0.0
	zones_captured = 0
	zones_total = ZONES_PER_SECTOR
	Engine.time_scale = 1.0

func set_phase(new_phase: Phase) -> void:
	if current_phase == new_phase:
		return
	current_phase = new_phase
	EventBus.phase_changed.emit(int(current_phase))

func add_score(amount: int) -> void:
	score += maxi(0, amount)
	EventBus.score_updated.emit(score, ricochet_kills)

func register_zone_captured(zone_id: int) -> void:
	zones_captured = mini(zones_total, zones_captured + 1)
	add_score(ZONE_CAPTURE_SCORE)
	EventBus.capture_zone_captured.emit(zone_id, zones_captured, zones_total)

func begin_next_sector() -> void:
	sector_index += 1
	zones_captured = 0
	zones_total = ZONES_PER_SECTOR

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
	add_score(gained)
	if current_phase == Phase.SKIRMISH:
		_add_threat(_threat_for_score(base_score))

func _threat_for_score(base_score: int) -> float:
	if base_score > 200:
		return 25.0
	if base_score > 100:
		return 15.0
	return 10.0

func _add_threat(amount: float) -> void:
	if amount <= 0.0:
		return
	threat_progress = clampf(threat_progress + amount, 0.0, MAX_THREAT)
	EventBus.threat_updated.emit(threat_progress, MAX_THREAT)
	if current_phase == Phase.SKIRMISH and threat_progress >= MAX_THREAT:
		set_phase(Phase.BOSS)

func _on_player_died() -> void:
	change_state(State.GAME_OVER)
