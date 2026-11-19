class_name EnemyArtillery
extends BaseEnemy

const FIRE_INTERVAL: float = 2.5
const BULLET_SPEED: float = 400.0
const STOP_DISTANCE: float = 350.0
const BULLET_SCENE: String = "res://scenes/projectiles/enemy_bullet.tscn"

@onready var fire_timer: Timer = $FireTimer
@onready var muzzle_marker: Marker2D = $MuzzleMarker

func _ready() -> void:
	max_hp = 1
	move_speed = 110.0
	base_score = 200
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
		var dist: float = global_position.distance_to(player.global_position)
		var dir: Vector2 = (player.global_position - global_position).normalized()
		rotation = dir.angle()
		if dist > STOP_DISTANCE:
			velocity = dir * move_speed * speed_multiplier
			move_and_slide()
		else:
			velocity = Vector2.ZERO

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
