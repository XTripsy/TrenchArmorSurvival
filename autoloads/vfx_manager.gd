extends Node

const FLOATING_TEXT_SCENE: String = "res://scenes/ui/floating_text.tscn"
const SMOKE_LIFETIME: float = 0.8
const SPARK_LIFETIME: float = 0.4
const FIRE_LIFETIME: float = 1.6
const SCORCH_LIFETIME: float = 4.0
const DEBRIS_LIFETIME: float = 4.0
const PARTICLE_TEXTURE_SIZE: int = 32

var _soft_texture: Texture2D = null
var _streak_texture: Texture2D = null

func _ready() -> void:
	_soft_texture = _make_soft_texture()
	_streak_texture = _make_streak_texture()
	EventBus.bullet_ricocheted.connect(_on_bullet_ricocheted)
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)

func spawn_muzzle_flash(pos: Vector2, rot: float) -> void:
	var flash: Polygon2D = Polygon2D.new()
	flash.polygon = PackedVector2Array([
		Vector2(0.0, -9.0), Vector2(26.0, 0.0), Vector2(0.0, 9.0), Vector2(7.0, 0.0),
	])
	flash.color = Color("#FFF2B2")
	flash.z_index = 20
	_effect_parent().add_child(flash)
	flash.global_position = pos
	flash.rotation = rot

	var tween: Tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.08)
	tween.tween_callback(flash.queue_free)

	_spawn_smoke(pos, rot)

func spawn_ricochet_sparks(pos: Vector2, normal: Vector2) -> void:
	if normal.is_zero_approx():
		normal = Vector2.UP
	var sparks: CPUParticles2D = CPUParticles2D.new()
	sparks.amount = 14
	sparks.lifetime = 0.25
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.direction = normal
	sparks.spread = 45.0
	sparks.initial_velocity_min = 120.0
	sparks.initial_velocity_max = 260.0
	sparks.gravity = Vector2.ZERO
	sparks.texture = _streak_texture
	sparks.particle_flag_align_y = true
	sparks.scale_amount_min = 0.5
	sparks.scale_amount_max = 1.0
	sparks.color = Color("#FFD700")
	sparks.color_ramp = _alpha_ramp(1.0)
	sparks.z_index = 15
	_effect_parent().add_child(sparks)
	sparks.global_position = pos
	sparks.emitting = true
	_free_after(sparks, SPARK_LIFETIME)

func spawn_tank_explosion(pos: Vector2) -> void:
	var parent: Node = _effect_parent()
	_spawn_scorch(parent, pos)
	_spawn_fire(parent, pos)
	_spawn_black_smoke(parent, pos)
	_spawn_debris(parent, pos)

func spawn_floating_text(pos: Vector2, text: String) -> void:
	var instance: Node2D = null
	var scene_handles_setup: bool = false
	if ResourceLoader.exists(FLOATING_TEXT_SCENE):
		var packed: PackedScene = load(FLOATING_TEXT_SCENE) as PackedScene
		if packed != null:
			var candidate: Node = packed.instantiate()
			instance = candidate as Node2D
			if instance != null and instance.has_method("setup"):
				scene_handles_setup = true
			else:
				if candidate != null:
					candidate.free()
				instance = null

	var procedural: bool = instance == null
	if procedural:
		instance = _build_floating_text(text)

	instance.z_index = 30
	_effect_parent().add_child(instance)
	instance.global_position = pos

	if scene_handles_setup:
		# T-030's setup() owns the float/fade tween, so it must run once the node is
		# inside the tree; a tween created outside the tree has no SceneTree to
		# advance it.
		instance.call("setup", text)
	else:
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(instance, "global_position", pos + Vector2(0.0, -30.0), 0.8)
		tween.tween_property(instance, "modulate:a", 0.0, 0.8)
		tween.chain().tween_callback(instance.queue_free)

func _effect_parent() -> Node:
	var scene: Node = get_tree().current_scene
	if scene != null and is_instance_valid(scene):
		return scene
	return self

func _build_floating_text(text: String) -> Node2D:
	var root: Node2D = Node2D.new()
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#FFD700"))
	label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(-60.0, -14.0)
	label.size = Vector2(120.0, 28.0)
	root.add_child(label)
	return root

func _spawn_smoke(pos: Vector2, rot: float) -> void:
	var smoke: CPUParticles2D = CPUParticles2D.new()
	smoke.amount = 8
	smoke.lifetime = 0.5
	smoke.one_shot = true
	smoke.explosiveness = 0.8
	smoke.direction = Vector2.RIGHT
	smoke.spread = 35.0
	smoke.initial_velocity_min = 20.0
	smoke.initial_velocity_max = 70.0
	smoke.gravity = Vector2.ZERO
	smoke.texture = _soft_texture
	smoke.scale_amount_min = 0.6
	smoke.scale_amount_max = 1.6
	smoke.color = Color(0.6, 0.6, 0.6, 0.5)
	smoke.color_ramp = _alpha_ramp(1.0)
	_effect_parent().add_child(smoke)
	smoke.global_position = pos
	smoke.rotation = rot
	smoke.emitting = true
	_free_after(smoke, SMOKE_LIFETIME)

