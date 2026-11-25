extends Control

const ARENA_SCENE: String = "res://scenes/arena.tscn"
const GRID_STEP: int = 128
const GRID_WIDTH: int = 1280
const GRID_HEIGHT: int = 720
const GRID_COLOR: Color = Color(0.431, 0.478, 0.529, 0.06)
const BEST_SCORE_KEY: String = "best_score"

var deploy_button: Button
var intel_button: Button
var quit_button: Button
var manual_card: PanelContainer
var manual_tabs: HBoxContainer
var manual_title: Label
var manual_description: Label
var manual_diagram: Control
var active_tab: int = 0
var tab_timer: float = 0.0
var attract_time: float = 0.0
var _manual_paused: bool = false

func _ready() -> void:
	GameManager.change_state(GameManager.State.MENU)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.stop_engine()
	_build_war_room()
	_set_manual_tab(0)
	deploy_button.grab_focus()

func _process(delta: float) -> void:
	attract_time += delta
	if not _manual_paused:
		tab_timer += delta
		if tab_timer >= 6.0:
			_set_manual_tab((active_tab + 1) % 3)
	queue_redraw()
	if is_instance_valid(manual_diagram):
		manual_diagram.queue_redraw()

func _draw() -> void:
	# Radial-style layered vignette, coordinate grid and atmospheric scanline framing.
	var viewport_size: Vector2 = size
	for i: int in range(8, 0, -1):
		var inset: float = float(i) * 24.0
		var alpha: float = lerpf(0.55, 0.18, float(i) / 8.0)
		draw_rect(Rect2(Vector2(inset, inset), viewport_size - Vector2(inset * 2.0, inset * 2.0)), Color(0.02, 0.025, 0.03, alpha), false, 24.0)
	for x: int in range(0, GRID_WIDTH + 1, GRID_STEP):
		draw_line(Vector2(x, 0), Vector2(x, GRID_HEIGHT), GRID_COLOR, 1.0)
	for y: int in range(0, GRID_HEIGHT + 1, GRID_STEP):
		draw_line(Vector2(0, y), Vector2(GRID_WIDTH, y), GRID_COLOR, 1.0)
	draw_string(UIThemeBuilder.build_system_font(), Vector2(24, 20), "SEC-01 // LAT 49.2N // FIELD COMMAND LINK", HORIZONTAL_ALIGNMENT_LEFT, -1, UIThemeBuilder.TYPE_MICRO, UIThemeBuilder.UI_TEXT_MUTED)
	draw_string(UIThemeBuilder.build_system_font(), Vector2(size.x - 244, size.y - 54), "LIVE FEED // ATTRACT MODE", HORIZONTAL_ALIGNMENT_LEFT, -1, UIThemeBuilder.TYPE_MICRO, UIThemeBuilder.SEMANTIC_ALLY)

