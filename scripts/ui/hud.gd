extends CanvasLayer

const MAX_SHIELDS: int = 3
const SHIELD_BROKEN_COLOR: Color = Color(0.164706, 0.164706, 0.164706, 1)

@onready var score_label: Label = $HUDRoot/ScoreLabel
@onready var time_label: Label = $HUDRoot/TimeLabel
@onready var shields: Node2D = $HUDRoot/Shields
@onready var reticle: Node2D = $HUDRoot/Reticle

func _ready() -> void:
	EventBus.score_updated.connect(_on_score_updated)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.game_state_changed.connect(_on_game_state_changed)
	_refresh_score(GameManager.score)
	_refresh_shields(MAX_SHIELDS)
	_refresh_time()

func _process(_delta: float) -> void:
	_refresh_time()
	reticle.position = get_viewport().get_mouse_position()
	reticle.visible = GameManager.state == GameManager.State.PLAYING

func _on_score_updated(new_score: int, _ricochet_kills: int) -> void:
	_refresh_score(new_score)

func _on_player_damaged(current_hp: int, _max_hp: int) -> void:
	_refresh_shields(current_hp)

func _on_game_state_changed(_new_state: int) -> void:
	reticle.visible = GameManager.state == GameManager.State.PLAYING

func _refresh_score(value: int) -> void:
	score_label.text = "SCORE: %06d" % value

func _refresh_time() -> void:
	var total: int = maxi(0, floori(GameManager.time_survived))
	time_label.text = "TIME: %02d:%02d" % [total / 60, total % 60]

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
