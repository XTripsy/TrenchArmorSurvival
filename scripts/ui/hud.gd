extends CanvasLayer

const MAX_SHIELDS: int = 3
const SHIELD_BROKEN_COLOR: Color = Color(0.164706, 0.164706, 0.164706, 1)
const INNER_BOUNDS: Rect2 = Rect2(0.0, 0.0, 1280.0, 720.0)
const BOSS_BAR_WIDTH: float = 400.0
const SCREEN_EDGE_MARGIN: float = 52.0
const ARROW_LENGTH: float = 22.0
const ARROW_HALF_WIDTH: float = 8.0
const MINIMAP_SIZE: Vector2 = Vector2(220.0, 124.0)
const MINIMAP_MARGIN: float = 18.0
const MINIMAP_PADDING: float = 6.0
const MINIMAP_ENEMY_LIMIT: int = 80
const ZONE_NEUTRAL_COLOR: Color = Color("#D9A738")
const ZONE_CAPTURING_COLOR: Color = Color("#E5C158")
const ZONE_CONTESTED_COLOR: Color = Color("#FF4444")
const ZONE_CAPTURED_COLOR: Color = Color("#6B8E23")
const BOSS_COLOR: Color = Color("#FF4444")
const ENEMY_BLIP_COLOR: Color = Color("#FF2222")
const PLAYER_BLIP_COLOR: Color = Color("#9ACD32")

var _active_bounds: Rect2 = INNER_BOUNDS
var _boss_hp: int = 0
var _boss_max_hp: int = 0
var _tactical: TacticalOverlay = null

@onready var score_label: Label = $HUDRoot/ScoreLabel
@onready var time_label: Label = $HUDRoot/TimeLabel
@onready var objective_label: Label = $HUDRoot/ObjectiveLabel
@onready var objective_bar: Node2D = $HUDRoot/ObjectiveBar
@onready var bar_fill: Line2D = $HUDRoot/ObjectiveBar/Fill
@onready var shields: Node2D = $HUDRoot/Shields
@onready var reticle: Node2D = $HUDRoot/Reticle


class TacticalOverlay:
	extends Control

	var hud: Node = null

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if hud != null:
			hud.call("draw_tactical", self)


func _ready() -> void:
	EventBus.score_updated.connect(_on_score_updated)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.game_state_changed.connect(_on_game_state_changed)
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_hp_changed.connect(_on_boss_hp_changed)
	EventBus.map_expanded.connect(_on_map_expanded)
	EventBus.sector_cleared.connect(_on_sector_cleared)
	_refresh_score(GameManager.score)
	_refresh_shields(MAX_SHIELDS)
	_refresh_time()
	_refresh_objective()
	_tactical = TacticalOverlay.new()
	_tactical.hud = self
	$HUDRoot.add_child(_tactical)

func _process(_delta: float) -> void:
	_refresh_time()
	_refresh_objective()
	reticle.position = get_viewport().get_mouse_position()
	reticle.visible = GameManager.state == GameManager.State.PLAYING

func _on_score_updated(new_score: int, _ricochet_kills: int) -> void:
	_refresh_score(new_score)

func _on_player_damaged(current_hp: int, _max_hp: int) -> void:
	_refresh_shields(current_hp)

func _on_game_state_changed(_new_state: int) -> void:
	reticle.visible = GameManager.state == GameManager.State.PLAYING

func _on_phase_changed(_new_phase: int) -> void:
	if GameManager.current_phase == GameManager.Phase.SKIRMISH:
		_boss_hp = 0
		_boss_max_hp = 0
	_refresh_objective()

func _on_boss_spawned(_boss_name: String, current_hp: int, max_hp: int) -> void:
	_boss_hp = current_hp
	_boss_max_hp = max_hp
	_refresh_objective()

func _on_boss_hp_changed(current_hp: int, max_hp: int) -> void:
	_boss_hp = current_hp
	_boss_max_hp = max_hp
	_refresh_objective()

func _on_map_expanded(new_bounds: Rect2) -> void:
	_active_bounds = new_bounds

func _on_sector_cleared(_sector_num: int, bonus_score: int) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		VFXManager.spawn_floating_text(player.global_position, "+%d SECTOR CLEARED!" % bonus_score)

func _refresh_score(value: int) -> void:
	score_label.text = "SCORE: %06d" % value

func _refresh_time() -> void:
	var total: int = maxi(0, floori(GameManager.time_survived))
	time_label.text = "TIME: %02d:%02d" % [total / 60, total % 60]

func _refresh_objective() -> void:
	match GameManager.current_phase:
		GameManager.Phase.BOSS:
			objective_label.text = "IRON GOLIATH HP"
			objective_bar.visible = true
			var ratio: float = 0.0
			if _boss_max_hp > 0:
				ratio = clampf(float(_boss_hp) / float(_boss_max_hp), 0.0, 1.0)
			bar_fill.points = PackedVector2Array([Vector2.ZERO, Vector2(BOSS_BAR_WIDTH * ratio, 0.0)])
		GameManager.Phase.INVASION:
			objective_label.text = "ZONES CAPTURED: %d/%d" % [GameManager.zones_captured, GameManager.zones_total]
			objective_bar.visible = false
		_:
			objective_label.text = "THREAT: %d%%" % int(round(GameManager.threat_progress))
			objective_bar.visible = false