func _spawn_fire(parent: Node, pos: Vector2) -> void:
	var fire: CPUParticles2D = CPUParticles2D.new()
	fire.amount = 24
	fire.lifetime = 0.6
	fire.one_shot = true
	fire.explosiveness = 1.0
	fire.direction = Vector2.UP
	fire.spread = 180.0
	fire.initial_velocity_min = 40.0
	fire.initial_velocity_max = 160.0
	fire.gravity = Vector2.ZERO
	fire.texture = _soft_texture
	fire.scale_amount_min = 1.0
	fire.scale_amount_max = 2.5
	fire.color = Color("#FF5500")
	fire.color_ramp = _alpha_ramp(1.0)
	fire.z_index = 10
	parent.add_child(fire)
	fire.global_position = pos
	fire.emitting = true
	_free_after(fire, FIRE_LIFETIME)

func _spawn_black_smoke(parent: Node, pos: Vector2) -> void:
	var smoke: CPUParticles2D = CPUParticles2D.new()
	smoke.amount = 16
	smoke.lifetime = 1.2
	smoke.one_shot = true
	smoke.explosiveness = 1.0
	smoke.direction = Vector2.UP
	smoke.spread = 90.0
	smoke.initial_velocity_min = 30.0
	smoke.initial_velocity_max = 100.0
	smoke.gravity = Vector2.ZERO
	smoke.texture = _soft_texture
	smoke.scale_amount_min = 1.8
	smoke.scale_amount_max = 4.5
	smoke.color = Color(0.05, 0.05, 0.05, 0.6)
	smoke.color_ramp = _alpha_ramp(1.0)
	smoke.z_index = 9
	parent.add_child(smoke)
	smoke.global_position = pos
	smoke.emitting = true
	_free_after(smoke, FIRE_LIFETIME)

func _spawn_scorch(parent: Node, pos: Vector2) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 10:
		var angle: float = TAU * float(i) / 10.0
		var radius: float = 18.0 + sin(float(i) * 2.3) * 6.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	var scorch: Polygon2D = Polygon2D.new()
	scorch.polygon = points
	scorch.color = Color(0.02, 0.02, 0.02, 0.55)
	scorch.z_index = -1
	parent.add_child(scorch)
	scorch.global_position = pos

	var tween: Tween = create_tween()
	tween.tween_interval(SCORCH_LIFETIME)
	tween.tween_property(scorch, "modulate:a", 0.0, 0.8)
	tween.tween_callback(scorch.queue_free)

func _spawn_debris(parent: Node, pos: Vector2) -> void:
	var count: int = randi_range(3, 5)
	for i: int in count:
		var fragment: Polygon2D = Polygon2D.new()
		fragment.polygon = PackedVector2Array([
			Vector2(-4.0, -3.0), Vector2(4.0, -2.0), Vector2(3.0, 3.0), Vector2(-3.0, 2.0),
		])
		fragment.color = Color("#36393F")
		fragment.z_index = 5
		parent.add_child(fragment)
		fragment.global_position = pos
		fragment.rotation = randf_range(0.0, TAU)

		var target: Vector2 = pos + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(20.0, 70.0)
		var tween: Tween = create_tween()
		tween.tween_property(fragment, "global_position", target, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(fragment, "rotation", fragment.rotation + randf_range(-6.0, 6.0), 0.4)
		tween.tween_interval(DEBRIS_LIFETIME)
		tween.tween_property(fragment, "modulate:a", 0.0, 0.5)
		tween.tween_callback(fragment.queue_free)

func _free_after(node: Node, seconds: float) -> void:
	var timer: Timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = seconds
	timer.timeout.connect(node.queue_free)
	node.add_child(timer)
	timer.start()

func _alpha_ramp(peak_alpha: float) -> Gradient:
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color(1.0, 1.0, 1.0, peak_alpha))
	ramp.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	ramp.add_point(0.65, Color(1.0, 1.0, 1.0, peak_alpha))
	return ramp

func _make_soft_texture() -> Texture2D:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	gradient.add_point(0.35, Color(1.0, 1.0, 1.0, 0.75))

	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = PARTICLE_TEXTURE_SIZE
	texture.height = PARTICLE_TEXTURE_SIZE
	return texture

func _make_streak_texture() -> Texture2D:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 0.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	gradient.add_point(0.5, Color(1.0, 1.0, 1.0, 1.0))

	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	texture.width = PARTICLE_TEXTURE_SIZE / 4
	texture.height = PARTICLE_TEXTURE_SIZE
	return texture

func _on_bullet_ricocheted(impact_position: Vector2, impact_normal: Vector2) -> void:
	spawn_ricochet_sparks(impact_position, impact_normal)

func _on_enemy_destroyed(enemy_position: Vector2, _base_score: int, _was_ricochet: bool) -> void:
	spawn_tank_explosion(enemy_position)
	EventBus.camera_shake_requested.emit(5.0, 0.2)
