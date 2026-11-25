class_name CameraShake
extends Camera2D

const MAX_OFFSET: float = 32.0
const INNER_BOUNDS: Rect2 = Rect2(0.0, 0.0, 1280.0, 720.0)
const INNER_CENTER: Vector2 = Vector2(640.0, 360.0)
const FOLLOW_SPEED: float = 5.0

var _intensity: float = 0.0
var _duration: float = 0.0
var _elapsed: float = 0.0
var _active: bool = false
var _following: bool = false

func _ready() -> void:
	offset = Vector2.ZERO
	position = INNER_CENTER
	_apply_bounds(INNER_BOUNDS)
	EventBus.camera_shake_requested.connect(_on_camera_shake_requested)
	EventBus.map_expanded.connect(_on_map_expanded)

func _on_camera_shake_requested(intensity: float, duration: float) -> void:
	if intensity < _intensity or duration <= 0.0:
		return
	_intensity = minf(intensity, MAX_OFFSET)
	_duration = duration
	_elapsed = 0.0
	_active = true

func _on_map_expanded(new_bounds: Rect2) -> void:
	_apply_bounds(new_bounds)
	_following = true

func _apply_bounds(bounds: Rect2) -> void:
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.end.x)
	limit_bottom = int(bounds.end.y)

func _process(delta: float) -> void:
	_update_follow(delta)
	if not _active:
		return
	_elapsed += delta
	if _elapsed >= _duration:
		offset = Vector2.ZERO
		_intensity = 0.0
		_duration = 0.0
		_elapsed = 0.0
		_active = false
		return
	var falloff: float = 1.0 - (_elapsed / _duration)
	var direction: Vector2 = Vector2.from_angle(randf() * TAU)
	offset = direction * _intensity * falloff

func _update_follow(delta: float) -> void:
	if not _following:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var weight: float = clampf(FOLLOW_SPEED * delta, 0.0, 1.0)
	global_position = global_position.lerp(player.global_position, weight)
