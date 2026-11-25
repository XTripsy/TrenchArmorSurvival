class_name BossGoliath
extends BaseEnemy

const BOSS_NAME: String = "IRON GOLIATH"
const BASE_HP: int = 16
const HP_PER_SECTOR: int = 4
const BASE_BOSS_SCORE: int = 1500
const BOSS_SPEED: float = 65.0
const BULLET_SCENE: String = "res://scenes/projectiles/enemy_bullet.tscn"
const BULLET_SPEED: float = 380.0
const SPREAD_ANGLES: Array[float] = [-0.314159, 0.0, 0.314159]
const MORTAR_RADIUS: float = 110.0
const MORTAR_WARNING_TIME: float = 1.1
const SPREAD_WINDUP: float = 0.35
const SPREAD_RECOVERY: float = 0.9
const MORTAR_WINDUP: float = 0.3
const MORTAR_RECOVERY: float = 0.5
const ADVANCE_DURATION: float = 1.6
const TURN_RATE: float = 5.0

enum AttackState { SPREAD, MORTAR, ADVANCE }

var _attack_state: AttackState = AttackState.ADVANCE
var _state_time: float = 0.0
var _attack_fired: bool = false
var _mortar_started: bool = false
var _mortar_position: Vector2 = Vector2.ZERO
var _warning: MortarWarning = null

@onready var muzzle_marker: Marker2D = $TurretPivot/MuzzleMarker


class MortarWarning:
	extends Node2D

	var radius: float = 110.0
	var duration: float = 1.1
	var detonate: Callable = Callable()
	var _elapsed: float = 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_elapsed += delta
		queue_redraw()
		if _elapsed >= duration:
			set_process(false)
			if detonate.is_valid():
				detonate.call(global_position)
			queue_free()

	func _draw() -> void:
		var ratio: float = clampf(_elapsed / duration, 0.0, 1.0)
		draw_circle(Vector2.ZERO, radius, Color(1.0, 0.266667, 0.266667, 0.12 + ratio * 0.14))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color("#FF4444"), 3.0)
		draw_arc(Vector2.ZERO, radius * ratio, 0.0, TAU, 48, Color(1.0, 0.266667, 0.266667, 0.85), 5.0)
		draw_line(Vector2(-radius, 0.0), Vector2(radius, 0.0), Color(1.0, 0.266667, 0.266667, 0.35), 1.5)
		draw_line(Vector2(0.0, -radius), Vector2(0.0, radius), Color(1.0, 0.266667, 0.266667, 0.35), 1.5)


func _ready() -> void:
	max_hp = BASE_HP + HP_PER_SECTOR * (GameManager.sector_index - 1)
	move_speed = BOSS_SPEED
	base_score = BASE_BOSS_SCORE
	super._ready()
	add_to_group("boss")
	EventBus.boss_spawned.emit(BOSS_NAME, hp, max_hp)

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	var player: Node2D = get_player()
	if player == null:
		return
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length_squared() > 0.0:
		rotation = lerp_angle(rotation, to_player.angle(), TURN_RATE * delta)
	_state_time += delta
	match _attack_state:
		AttackState.SPREAD:
			_update_spread()
		AttackState.MORTAR:
			_update_mortar()
		AttackState.ADVANCE:
			_update_advance(delta, to_player)

func _update_spread() -> void:
	velocity = Vector2.ZERO
	if not _attack_fired and _state_time >= SPREAD_WINDUP:
		_attack_fired = true
		perform_spread_volley()
	if _state_time >= SPREAD_WINDUP + SPREAD_RECOVERY:
		_next_attack()

func _update_mortar() -> void:
	velocity = Vector2.ZERO
	if not _mortar_started and _state_time >= MORTAR_WINDUP:
		_mortar_started = true
		begin_mortar_telegraph()
	if _state_time >= MORTAR_WINDUP + MORTAR_WARNING_TIME + MORTAR_RECOVERY:
		_next_attack()

func _update_advance(delta: float, to_player: Vector2) -> void:
	if to_player.length_squared() > 1.0:
		var direction: Vector2 = to_player.normalized()
		velocity = direction * move_speed * speed_multiplier
		move_and_slide()
	else:
		velocity = Vector2.ZERO
	if _state_time >= ADVANCE_DURATION:
		_next_attack()

func _next_attack() -> void:
	_state_time = 0.0
	_attack_fired = false
	_mortar_started = false
	match _attack_state:
		AttackState.SPREAD:
			_attack_state = AttackState.MORTAR
		AttackState.MORTAR:
			_attack_state = AttackState.ADVANCE
		_:
			_attack_state = AttackState.SPREAD

func perform_spread_volley() -> void:
	var player: Node2D = get_player()
	if player == null:
		return
	var origin: Vector2 = muzzle_marker.global_position if muzzle_marker != null else global_position
	var base_direction: Vector2 = (player.global_position - origin).normalized()
	AudioManager.play_enemy_cannon()
	for offset: float in SPREAD_ANGLES:
		_spawn_bullet(origin, base_direction.rotated(offset))

func _spawn_bullet(origin: Vector2, direction: Vector2) -> void:
	if not ResourceLoader.exists(BULLET_SCENE):
		return
	var packed: PackedScene = load(BULLET_SCENE) as PackedScene
	if packed == null:
		return
	var bullet: Node2D = packed.instantiate() as Node2D
	if bullet == null:
		return
	if bullet.get("direction") != null:
		bullet.set("direction", direction)
	if bullet.get("speed") != null:
		bullet.set("speed", BULLET_SPEED)
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(bullet)
	bullet.global_position = origin
	bullet.rotation = direction.angle()

func begin_mortar_telegraph() -> void:
	var player: Node2D = get_player()
	if player == null:
		return
	_mortar_position = player.global_position
	_warning = MortarWarning.new()
	_warning.radius = MORTAR_RADIUS
	_warning.duration = MORTAR_WARNING_TIME
	_warning.detonate = Callable(self, "_detonate_mortar")
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(_warning)
	_warning.global_position = _mortar_position

func _detonate_mortar(position: Vector2) -> void:
	AudioManager.play_explosion()
	VFXManager.spawn_tank_explosion(position)
	EventBus.camera_shake_requested.emit(8.0, 0.25)
	var player: Node2D = get_player()
	if player != null and player.global_position.distance_to(position) <= MORTAR_RADIUS:
		if player.has_method("take_damage"):
			player.call("take_damage", 1, false)
	_warning = null

func take_damage(amount: int, from_ricochet: bool = false) -> void:
	if not _alive:
		return
	var applied: int = 2 if from_ricochet else 1
	super.take_damage(applied, from_ricochet)
	EventBus.boss_hp_changed.emit(hp, max_hp)

func die(from_ricochet: bool = false) -> void:
	if not _alive:
		return
	EventBus.boss_defeated.emit(global_position, base_score)
	EventBus.camera_shake_requested.emit(14.0, 0.5)
	super.die(from_ricochet)
