class_name CameraShake
extends Camera2D

const MAX_OFFSET: float = 32.0

var _intensity: float = 0.0
var _duration: float = 0.0
var _elapsed: float = 0.0
var _active: bool = false

func _ready() -> void:
	offset = Vector2.ZERO
	EventBus.camera_shake_requested.connect(_on_camera_shake_requested)

func _on_camera_shake_requested(intensity: float, duration: float) -> void:
	if intensity < _intensity or duration <= 0.0:
		return
	_intensity = minf(intensity, MAX_OFFSET)
	_duration = duration
	_elapsed = 0.0
	_active = true

func _process(delta: float) -> void:
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
