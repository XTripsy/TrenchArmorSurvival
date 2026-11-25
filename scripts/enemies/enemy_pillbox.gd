class_name EnemyPillbox
extends BaseEnemy

const FIRE_INTERVAL: float = 2.2
const BULLET_SPEED: float = 400.0
const BULLET_SCENE: String = "res://scenes/projectiles/enemy_bullet.tscn"

@onready var fire_timer: Timer = $FireTimer
@onready var muzzle_marker: Marker2D = $MuzzleMarker

func _ready() -> void:
	max_hp = 3
	move_speed = 0.0
	base_score = 300
	super._ready()
	if fire_timer != null:
		fire_timer.wait_time = FIRE_INTERVAL
		fire_timer.timeout.connect(_on_fire_timer_timeout)
		fire_timer.start()

func _physics_process(_delta: float) -> void:
	if not _alive:
		return
	velocity = Vector2.ZERO
	var player: Node2D = get_player()
	if player != null:
		rotation = (player.global_position - global_position).angle()

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
	var origin: Vector2 = muzzle_marker.global_position if muzzle_marker != null else global_position
	var direction: Vector2 = (player.global_position - origin).normalized()
	if bullet.get("direction") != null:
		bullet.set("direction", direction)
	if bullet.get("speed") != null:
		bullet.set("speed", BULLET_SPEED)
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(bullet)
	bullet.global_position = origin
	bullet.rotation = direction.angle()
