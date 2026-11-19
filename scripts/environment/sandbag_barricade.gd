class_name SandbagBarricade
extends StaticBody2D

const MAX_HP: int = 3

var hp: int = MAX_HP
var _alive: bool = true

@onready var visual: Node2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var crack_visual: Line2D = $Visual/Crack

func _ready() -> void:
	add_to_group("destructible_cover")
	collision_layer = 4
	collision_mask = 0
	hp = MAX_HP
	if crack_visual != null:
		crack_visual.visible = false

func take_damage(amount: int, _is_ricochet: bool = false) -> void:
	if not _alive:
		return
	AudioManager.play_hit()
	hp = maxi(0, hp - amount)
	_flash_and_shrink()
	if crack_visual != null:
		crack_visual.visible = hp == 1
	if hp <= 0:
		_destroy()

func _flash_and_shrink() -> void:
	modulate = Color(8.0, 8.0, 8.0, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	if visual != null:
		visual.scale = Vector2.ONE * (1.0 - 0.08 * float(MAX_HP - hp))

func _destroy() -> void:
	_alive = false
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	_spawn_debris_particles()
	if visual != null:
		visual.visible = false
	get_tree().create_timer(0.4).timeout.connect(queue_free)

func _spawn_debris_particles() -> void:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.amount = 12
	particles.lifetime = 0.35
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 90.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 120.0
	particles.gravity = Vector2(0.0, 300.0)
	particles.color = Color("#8B6F47")
	particles.emitting = true
	add_child(particles)
