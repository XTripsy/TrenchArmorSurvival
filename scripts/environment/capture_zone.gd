class_name CaptureZone
extends Area2D

const RADIUS: float = 180.0
const CAPTURE_RATE: float = 0.15
const RING_WIDTH: float = 4.0
const INNER_RING_OFFSET: float = 10.0
const STATE_NEUTRAL: String = "NEUTRAL"
const STATE_CAPTURING: String = "CAPTURING"
const STATE_CONTESTED: String = "CONTESTED"
const STATE_CAPTURED: String = "CAPTURED"
const NEUTRAL_COLOR: Color = Color("#D9A738")
const CAPTURING_COLOR: Color = Color("#E5C158")
const CONTESTED_COLOR: Color = Color("#FF4444")
const CAPTURED_COLOR: Color = Color("#6B8E23")

enum ZoneState { NEUTRAL, CAPTURING, CONTESTED, CAPTURED }

@export var zone_id: int = 0

var progress: float = 0.0
var captured: bool = false
var state: ZoneState = ZoneState.NEUTRAL

var _player_inside: bool = false
var _enemy_count: int = 0
var _last_reported_progress: float = -1.0

func _ready() -> void:
	collision_layer = 32
	collision_mask = 3
	z_index = -1
	add_to_group("capture_zone")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_emit_update()

func is_captured() -> bool:
	return captured

func _process(delta: float) -> void:
	_update_capture(delta)
	queue_redraw()

func _update_capture(delta: float) -> void:
	if captured:
		return
	var previous_state: ZoneState = state
	if _player_inside and _enemy_count == 0:
		progress = minf(1.0, progress + CAPTURE_RATE * delta)
		state = ZoneState.CAPTURING
		if progress >= 1.0:
			_complete_capture()
			return
	elif _enemy_count > 0 and progress < 1.0:
		state = ZoneState.CONTESTED
	else:
		state = ZoneState.NEUTRAL
	if state != previous_state or absf(progress - _last_reported_progress) >= 0.01:
		_emit_update()

func _complete_capture() -> void:
	captured = true
	state = ZoneState.CAPTURED
	progress = 1.0
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player != null and player.has_method("heal"):
		player.call("heal", 1)
	VFXManager.spawn_floating_text(global_position, "+500 ZONE CAPTURED!")
	AudioManager.play_explosion()
	EventBus.camera_shake_requested.emit(6.0, 0.25)
	_emit_update()
	GameManager.register_zone_captured(zone_id)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
	elif body.is_in_group("enemy"):
		_enemy_count += 1

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
	elif body.is_in_group("enemy"):
		_enemy_count = maxi(0, _enemy_count - 1)

func _emit_update() -> void:
	_last_reported_progress = progress
	EventBus.capture_zone_updated.emit(zone_id, progress, state_name())

func state_name() -> String:
	match state:
		ZoneState.CAPTURING:
			return STATE_CAPTURING
		ZoneState.CONTESTED:
			return STATE_CONTESTED
		ZoneState.CAPTURED:
			return STATE_CAPTURED
		_:
			return STATE_NEUTRAL

func _state_color() -> Color:
	match state:
		ZoneState.CAPTURING:
			return CAPTURING_COLOR
		ZoneState.CONTESTED:
			return CONTESTED_COLOR
		ZoneState.CAPTURED:
			return CAPTURED_COLOR
		_:
			return NEUTRAL_COLOR

func _draw() -> void:
	var color: Color = _state_color()
	var inner_radius: float = RADIUS - INNER_RING_OFFSET
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 96, color, RING_WIDTH, true)
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 96, Color(color.r, color.g, color.b, 0.35), 2.0, true)
	if progress > 0.0:
		var steps: int = maxi(4, int(96.0 * progress))
		var fill_points: PackedVector2Array = PackedVector2Array()
		fill_points.append(Vector2.ZERO)
		for i: int in range(steps + 1):
			var angle: float = -PI * 0.5 + TAU * progress * float(i) / float(steps)
			fill_points.append(Vector2(cos(angle), sin(angle)) * inner_radius)
		draw_colored_polygon(fill_points, Color(color.r, color.g, color.b, 0.18))
		draw_arc(Vector2.ZERO, inner_radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 96, color, 6.0, true)
	for i: int in 4:
		var marker_angle: float = TAU * float(i) / 4.0
		var marker_position: Vector2 = Vector2(cos(marker_angle), sin(marker_angle)) * RADIUS
		draw_circle(marker_position, 4.0, color)
