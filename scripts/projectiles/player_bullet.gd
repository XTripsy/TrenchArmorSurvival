class_name PlayerBullet
extends CharacterBody2D

const SPEED: float = 650.0
const MAX_BOUNCES: int = 1
const OFFSCREEN_MARGIN: float = 256.0
const RICOCHET_COLOR: Color = Color("#FF5500")

var direction: Vector2 = Vector2.RIGHT
var bounce_count: int = 0
var is_ricochet: bool = false

@onready var visual: Polygon2D = $Visual

func _ready() -> void:
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	velocity = direction.normalized() * SPEED
	rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision != null:
		_handle_collision(collision)
	if is_queued_for_deletion():
		return
	
	# Cleanup off-screen (world space aware)
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
		collider.call("take_damage", 1, is_ricochet)
		queue_free()
		return
	if collider is Node and (collider as Node).is_in_group("bouncy_surface"):
		if bounce_count < MAX_BOUNCES:
			_bounce(collision)
		else:
			VFXManager.spawn_ricochet_sparks(collision.get_position(), collision.get_normal())
			queue_free()
		return
	queue_free()

func _bounce(collision: KinematicCollision2D) -> void:
	bounce_count += 1
	is_ricochet = true
	velocity = velocity.bounce(collision.get_normal())
	rotation = velocity.angle()
	visual.color = RICOCHET_COLOR
	EventBus.bullet_ricocheted.emit(collision.get_position(), collision.get_normal())
	AudioManager.play_ricochet()
