class_name EnemyScout
extends BaseEnemy

func _ready() -> void:
	max_hp = 1
	move_speed = 250.0
	base_score = 100
	super._ready()

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	var player: Node2D = get_player()
	if player != null:
		var dir: Vector2 = (player.global_position - global_position).normalized()
		velocity = dir * move_speed * speed_multiplier
		rotation = dir.angle()
		move_and_slide()
		_check_player_collision()

func _check_player_collision() -> void:
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider != null and (collider.is_in_group("player") or collider.name == "Player"):
			if collider.has_method("take_damage"):
				collider.call("take_damage", 1, false)
			die(false)
			return
