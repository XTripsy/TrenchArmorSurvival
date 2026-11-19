extends CanvasLayer

@onready var overlay: Control = $Overlay
@onready var header_label: Label = $Overlay/HeaderLabel
@onready var stats_label: Label = $Overlay/StatsLabel
@onready var redeploy_button: Button = $Overlay/RedeployButton
@onready var menu_button: Button = $Overlay/MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	EventBus.game_state_changed.connect(_on_game_state_changed)
	redeploy_button.pressed.connect(_on_redeploy_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	if GameManager.state == GameManager.State.GAME_OVER:
		_show_stats()

func _on_game_state_changed(new_state: int) -> void:
	if new_state == int(GameManager.State.GAME_OVER):
		_show_stats()
	else:
		overlay.visible = false

func _show_stats() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var total: int = maxi(0, floori(GameManager.time_survived))
	header_label.text = "TANK DESTROYED"
	stats_label.text = "FINAL SCORE: %06d\nTIME SURVIVED: %02d:%02d\nRICOCHET KILLS: %d" % [
		GameManager.score,
		total / 60,
		total % 60,
		GameManager.ricochet_kills,
	]
	overlay.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if overlay.visible and event.is_action_pressed("ui_accept"):
		_on_redeploy_pressed()
		get_viewport().set_input_as_handled()

func _on_redeploy_pressed() -> void:
	var arena: Node = get_parent()
	if arena != null and arena.has_method("restart_run"):
		arena.call("restart_run")

func _on_menu_pressed() -> void:
	var arena: Node = get_parent()
	if arena != null and arena.has_method("return_to_menu"):
		arena.call("return_to_menu")
