extends CanvasLayer

@onready var overlay: Control = $Overlay
@onready var title_label: Label = $Overlay/TitleLabel
@onready var audio_button: Button = $Overlay/AudioButton
@onready var resume_button: Button = $Overlay/ResumeButton
@onready var restart_button: Button = $Overlay/RestartButton
@onready var menu_button: Button = $Overlay/MenuButton
var _abort_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	
	title_label.text = "TACTICAL PAUSE"
	title_label.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_DISPLAY, UIThemeBuilder.UI_TEXT_PRIMARY)
	var frame: TacticalFrame = TacticalFrame.new()
	frame.show_hazard_stripes = true
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(frame)
	UIThemeBuilder.setup_tactical_button(audio_button)
	UIThemeBuilder.setup_tactical_button(resume_button)
	_audio_button_refresh()
	audio_button.pressed.connect(_on_audio_pressed)
	UIThemeBuilder.setup_tactical_button(restart_button)
	UIThemeBuilder.setup_tactical_button(menu_button)
	
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _process(delta: float) -> void:
	if _abort_timer > 0.0:
		_abort_timer -= delta
		if _abort_timer <= 0.0:
			menu_button.text = "ABORT TO MENU"
			menu_button.add_theme_stylebox_override("normal", UIThemeBuilder.panel_style(UIThemeBuilder.UI_SURFACE, UIThemeBuilder.UI_BORDER_STEEL))
			_abort_timer = 0.0

func _on_menu_pressed() -> void:
	if _abort_timer > 0.0:
		GameManager.change_state(GameManager.State.MENU)
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		_abort_timer = 3.0
		menu_button.text = "CONFIRM ABORT?"
		menu_button.add_theme_stylebox_override("normal", UIThemeBuilder.panel_style(UIThemeBuilder.UI_SURFACE, UIThemeBuilder.SEMANTIC_DANGER))

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

func _on_audio_pressed() -> void:
	AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))
	_audio_button_refresh()

func _audio_button_refresh() -> void:
	var muted: bool = AudioServer.is_bus_mute(0)
	audio_button.text = "AUDIO: OFF" if muted else "AUDIO: ON"

func _on_resume_pressed() -> void:
	_resume()

func _on_restart_pressed() -> void:
	var arena: Node = get_parent()
	if arena != null and arena.has_method("restart_run"):
		arena.call("restart_run")