func _build_war_room() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color("#141618")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	move_child(background, 0)

	var vignette: TacticalFrame = TacticalFrame.new()
	vignette.show_brackets = false
	vignette.show_scanlines = true
	vignette.accent_color = Color(0.0, 0.0, 0.0, 0.0)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	var left: VBoxContainer = VBoxContainer.new()
	left.position = Vector2(56, 54)
	left.custom_minimum_size = Vector2(480, 560)
	left.add_theme_constant_override("separation", 12)
	add_child(left)

	var crest: CrestControl = CrestControl.new()
	crest.custom_minimum_size = Vector2(72, 72)
	left.add_child(crest)

	var terminal: Label = Label.new()
	terminal.text = "● FIELD COMMAND TERMINAL // BUILD 1.0"
	terminal.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_MICRO, UIThemeBuilder.UI_BORDER_ACTIVE, 2)
	left.add_child(terminal)

	var title: Label = Label.new()
	title.text = "TRENCH ARMOR"
	title.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_HERO, UIThemeBuilder.UI_TEXT_PRIMARY, 2)
	left.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "SURVIVAL  //  RICOCHET TACTICS"
	subtitle.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_HEADER, UIThemeBuilder.UI_BORDER_ACTIVE, 2)
	left.add_child(subtitle)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	left.add_child(spacer)

	deploy_button = _make_action_button("DEPLOY TO SECTOR    >>", 52)
	intel_button = _make_action_button("TACTICAL INTEL", 44)
	quit_button = _make_action_button("QUIT TO DESKTOP", 44)
	left.add_child(deploy_button)
	left.add_child(intel_button)
	left.add_child(quit_button)
	deploy_button.pressed.connect(_on_deploy_pressed)
	intel_button.pressed.connect(_on_intel_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	_build_manual()
	_build_footer()

func _make_action_button(text: String, height: float) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(340, height)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	UIThemeBuilder.setup_tactical_button(button)
	return button

func _build_manual() -> void:
	manual_card = PanelContainer.new()
	manual_card.position = Vector2(size.x - 496, 54)
	manual_card.custom_minimum_size = Vector2(440, 430)
	manual_card.add_theme_stylebox_override("panel", UIThemeBuilder.panel_style(UIThemeBuilder.UI_BG_DARK, UIThemeBuilder.UI_BORDER_ACTIVE, 4, 2))
	add_child(manual_card)

	var frame: TacticalFrame = TacticalFrame.new()
	frame.show_brackets = true
	frame.show_scanlines = true
	frame.accent_color = UIThemeBuilder.UI_BORDER_ACTIVE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	manual_card.add_child(frame)

	var content: VBoxContainer = VBoxContainer.new()
	content.position = Vector2(16, 16)
	content.custom_minimum_size = Vector2(408, 398)
	content.add_theme_constant_override("separation", 8)
	manual_card.add_child(content)

	manual_title = Label.new()
	manual_title.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_HEADER, UIThemeBuilder.UI_TEXT_PRIMARY)
	content.add_child(manual_title)

	manual_tabs = HBoxContainer.new()
	manual_tabs.add_theme_constant_override("separation", 4)
	content.add_child(manual_tabs)
	for i: int in 3:
		var tab: Button = Button.new()
		tab.text = ["[1] COMBAT", "[2] ESCALATION", "[3] INVASION"][i]
		tab.custom_minimum_size = Vector2(130, 34)
		UIThemeBuilder.setup_tactical_button(tab)
		tab.pressed.connect(_on_manual_tab_pressed.bind(i))
		manual_tabs.add_child(tab)

	manual_diagram = ManualDiagram.new()
	manual_diagram.custom_minimum_size = Vector2(408, 140)
	manual_diagram.set("diagram_index", active_tab)
	content.add_child(manual_diagram)

	manual_description = Label.new()
	manual_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	manual_description.custom_minimum_size = Vector2(408, 80)
	manual_description.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_LABEL, UIThemeBuilder.UI_TEXT_MUTED)
	content.add_child(manual_description)

func _build_footer() -> void:
	var footer: PanelContainer = PanelContainer.new()
	footer.position = Vector2(24, size.y - 68)
	footer.custom_minimum_size = Vector2(size.x - 48, 44)
	footer.add_theme_stylebox_override("panel", UIThemeBuilder.panel_style(UIThemeBuilder.UI_BG_ELEVATED, UIThemeBuilder.UI_ORNAMENT_DIM, 2, 1))
	add_child(footer)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	footer.add_child(row)
	var badge_keys: Array[String] = ["[WASD]", "[MOUSE]", "[LMB]", "[ESC]"]
	var badge_actions: Array[String] = ["DRIVE", "AIM", "FIRE", "PAUSE"]
	for i: int in badge_keys.size():
		row.add_child(UIThemeBuilder.create_keycap_badge(badge_keys[i], badge_actions[i]))
	var filler: Control = Control.new()
	filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(filler)
	var best: Label = Label.new()
	best.text = "BEST RECORD: %06d    STATUS: COMBAT READY" % _get_best_score()
	best.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_MICRO, UIThemeBuilder.SEMANTIC_ALLY)
	row.add_child(best)

func _on_manual_tab_pressed(index: int) -> void:
	_manual_paused = true
	_set_manual_tab(index)

func _set_manual_tab(index: int) -> void:
	active_tab = index
	tab_timer = 0.0
	if manual_title == null:
		return
	var titles: Array[String] = ["FIELD MANUAL // RICOCHET TACTICS", "FIELD MANUAL // THREAT ESCALATION", "FIELD MANUAL // TERRITORY INVASION"]
	var descriptions: Array[String] = [
		"1X WALL BOUNCE = 2X SCORE & HEAVY ARMOR PIERCING. Use angles, not volume.",
		"100% THREAT DEPLOYS IRON GOLIATH. Ricochet rounds deal 2X DAMAGE to the boss.",
		"1280X720 -> 2560X1440. Secure 3 outposts for +500 PTS and +1 ARMOR REPAIR."
	]
	manual_title.text = titles[index]
	manual_description.text = descriptions[index]
	manual_diagram.set("diagram_index", index)
	manual_diagram.queue_redraw()
	for i: int in manual_tabs.get_child_count():
		var tab: Button = manual_tabs.get_child(i) as Button
		tab.modulate = Color.WHITE if i == index else Color(0.65, 0.68, 0.72, 1.0)