func _refresh_shields(current_hp: int) -> void:
	for i: int in MAX_SHIELDS:
		var shield: Node2D = shields.get_node_or_null("Shield%d" % (i + 1)) as Node2D
		if shield == null:
			continue
		var broken: bool = i >= current_hp
		var plate: Polygon2D = shield.get_node_or_null("Plate") as Polygon2D
		var crack: Line2D = shield.get_node_or_null("Crack") as Line2D
		if plate != null:
			plate.modulate = SHIELD_BROKEN_COLOR if broken else Color.WHITE
		if crack != null:
			crack.visible = broken

func draw_tactical(canvas: CanvasItem) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	var viewport_size: Vector2 = canvas.get_viewport_rect().size
	_draw_off_screen_arrows(canvas, viewport_size)
	_draw_minimap(canvas, viewport_size)

func _draw_off_screen_arrows(canvas: CanvasItem, viewport_size: Vector2) -> void:
	var center: Vector2 = viewport_size * 0.5
	var safe_rect: Rect2 = Rect2(Vector2(SCREEN_EDGE_MARGIN, SCREEN_EDGE_MARGIN), viewport_size - Vector2(SCREEN_EDGE_MARGIN, SCREEN_EDGE_MARGIN) * 2.0)
	for node: Node in get_tree().get_nodes_in_group("capture_zone"):
		var zone: Node2D = node as Node2D
		if zone == null or bool(zone.get("captured")):
			continue
		var zone_state: int = int(zone.get("state"))
		_draw_direction_arrow(canvas, viewport_size, center, safe_rect, zone.global_position, _zone_color(zone_state))
	for node: Node in get_tree().get_nodes_in_group("boss"):
		var boss: Node2D = node as Node2D
		if boss != null:
			_draw_direction_arrow(canvas, viewport_size, center, safe_rect, boss.global_position, BOSS_COLOR)

func _draw_direction_arrow(canvas: CanvasItem, viewport_size: Vector2, center: Vector2, safe_rect: Rect2, world_position: Vector2, color: Color) -> void:
	var screen_position: Vector2 = canvas.get_viewport().get_canvas_transform() * world_position
	if safe_rect.has_point(screen_position):
		return
	var direction: Vector2 = (screen_position - center)
	if direction.is_zero_approx():
		return
	direction = direction.normalized()
	var half: Vector2 = viewport_size * 0.5 - Vector2(SCREEN_EDGE_MARGIN, SCREEN_EDGE_MARGIN)
	var scale_x: float = INF
	var scale_y: float = INF
	if absf(direction.x) > 0.001:
		scale_x = half.x / absf(direction.x)
	if absf(direction.y) > 0.001:
		scale_y = half.y / absf(direction.y)
	var distance: float = minf(scale_x, scale_y)
	var tip: Vector2 = center + direction * distance
	var base: Vector2 = tip - direction * ARROW_LENGTH
	var side: Vector2 = direction.orthogonal() * ARROW_HALF_WIDTH
	var points: PackedVector2Array = PackedVector2Array([tip, base + side, base - side])
	canvas.draw_colored_polygon(points, color)
	canvas.draw_line(base - direction * 10.0, base, color, 3.0, true)

func _draw_minimap(canvas: CanvasItem, viewport_size: Vector2) -> void:
	var rect: Rect2 = Rect2(Vector2(viewport_size.x - MINIMAP_SIZE.x - MINIMAP_MARGIN, MINIMAP_MARGIN), MINIMAP_SIZE)
	canvas.draw_rect(rect, Color(0.05, 0.05, 0.05, 0.7))
	canvas.draw_rect(rect, Color(0.85, 0.788235, 0.639216, 0.85), false, 2.0)
	var inner: Rect2 = rect.grow(-MINIMAP_PADDING)
	canvas.draw_rect(inner, Color(0.23, 0.18, 0.16, 0.65))
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		canvas.draw_circle(_to_minimap(player.global_position, inner), 4.0, PLAYER_BLIP_COLOR)
	for node: Node in get_tree().get_nodes_in_group("capture_zone"):
		var zone: Node2D = node as Node2D
		if zone == null:
			continue
		var point: Vector2 = _to_minimap(zone.global_position, inner)
		canvas.draw_circle(point, 6.0, _zone_color(int(zone.get("state"))))
		canvas.draw_arc(point, 8.0, 0.0, TAU, 16, Color(0.85, 0.788235, 0.639216, 0.9), 1.5, true)
	for node: Node in get_tree().get_nodes_in_group("boss"):
		var boss: Node2D = node as Node2D
		if boss != null:
			canvas.draw_circle(_to_minimap(boss.global_position, inner), 5.0, BOSS_COLOR)
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	var limit: int = mini(enemies.size(), MINIMAP_ENEMY_LIMIT)
	for i: int in limit:
		var enemy: Node2D = enemies[i] as Node2D
		if enemy != null:
			canvas.draw_circle(_to_minimap(enemy.global_position, inner), 2.0, ENEMY_BLIP_COLOR)

func _to_minimap(world_position: Vector2, inner: Rect2) -> Vector2:
	var normalized: Vector2 = (world_position - _active_bounds.position) / _active_bounds.size
	normalized = Vector2(clampf(normalized.x, 0.0, 1.0), clampf(normalized.y, 0.0, 1.0))
	return inner.position + normalized * inner.size

func _zone_color(zone_state: int) -> Color:
	match zone_state:
		1:
			return ZONE_CAPTURING_COLOR
		2:
			return ZONE_CONTESTED_COLOR
		3:
			return ZONE_CAPTURED_COLOR
		_:
			return ZONE_NEUTRAL_COLOR
