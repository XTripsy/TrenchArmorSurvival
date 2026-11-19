class_name EnemyBullet
extends CharacterBody2D

const DEFAULT_SPEED: float = 400.0
const OFFSCREEN_MARGIN: float = 256.0

var direction: Vector2 = Vector2.RIGHT
var speed: float = DEFAULT_SPEED

@onready var visual: Polygon2D = $Visual

func _ready() -> void:
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	velocity = direction.normalized() * speed
	rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision != null:
		_handle_collision(collision)
	if is_queued_for_deletion():
		return
	
	var visible_rect: Rect2 = get_viewport().get_visible_rect()
	var world_rect: Rect2 = get_canvas_transform().affine_inverse() * visible_rect
	if not world_rect.grow(OFFSCREEN_MARGIN).has_point(global_position):
		queue_free()

func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider: Object = collision.get_collider()
	if collider == null:
		queue_free()
		return
	if collider.has_method("take_damage"):
		collider.call("take_damage", 1, false)
	queue_free()
