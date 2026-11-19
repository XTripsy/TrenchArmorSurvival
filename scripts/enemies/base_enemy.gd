class_name BaseEnemy
extends CharacterBody2D

@export var max_hp: int = 1
@export var move_speed: float = 150.0
@export var base_score: int = 100

var hp: int = 1
var speed_multiplier: float = 1.0
var _alive: bool = true

func _ready() -> void:
	hp = max_hp
	# Initialize collision mode
	motion_mode = MOTION_MODE_FLOATING

func take_damage(amount: int, from_ricochet: bool = false) -> void:
	if not _alive:
		return
	AudioManager.play_hit()
	hp = maxi(0, hp - amount)
	_flash_white()
	if hp <= 0:
		die(from_ricochet)

func die(from_ricochet: bool = false) -> void:
	if not _alive:
		return
	_alive = false
	EventBus.enemy_destroyed.emit(global_position, base_score, from_ricochet)
	queue_free()

func get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _flash_white() -> void:
	modulate = Color(10.0, 10.0, 10.0, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
