extends Node

# --- UI TOKENS (Source of Truth) ---
const UI_BG_DARK := Color("#141618e6") # 0.9 alpha
const UI_SURFACE := Color("#22262af2") # 0.95 alpha
const UI_SURFACE_HOVER := Color("#2E343B")
const UI_BORDER_STEEL := Color("#4D5660")
const UI_BORDER_ACTIVE := Color("#E0AF3E")
const UI_TEXT_PRIMARY := Color("#F4F1EA")
const UI_TEXT_MUTED := Color("#A8B2BC")
const UI_TEXT_DANGER := Color("#FF6B6B")

const SEMANTIC_ALLY := Color("#5E943B")
const SEMANTIC_WARN := Color("#E59528")
const SEMANTIC_DANGER := Color("#D13B3B")
const SEMANTIC_CRIT := Color("#FF6A1A")

# --- TYPOGRAPHY CONSTANTS ---
const TYPE_DISPLAY := 48
const TYPE_METRIC := 24
const TYPE_HEADER := 18
const TYPE_LABEL := 14
const TYPE_MICRO := 12

func build_system_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["JetBrains Mono", "Consolas", "Liberation Mono", "Courier New"])
	font.font_weight = 700 # Bold
	return font

func create_label_settings(size: int, color: Color = UI_TEXT_PRIMARY, outline_size: int = 2) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font = build_system_font()
	settings.font_size = size
	settings.font_color = color
	settings.outline_size = outline_size
	settings.outline_color = Color("#0B0C0E")
	if size == TYPE_DISPLAY:
		settings.line_spacing = 2
	return settings

func panel_style(bg: Color, border: Color, radius: int = 4, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func setup_tactical_button(btn: Button) -> void:
	if not btn.is_node_ready():
		await btn.ready
	
	# Initial style and pivot
	_update_btn_pivot(btn)
	if not btn.resized.is_connected(_update_btn_pivot.bind(btn)):
		btn.resized.connect(_update_btn_pivot.bind(btn))
	
	# Theme overrides
	btn.add_theme_stylebox_override("normal", panel_style(UI_SURFACE, UI_BORDER_STEEL))
	btn.add_theme_stylebox_override("hover", panel_style(UI_SURFACE_HOVER, UI_BORDER_ACTIVE))
	btn.add_theme_stylebox_override("focus", panel_style(UI_SURFACE_HOVER, UI_BORDER_ACTIVE))
	btn.add_theme_stylebox_override("pressed", panel_style(UI_BG_DARK, UI_BORDER_ACTIVE))
	btn.add_theme_stylebox_override("disabled", panel_style(UI_SURFACE, UI_BORDER_STEEL))
	
	btn.add_theme_color_override("font_color", UI_TEXT_PRIMARY)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_focus_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_font_override("font", build_system_font())
	btn.add_theme_font_size_override("font_size", TYPE_LABEL)
	
	# Animations
	if not btn.mouse_entered.is_connected(_on_btn_hover.bind(btn)):
		btn.mouse_entered.connect(_on_btn_hover.bind(btn))
		btn.focus_entered.connect(_on_btn_hover.bind(btn))
		btn.mouse_exited.connect(_on_btn_exit.bind(btn))
		btn.focus_exited.connect(_on_btn_exit.bind(btn))
		btn.button_down.connect(_on_btn_down.bind(btn))
		btn.button_up.connect(_on_btn_hover.bind(btn))
		btn.pressed.connect(_on_btn_pressed.bind(btn))

func _update_btn_pivot(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0

func _on_btn_hover(btn: Button) -> void:
	if btn.disabled: return
	if btn.has_focus() or btn.get_global_rect().has_point(btn.get_global_mouse_position()):
		AudioManager.play_ui_hover()
		var tween := btn.create_tween()
		tween.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_btn_exit(btn: Button) -> void:
	if btn.disabled: return
	var tween := btn.create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_btn_down(btn: Button) -> void:
	if btn.disabled: return
	var tween := btn.create_tween()
	tween.tween_property(btn, "scale", Vector2(0.97, 0.97), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_btn_pressed(btn: Button) -> void:
	if btn.disabled: return
	AudioManager.play_ui_click()
