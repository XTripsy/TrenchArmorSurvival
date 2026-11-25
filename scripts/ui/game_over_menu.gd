extends CanvasLayer

@onready var overlay: Control = $Overlay
@onready var header_label: Label = $Overlay/HeaderLabel
@onready var stats_label: Label = $Overlay/StatsLabel
@onready var redeploy_button: Button = $Overlay/RedeployButton
@onready var menu_button: Button = $Overlay/MenuButton
var _lockout_timer: float = 0.0
var _reveal_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	EventBus.game_state_changed.connect(_on_game_state_changed)
	UIThemeBuilder.setup_tactical_button(redeploy_button)
	UIThemeBuilder.setup_tactical_button(menu_button)
	redeploy_button.pressed.connect(_on_redeploy_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	header_label.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_DISPLAY, UIThemeBuilder.UI_TEXT_DANGER, 2)
	if GameManager.state == GameManager.State.GAME_OVER:
		_show_stats()

func _process(delta: float) -> void:
	if _reveal_timer > 0.0:
		_reveal_timer -= delta
		if _reveal_timer <= 0.0:
			_reveal_timer = 0.0
			_show_debrief()
	if _lockout_timer > 0.0:
		_lockout_timer -= delta
		if _lockout_timer <= 0.0:
			redeploy_button.disabled = false

func _on_game_state_changed(new_state: int) -> void:
	if new_state == int(GameManager.State.GAME_OVER):
		_show_stats()
	else:
		overlay.visible = false

func _show_stats() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	overlay.visible = false
	redeploy_button.disabled = true
	_reveal_timer = 0.6

func _show_debrief() -> void:
	var total: int = maxi(0, floori(GameManager.time_survived))
	header_label.text = "ARMOR DESTROYED"
	stats_label.text = "FINAL SCORE: %06d\nTIME SURVIVED: %02d:%02d\nRICOCHET KILLS: %d" % [
		GameManager.score,
		total / 60,
		total % 60,
		GameManager.ricochet_kills,
	]
	overlay.visible = true
	_lockout_timer = 0.8
	redeploy_button.disabled = true

func _unhandled_input(event: InputEvent) -> void:
	if overlay.visible and event.is_action_pressed("ui_accept"):
		if _lockout_timer <= 0.0:
			_on_redeploy_pressed()
		get_viewport().set_input_as_handled()

func _on_redeploy_pressed() -> void:
	if _lockout_timer > 0.0:
		return
	var arena: Node = get_parent()
	if arena != null and arena.has_method("restart_run"):
		arena.call("restart_run")

func _on_menu_pressed() -> void:
	var arena: Node = get_parent()
	if arena != null and arena.has_method("return_to_menu"):
		arena.call("return_to_menu")
