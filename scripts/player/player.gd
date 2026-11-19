class_name PlayerTank
extends CharacterBody2D

const MAX_HP: int = 3
const BASE_SPEED: float = 220.0
const TURN_SPEED: float = 10.0
const FIRE_COOLDOWN: float = 0.45
const RECOIL_FORCE: float = 40.0
const RECOIL_DECAY: float = 900.0
const IFRAME_DURATION: float = 1.2
const HIT_FLASH_DURATION: float = 0.1
const BULLET_SCENE: String = "res://scenes/projectiles/player_bullet.tscn"
const TREAD_MARK_SCENE: String = "res://scenes/player/tread_mark.tscn"
const TREAD_FADE: float = 3.0

var hp: int = MAX_HP
var speed_multiplier: float = 1.0
var is_invulnerable: bool = false
var _alive: bool = true
var _engine_moving: bool = false
var _fire_cooldown_left: float = 0.0
var _recoil_velocity: Vector2 = Vector2.ZERO
var _recoil_tween: Tween = null
var _iframe_tween: Tween = null
var _turret_base_x: float = 0.0
var _last_left_track: Vector2
var _last_right_track: Vector2
var _had_track_anchor: bool = false

@onready var hull_visual: Node2D = $HullVisual
@onready var turret_pivot: Node2D = $TurretPivot
@onready var turret_visual: Polygon2D = $TurretPivot/TurretVisual
@onready var muzzle_marker: Marker2D = $TurretPivot/MuzzleMarker
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var tread_timer: Timer = $TreadTimer

func _ready() -> void:
	hp = MAX_HP
	_turret_base_x = turret_visual.position.x
	tread_timer.timeout.connect(_on_tread_timer_timeout)
	AudioManager.play_engine(false)

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * BASE_SPEED * speed_multiplier + _recoil_velocity
	move_and_slide()
	_recoil_velocity = _recoil_velocity.move_toward(Vector2.ZERO, RECOIL_DECAY * delta)
	_fire_cooldown_left = maxf(0.0, _fire_cooldown_left - delta)
	var has_input: bool = input_vector.length_squared() > 0.0
	if has_input:
		hull_visual.rotation = lerp_angle(hull_visual.rotation, input_vector.angle(), TURN_SPEED * delta)
	if has_input and not _had_track_anchor:
		_last_left_track = _track_point(-13.0)
		_last_right_track = _track_point(13.0)
		_had_track_anchor = true
	elif not has_input:
		_had_track_anchor = false
	turret_pivot.look_at(get_global_mouse_position())
	if has_input != _engine_moving:
		_engine_moving = has_input
		AudioManager.play_engine(_engine_moving)
	if Input.is_action_pressed("shoot") and _fire_cooldown_left <= 0.0:
		_fire()

func _fire() -> void:
	_fire_cooldown_left = FIRE_COOLDOWN
	var aim: Vector2 = Vector2.RIGHT.rotated(turret_pivot.global_rotation)
	_recoil_velocity -= aim * RECOIL_FORCE * 5.0
	VFXManager.spawn_muzzle_flash(muzzle_marker.global_position, aim.angle())
	AudioManager.play_cannon()
	EventBus.camera_shake_requested.emit(2.0, 0.1)
	_play_recoil_tween()
	_spawn_bullet(aim)

func _play_recoil_tween() -> void:
	if _recoil_tween != null and _recoil_tween.is_valid():
		_recoil_tween.kill()
	_recoil_tween = create_tween()
	_recoil_tween.tween_property(turret_visual, "position:x", _turret_base_x - 6.0, 0.05)
	_recoil_tween.tween_property(turret_visual, "position:x", _turret_base_x, 0.12)

func _spawn_bullet(aim: Vector2) -> void:
	if not ResourceLoader.exists(BULLET_SCENE):
		return
	var packed: PackedScene = load(BULLET_SCENE) as PackedScene
	if packed == null:
		return
	var bullet: Node2D = packed.instantiate() as Node2D
	if bullet == null:
		return
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if bullet.get("direction") != null:
		bullet.set("direction", aim)
	parent.add_child(bullet)
	bullet.global_position = muzzle_marker.global_position
	bullet.rotation = aim.angle()

func take_damage(amount: int, _is_ricochet: bool = false) -> void:
	if not _alive or is_invulnerable:
		return
	hp = maxi(0, hp - amount)
	EventBus.player_damaged.emit(hp, MAX_HP)
	EventBus.camera_shake_requested.emit(12.0, 0.35)
	GameManager.trigger_hit_stop(0.05)
	_flash_white()
	if hp <= 0:
		_die()
	else:
		_start_iframes()

func _flash_white() -> void:
	hull_visual.modulate = Color(10.0, 10.0, 10.0, 1.0)
	turret_visual.modulate = Color(10.0, 10.0, 10.0, 1.0)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(hull_visual, "modulate", Color.WHITE, HIT_FLASH_DURATION)
	tween.tween_property(turret_visual, "modulate", Color.WHITE, HIT_FLASH_DURATION)

func _start_iframes() -> void:
	is_invulnerable = true
	if _iframe_tween != null and _iframe_tween.is_valid():
		_iframe_tween.kill()
	_iframe_tween = create_tween()
	var cycles: int = maxi(1, int(round(IFRAME_DURATION / 0.2)))
	for i: int in cycles:
		_iframe_tween.tween_property(self, "modulate:a", 0.25, 0.1)
		_iframe_tween.tween_property(self, "modulate:a", 1.0, 0.1)
	_iframe_tween.tween_callback(_on_iframes_finished)

func _on_iframes_finished() -> void:
	modulate.a = 1.0
	is_invulnerable = false

func _die() -> void:
	_alive = false
	is_invulnerable = true
	if _iframe_tween != null and _iframe_tween.is_valid():
		_iframe_tween.kill()
	modulate.a = 1.0
	EventBus.player_died.emit()
	VFXManager.spawn_tank_explosion(global_position)
	hull_visual.visible = false
	turret_pivot.visible = false
	collision_shape.set_deferred("disabled", true)
	tread_timer.stop()

func _track_point(side: float) -> Vector2:
	return hull_visual.global_transform * Vector2(-4.0, side)

func _on_tread_timer_timeout() -> void:
	if not _alive or not _had_track_anchor:
		return
	var left: Vector2 = _track_point(-13.0)
	var right: Vector2 = _track_point(13.0)
	_spawn_tread_mark(_last_left_track, left)
	_spawn_tread_mark(_last_right_track, right)
	_last_left_track = left
	_last_right_track = right

func _spawn_tread_mark(from: Vector2, to: Vector2) -> void:
	if not ResourceLoader.exists(TREAD_MARK_SCENE):
		return
	var packed: PackedScene = load(TREAD_MARK_SCENE) as PackedScene
	if packed == null:
		return
	var mark: Line2D = packed.instantiate() as Line2D
	if mark == null:
		return
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(mark)
	mark.points = PackedVector2Array([from, to])
	var tween: Tween = mark.create_tween()
	tween.tween_property(mark, "modulate:a", 0.0, TREAD_FADE)
	tween.tween_callback(mark.queue_free)
