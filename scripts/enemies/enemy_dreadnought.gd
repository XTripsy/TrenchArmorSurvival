class_name EnemyDreadnought
extends BaseEnemy

const FIRE_INTERVAL: float = 3.5
const BULLET_SPEED: float = 350.0
const BULLET_SCENE: String = "res://scenes/projectiles/enemy_bullet.tscn"

@onready var fire_timer: Timer = $FireTimer
@onready var muzzle_marker: Marker2D = $MuzzleMarker

func _ready() -> void:
	max_hp = 2
	move_speed = 70.0
	base_score = 500
	super._ready()
	if fire_timer != null:
		fire_timer.wait_time = FIRE_INTERVAL
		fire_timer.timeout.connect(_on_fire_timer_timeout)
		fire_timer.start()

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	var player: Node2D = get_player()
	if player != null:
		var dir: Vector2 = (player.global_position - global_position).normalized()
		velocity = dir * move_speed * speed_multiplier
		rotation = dir.angle()
		move_and_slide()

func take_damage(amount: int, from_ricochet: bool = false) -> void:
	if from_ricochet:
		# Dreadnought instakilled by ricochet
		super.take_damage(max_hp, true)
	else:
		super.take_damage(amount, false)

func _on_fire_timer_timeout() -> void:
	if not _alive:
		return
	var player: Node2D = get_player()
	if player == null:
		return
	_fire(player)

func _fire(player: Node2D) -> void:
	AudioManager.play_enemy_cannon()
	if not ResourceLoader.exists(BULLET_SCENE):
		return
	var packed: PackedScene = load(BULLET_SCENE) as PackedScene
	if packed == null:
		return
	var bullet: Node2D = packed.instantiate() as Node2D
	if bullet == null:
		return
	var dir: Vector2 = (player.global_position - global_position).normalized()
	if bullet.get("direction") != null:
		bullet.set("direction", dir)
	if bullet.get("speed") != null:
		bullet.set("speed", BULLET_SPEED)
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(bullet)
	bullet.global_position = muzzle_marker.global_position if muzzle_marker != null else global_position
	bullet.rotation = dir.angle()