func _on_intel_pressed() -> void:
	manual_card.modulate = Color(1.2, 1.1, 0.75, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(manual_card, "modulate", Color.WHITE, 0.35)
	manual_card.grab_focus()

func _on_deploy_pressed() -> void:
	get_tree().change_scene_to_file(ARENA_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _get_best_score() -> int:
	return int(ProjectSettings.get_setting("application/config/best_score", 0))

class CrestControl:
	extends Control

	func _draw() -> void:
		var center: Vector2 = size * 0.5
		var shield: PackedVector2Array = PackedVector2Array([center + Vector2(-32, -34), center + Vector2(32, -34), center + Vector2(36, 16), center + Vector2(0, 36), center + Vector2(-36, 16)])
		draw_colored_polygon(shield, UIThemeBuilder.UI_SURFACE)
		draw_polyline(shield + PackedVector2Array([shield[0]]), UIThemeBuilder.UI_BORDER_STEEL, 2.0)
		draw_rect(Rect2(center.x - 18, center.y - 8, 36, 16), Color("#556B2F"))
		draw_rect(Rect2(center.x - 7, center.y - 18, 14, 36), Color("#556B2F"))
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -10), center + Vector2(3, -3), center + Vector2(11, -3), center + Vector2(5, 2), center + Vector2(7, 10), center, center + Vector2(-7, 10), center + Vector2(-5, 2), center + Vector2(-11, -3), center + Vector2(-3, -3)]), Color.WHITE)
		draw_line(center + Vector2(-18, 27), center + Vector2(-7, 18), UIThemeBuilder.UI_BORDER_ACTIVE, 3.0)
		draw_line(center + Vector2(18, 27), center + Vector2(7, 18), UIThemeBuilder.UI_BORDER_ACTIVE, 3.0)

class ManualDiagram:
	extends Control

	var diagram_index: int = 0

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), UIThemeBuilder.UI_BG_ELEVATED)
		match diagram_index:
			0:
				_draw_combat_diagram()
			1:
				_draw_escalation_diagram()
			_:
				_draw_invasion_diagram()

	func _draw_combat_diagram() -> void:
		draw_line(Vector2(40, 104), Vector2(220, 20), UIThemeBuilder.UI_BORDER_STEEL, 5.0)
		draw_line(Vector2(30, 112), Vector2(130, 64), Color("#FFD700"), 3.0)
		draw_line(Vector2(130, 64), Vector2(260, 104), Color("#FF5500"), 3.0)
		draw_circle(Vector2(130, 64), 5, Color.WHITE)
		draw_string(UIThemeBuilder.build_system_font(), Vector2(274, 108), "2X SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, UIThemeBuilder.TYPE_HEADER, UIThemeBuilder.SEMANTIC_CRIT)

	func _draw_escalation_diagram() -> void:
		draw_line(Vector2(36, 104), Vector2(36, 30), UIThemeBuilder.UI_BORDER_STEEL, 3.0)
		draw_line(Vector2(36, 104), Vector2(190, 104), UIThemeBuilder.UI_BORDER_STEEL, 3.0)
		draw_polyline(PackedVector2Array([Vector2(42, 96), Vector2(90, 84), Vector2(126, 68), Vector2(164, 42), Vector2(204, 26)]), UIThemeBuilder.SEMANTIC_WARN, 4.0)
		draw_circle(Vector2(204, 26), 8.0, UIThemeBuilder.SEMANTIC_DANGER)
		draw_circle(Vector2(330, 70), 30, Color("#36393F"))
		draw_circle(Vector2(330, 70), 34, UIThemeBuilder.UI_TEXT_DANGER, false, 2.0)
		draw_string(UIThemeBuilder.build_system_font(), Vector2(270, 122), "100% THREAT → IRON GOLIATH", HORIZONTAL_ALIGNMENT_LEFT, -1, UIThemeBuilder.TYPE_MICRO, UIThemeBuilder.UI_TEXT_DANGER)

	func _draw_invasion_diagram() -> void:
		draw_rect(Rect2(36, 34, 130, 76), UIThemeBuilder.UI_SURFACE, false, 2.0)
		draw_rect(Rect2(238, 20, 140, 96), UIThemeBuilder.UI_BORDER_STEEL, false, 2.0)
		draw_line(Vector2(166, 72), Vector2(238, 72), UIThemeBuilder.UI_BORDER_ACTIVE, 3.0)
		for p: Vector2 in [Vector2(274, 44), Vector2(326, 44), Vector2(300, 92)]:
			draw_circle(p, 12, UIThemeBuilder.SEMANTIC_ALLY)
		draw_string(UIThemeBuilder.build_system_font(), Vector2(54, 128), "3 OUTPOSTS // +500 PTS // +1 ARMOR", HORIZONTAL_ALIGNMENT_LEFT, -1, UIThemeBuilder.TYPE_MICRO, UIThemeBuilder.SEMANTIC_ALLY)
