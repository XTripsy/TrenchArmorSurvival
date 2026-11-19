extends CanvasLayer

@onready var overlay: Control = $Overlay
@onready var resume_button: Button = $Overlay/ResumeButton
@onready var restart_button: Button = $Overlay/RestartButton
@onready var menu_button: Button = $Overlay/MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if GameManager.state == GameManager.State.PLAYING:
		_pause()
		get_viewport().set_input_as_handled()
	elif GameManager.state == GameManager.State.PAUSED:
		_resume()
		get_viewport().set_input_as_handled()

func _pause() -> void:
	overlay.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.change_state(GameManager.State.PAUSED)

func _resume() -> void:
	overlay.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	GameManager.change_state(GameManager.State.PLAYING)

func _on_resume_pressed() -> void:
	_resume()

func _on_restart_pressed() -> void:
	var arena: Node = get_parent()
	if arena != null and arena.has_method("restart_run"):
		arena.call("restart_run")

func _on_menu_pressed() -> void:
	var arena: Node = get_parent()
	if arena != null and arena.has_method("return_to_menu"):
		arena.call("return_to_menu")
