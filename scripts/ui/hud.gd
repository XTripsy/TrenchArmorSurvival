extends CanvasLayer

const INNER_BOUNDS: Rect2 = Rect2(0.0, 0.0, 1280.0, 720.0)
const SAFE_MARGIN: float = 24.0
const POINTER_MARGIN: float = 32.0

# Minimap constants
const MINIMAP_SIZE: Vector2 = Vector2(168.0, 94.0)
const MINIMAP_ENEMY_LIMIT: int = 80

# Dynamic State
var _active_bounds: Rect2 = INNER_BOUNDS
var _boss_hp: int = 0
var _boss_max_hp: int = 0
var _boss_trail_hp: float = 0.0
var _boss_trail_tween: Tween = null
var _last_score: int = 0
var _last_player_hp: int = 3
var _reticle_spread: float = 0.0
var _radar_angle: float = 0.0
var _ricochet_streak: int = 0

# UI Nodes
@onready var root: Control = $HUDRoot

# Top-Left Nodes
var armor_card: PanelContainer
var armor_container: HBoxContainer
var armor_status_lbl: Label
var _armor_segments: Array[PanelContainer] = []
var _critical_tween: Tween = null
var _chassis_icon: Control = null

# Top-Center Nodes
var phase_card: Control
var phase_header: Label
var skirmish_bar: ProgressBar
var boss_bar_back: PanelContainer
var boss_bar_trail: StyleBoxFlat
var boss_bar_fill: StyleBoxFlat
var boss_bar_fill_panel: Panel
var boss_bar_trail_panel: Panel
var invasion_container: HBoxContainer
var _invasion_badges: Array[PanelContainer] = []

# Top-Right Nodes
var telemetry_card: VBoxContainer
var score_label: Label
var time_label: Label
var streak_pill: PanelContainer

# Overlay Layer 2 Phase Banner
var banner_layer: CanvasLayer
var banner_panel: PanelContainer
var banner_label: Label
var crimson_vignette: ColorRect

# Overlay for Diegetic Pointers & Minimap
var _tactical_overlay: Control = null
var reticle: Control = null

func get_boss_trail_hp() -> float:
	return _boss_trail_hp

func _ready() -> void:
	layer = 1
	EventBus.score_updated.connect(_on_score_updated)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.game_state_changed.connect(_on_game_state_changed)
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_hp_changed.connect(_on_boss_hp_changed)
	EventBus.map_expanded.connect(_on_map_expanded)
	EventBus.sector_cleared.connect(_on_sector_cleared)

	_build_ui()
	_build_banner_layer()
	_refresh_score(GameManager.score)
	var player: Node = get_tree().get_first_node_in_group("player")
	var initial_hp: int = 3
	if player != null and player.get("hp") != null:
		initial_hp = int(player.get("hp"))
	_refresh_shields(initial_hp)
	_refresh_time()
	_refresh_objective()

func _build_ui() -> void:
	# 1. Top-Left: Armor Integrity Card
	armor_card = PanelContainer.new()
	armor_card.position = Vector2(SAFE_MARGIN, SAFE_MARGIN)
	armor_card.add_theme_stylebox_override("panel", UIThemeBuilder.panel_style(UIThemeBuilder.UI_BG_DARK, UIThemeBuilder.UI_BORDER_STEEL))
	root.add_child(armor_card)

	var armor_frame: TacticalFrame = TacticalFrame.new()
	armor_frame.show_brackets = true
	armor_frame.show_scanlines = true
	armor_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	armor_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	armor_card.add_child(armor_frame)

	var armor_hbox := HBoxContainer.new()
	armor_hbox.add_theme_constant_override("separation", 8)
	armor_card.add_child(armor_hbox)

	_chassis_icon = ChassisIcon.new()
	_chassis_icon.custom_minimum_size = Vector2(36, 36)
	armor_hbox.add_child(_chassis_icon)

	var armor_vbox := VBoxContainer.new()
	armor_vbox.add_theme_constant_override("separation", 4)
	armor_hbox.add_child(armor_vbox)

	var header_row := HBoxContainer.new()
	armor_vbox.add_child(header_row)

	var armor_lbl := Label.new()
	armor_lbl.text = "CHASSIS // VANGUARD-01"
	armor_lbl.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_MICRO, UIThemeBuilder.UI_TEXT_MUTED)
	header_row.add_child(armor_lbl)

	armor_status_lbl = Label.new()
	armor_status_lbl.text = "NOMINAL"
	armor_status_lbl.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_MICRO, UIThemeBuilder.SEMANTIC_ALLY)
	header_row.add_child(armor_status_lbl)

	armor_container = HBoxContainer.new()
	armor_container.add_theme_constant_override("separation", 6)
	armor_vbox.add_child(armor_container)

	# 2. Top-Center: Phase & Objective Tracker
	phase_card = Control.new()
	phase_card.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	phase_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(phase_card)

	var phase_vbox := VBoxContainer.new()
	phase_vbox.position = Vector2(1280.0 * 0.5 - 230.0, SAFE_MARGIN)
	phase_vbox.custom_minimum_size = Vector2(460.0, 60.0)
	phase_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	phase_card.add_child(phase_vbox)

	phase_header = Label.new()
	phase_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_header.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_LABEL, UIThemeBuilder.UI_TEXT_PRIMARY)
	phase_vbox.add_child(phase_header)

	# Skirmish Progress Bar
	skirmish_bar = ProgressBar.new()
	skirmish_bar.custom_minimum_size = Vector2(360.0, 14.0)
	skirmish_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skirmish_bar.show_percentage = false
	var skirmish_bg := UIThemeBuilder.panel_style(UIThemeBuilder.UI_SURFACE, UIThemeBuilder.UI_BORDER_STEEL, 2, 1)
	var skirmish_fg := UIThemeBuilder.panel_style(UIThemeBuilder.SEMANTIC_WARN, Color.TRANSPARENT, 2, 0)
	skirmish_bar.add_theme_stylebox_override("background", skirmish_bg)
	skirmish_bar.add_theme_stylebox_override("fill", skirmish_fg)
	phase_vbox.add_child(skirmish_bar)

	# Boss Bar (Double layer for trail)
	boss_bar_back = PanelContainer.new()
	boss_bar_back.custom_minimum_size = Vector2(460.0, 18.0)
	boss_bar_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	boss_bar_back.add_theme_stylebox_override("panel", UIThemeBuilder.panel_style(UIThemeBuilder.UI_SURFACE, UIThemeBuilder.UI_BORDER_STEEL, 2, 1))
	boss_bar_back.visible = false
	phase_vbox.add_child(boss_bar_back)

	boss_bar_trail = UIThemeBuilder.panel_style(Color(1, 1, 1, 0.85), Color.TRANSPARENT, 2, 0)
	boss_bar_trail_panel = Panel.new()
	boss_bar_trail_panel.add_theme_stylebox_override("panel", boss_bar_trail)
	boss_bar_back.add_child(boss_bar_trail_panel)

	boss_bar_fill = UIThemeBuilder.panel_style(UIThemeBuilder.SEMANTIC_DANGER, Color.TRANSPARENT, 2, 0)
	boss_bar_fill_panel = Panel.new()
	boss_bar_fill_panel.add_theme_stylebox_override("panel", boss_bar_fill)
	boss_bar_back.add_child(boss_bar_fill_panel)

	# Invasion Badges Container
	invasion_container = HBoxContainer.new()
	invasion_container.alignment = BoxContainer.ALIGNMENT_CENTER
	invasion_container.add_theme_constant_override("separation", 12)
	invasion_container.visible = false
	phase_vbox.add_child(invasion_container)

	for i: int in 3:
		var badge := PanelContainer.new()
		badge.custom_minimum_size = Vector2(84.0, 28.0)
		badge.add_theme_stylebox_override("panel", UIThemeBuilder.panel_style(UIThemeBuilder.UI_SURFACE, UIThemeBuilder.UI_BORDER_STEEL, 2, 1))
		var lbl := Label.new()
		lbl.name = "BadgeLabel"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_MICRO, UIThemeBuilder.UI_TEXT_MUTED)
		badge.add_child(lbl)
		invasion_container.add_child(badge)
		_invasion_badges.append(badge)

	# 3. Top-Right: Telemetry Panel
	telemetry_card = VBoxContainer.new()
	telemetry_card.position = Vector2(1280.0 - SAFE_MARGIN - 210.0, SAFE_MARGIN)
	telemetry_card.custom_minimum_size = Vector2(210.0, 70.0)
	telemetry_card.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(telemetry_card)

	var score_micro := Label.new()
	score_micro.text = "COMBAT SCORE"
	score_micro.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_micro.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_MICRO, UIThemeBuilder.UI_TEXT_MUTED)
	telemetry_card.add_child(score_micro)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.pivot_offset = Vector2(210.0, 12.0)
	score_label.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_METRIC, UIThemeBuilder.UI_TEXT_PRIMARY)
	telemetry_card.add_child(score_label)

	time_label = Label.new()
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_LABEL, UIThemeBuilder.UI_TEXT_MUTED)
	telemetry_card.add_child(time_label)

	streak_pill = PanelContainer.new()
	streak_pill.visible = false
	streak_pill.add_theme_stylebox_override("panel", UIThemeBuilder.panel_style(UIThemeBuilder.UI_BG_ELEVATED, UIThemeBuilder.SEMANTIC_CRIT, 2, 1))
	var streak_lbl := Label.new()
	streak_lbl.name = "StreakLabel"
	streak_lbl.text = "RICOCHET STREAK x2"
	streak_lbl.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_MICRO, UIThemeBuilder.SEMANTIC_CRIT)
	streak_pill.add_child(streak_lbl)
	telemetry_card.add_child(streak_pill)

	# 4. Tactical Overlay (_draw for radar & off-screen pointers)
	var tactical_overlay: TacticalOverlay = TacticalOverlay.new()
	tactical_overlay.hud = self
	_tactical_overlay = tactical_overlay
	root.add_child(_tactical_overlay)

	# 5. Diegetic Reticle
	_build_reticle()

func _build_banner_layer() -> void:
	banner_layer = CanvasLayer.new()
	banner_layer.layer = 2
	add_child(banner_layer)

	crimson_vignette = ColorRect.new()
	crimson_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crimson_vignette.color = Color(0.82, 0.23, 0.23, 0.0)
	crimson_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_layer.add_child(crimson_vignette)

	banner_panel = PanelContainer.new()
	banner_panel.custom_minimum_size = Vector2(720, 50)
	banner_panel.position = Vector2(1280.0 * 0.5 - 360.0, 128.0)
	banner_panel.visible = false
	banner_panel.add_theme_stylebox_override("panel", UIThemeBuilder.panel_style(UIThemeBuilder.UI_BG_DARK, UIThemeBuilder.UI_BORDER_ACTIVE, 4, 2))
	banner_layer.add_child(banner_panel)

	var frame: TacticalFrame = TacticalFrame.new()
	frame.show_hazard_stripes = true
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_panel.add_child(frame)

	banner_label = Label.new()
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_label.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_HEADER, UIThemeBuilder.UI_BORDER_ACTIVE)
	banner_panel.add_child(banner_label)

func show_phase_banner(message: String) -> void:
	banner_label.text = message
	banner_panel.visible = true
	banner_panel.modulate.a = 0.0
	banner_panel.position.x = 1280.0 * 0.5 - 360.0 - 80.0
	var tween: Tween = create_tween()
	tween.tween_property(banner_panel, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(banner_panel, "position:x", 1280.0 * 0.5 - 360.0, 0.2)
	tween.tween_interval(1.3)
	tween.tween_property(banner_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void: banner_panel.visible = false)

func _build_reticle() -> void:
	reticle = Control.new()
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(reticle)

	var dot := ColorRect.new()
	dot.name = "Dot"
	dot.size = Vector2(2, 2)
	dot.position = Vector2(-1, -1)
	dot.color = UIThemeBuilder.UI_TEXT_PRIMARY
	reticle.add_child(dot)

	for i: int in 4:
		var line := ColorRect.new()
		line.name = "Line%d" % i
		line.color = UIThemeBuilder.UI_TEXT_PRIMARY
		reticle.add_child(line)

func _process(delta: float) -> void:
	_refresh_time()
	_refresh_objective()
	_update_reticle(delta)
	_radar_angle = fmod(_radar_angle + delta * TAU * 0.5, TAU)
	if is_instance_valid(_chassis_icon):
		var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if player != null:
			_chassis_icon.rotation = player.rotation
			_chassis_icon.queue_redraw()

func _update_reticle(delta: float) -> void:
	reticle.position = reticle.get_global_mouse_position()
	reticle.visible = GameManager.state == GameManager.State.PLAYING

	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player != null and player.has_method("get_fire_cooldown_ratio"):
		var ratio: float = float(player.call("get_fire_cooldown_ratio"))
		_reticle_spread = ratio * 8.0
	else:
		_reticle_spread = maxf(0.0, _reticle_spread - delta * (8.0 / 0.45))

	var gap: float = 4.0 + _reticle_spread
	var line_len: float = 6.0
	var line_w: float = 2.0

	var top: ColorRect = reticle.get_node("Line0") as ColorRect
	top.position = Vector2(-line_w * 0.5, -gap - line_len)
	top.size = Vector2(line_w, line_len)

	var bot: ColorRect = reticle.get_node("Line1") as ColorRect
	bot.position = Vector2(-line_w * 0.5, gap)
	bot.size = Vector2(line_w, line_len)

	var left: ColorRect = reticle.get_node("Line2") as ColorRect
	left.position = Vector2(-gap - line_len, -line_w * 0.5)
	left.size = Vector2(line_len, line_w)

	var right: ColorRect = reticle.get_node("Line3") as ColorRect
	right.position = Vector2(gap, -line_w * 0.5)
	right.size = Vector2(line_len, line_w)

func _on_score_updated(new_score: int, ricochet_kills: int) -> void:
	if new_score > _last_score:
		_punch_score()
	_last_score = new_score
	_refresh_score(new_score)
	_ricochet_streak = ricochet_kills
	if streak_pill != null:
		streak_pill.visible = _ricochet_streak >= 2
		var lbl: Label = streak_pill.get_node("StreakLabel") as Label
		if lbl != null:
			lbl.text = "🔥 RICOCHET STREAK x%d" % _ricochet_streak

func _punch_score() -> void:
	var tween := create_tween()
	score_label.scale = Vector2(1.2, 1.2)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_player_damaged(current_hp: int, max_hp: int) -> void:
	_refresh_shields(current_hp, max_hp)

func _on_game_state_changed(_new_state: int) -> void:
	reticle.visible = GameManager.state == GameManager.State.PLAYING

func _on_phase_changed(new_phase: int) -> void:
	if new_phase == int(GameManager.Phase.BOSS):
		show_phase_banner("⚠ WARNING: IRON GOLIATH APPROACHING")
	elif new_phase == int(GameManager.Phase.INVASION):
		show_phase_banner("PERIMETER BREACHED — SECTOR EXPANDED")
	if GameManager.current_phase == GameManager.Phase.SKIRMISH:
		_boss_hp = 0
		_boss_max_hp = 0
		_boss_trail_hp = 0.0
	_animate_phase_transition()
	_refresh_objective()

func _animate_phase_transition() -> void:
	var tween := create_tween()
	phase_header.modulate.a = 0.0
	phase_header.position.y = -8.0
	tween.parallel().tween_property(phase_header, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(phase_header, "position:y", 0.0, 0.25)

func _on_boss_spawned(_boss_name: String, current_hp: int, max_hp: int) -> void:
	_boss_hp = current_hp
	_boss_max_hp = max_hp
	_boss_trail_hp = float(max_hp)
	_refresh_objective()

func _on_boss_hp_changed(current_hp: int, max_hp: int) -> void:
	_boss_hp = current_hp
	_boss_max_hp = max_hp
	if _boss_trail_tween != null and _boss_trail_tween.is_running():
		_boss_trail_tween.kill()

	_boss_trail_tween = create_tween()
	_boss_trail_tween.tween_interval(0.25)
	_boss_trail_tween.tween_property(self, "_boss_trail_hp", float(current_hp), 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_refresh_objective()

func _on_map_expanded(new_bounds: Rect2) -> void:
	_active_bounds = new_bounds

func _on_sector_cleared(_sector_num: int, bonus_score: int) -> void:
	show_phase_banner("SECTOR CLEARED // REPAIRING INTEGRITY")
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		VFXManager.spawn_floating_text(player.global_position, "+%d SECTOR CLEARED!" % bonus_score)

func _refresh_score(value: int) -> void:
	score_label.text = "%06d" % value

func _refresh_time() -> void:
	var total: int = maxi(0, floori(GameManager.time_survived))
	time_label.text = "TIME %02d:%02d" % [total / 60, total % 60]

func _refresh_objective() -> void:
	match GameManager.current_phase:
		GameManager.Phase.BOSS:
			phase_header.text = "WARNING: IRON GOLIATH // RICOCHET WEAKNESS [2X DMG]"
			phase_header.label_settings.font_color = UIThemeBuilder.UI_TEXT_DANGER
			skirmish_bar.visible = false
			boss_bar_back.visible = true
			invasion_container.visible = false

			if _boss_max_hp > 0:
				var fill_ratio: float = clampf(float(_boss_hp) / float(_boss_max_hp), 0.0, 1.0)
				var trail_ratio: float = clampf(_boss_trail_hp / float(_boss_max_hp), 0.0, 1.0)
				boss_bar_fill_panel.size = Vector2(460.0 * fill_ratio, 18.0)
				boss_bar_trail_panel.size = Vector2(460.0 * trail_ratio, 18.0)

		GameManager.Phase.INVASION:
			phase_header.text = "TERRITORY INVASION  //  CAPTURE ALL OUTPOSTS"
			phase_header.label_settings.font_color = UIThemeBuilder.UI_TEXT_PRIMARY
			skirmish_bar.visible = false
			boss_bar_back.visible = false
			invasion_container.visible = true
			_update_invasion_badges()

		_:
			phase_header.text = "SECTOR %02d  //  THREAT ESCALATION %d%%" % [GameManager.sector_index, int(GameManager.threat_progress)]
			phase_header.label_settings.font_color = UIThemeBuilder.UI_TEXT_PRIMARY
			skirmish_bar.visible = true
			skirmish_bar.value = GameManager.threat_progress
			boss_bar_back.visible = false
			invasion_container.visible = false

func _update_invasion_badges() -> void:
	var zones: Array[Node] = get_tree().get_nodes_in_group("capture_zone")
	for i: int in _invasion_badges.size():
		var badge: PanelContainer = _invasion_badges[i]
		var lbl: Label = badge.get_node("BadgeLabel") as Label
		if i < zones.size():
			var zone: Node2D = zones[i] as Node2D
			var state: int = int(zone.get("state"))
			var progress: float = float(zone.get("progress"))
			match state:
				1: # CAPTURING
					badge.add_theme_stylebox_override("panel", UIThemeBuilder.panel_style(UIThemeBuilder.SEMANTIC_WARN, UIThemeBuilder.UI_BORDER_ACTIVE, 2, 1))
					lbl.text = "%02d [ ▲ ] %d%%" % [i + 1, int(progress * 100)]
					lbl.label_settings.font_color = UIThemeBuilder.UI_BG_DARK
				2: # CONTESTED
					badge.add_theme_stylebox_override("panel", UIThemeBuilder.panel_style(UIThemeBuilder.SEMANTIC_DANGER, Color.WHITE, 2, 1))
					lbl.text = "%02d [ ! ]" % [i + 1]
					lbl.label_settings.font_color = Color.WHITE
				3: # CAPTURED
					badge.add_theme_stylebox_override("panel", UIThemeBuilder.panel_style(UIThemeBuilder.SEMANTIC_ALLY, UIThemeBuilder.UI_BORDER_STEEL, 2, 1))
					lbl.text = "%02d [ ✓ ]" % [i + 1]
					lbl.label_settings.font_color = Color.WHITE
				_: # NEUTRAL
					badge.add_theme_stylebox_override("panel", UIThemeBuilder.panel_style(UIThemeBuilder.UI_SURFACE, UIThemeBuilder.UI_BORDER_STEEL, 2, 1))
					lbl.text = "%02d [ - ]" % [i + 1]
					lbl.label_settings.font_color = UIThemeBuilder.UI_TEXT_MUTED
		else:
			badge.visible = false

func _refresh_shields(current_hp: int, max_hp: int = 3) -> void:
	if _armor_segments.size() != max_hp:
		for seg: PanelContainer in _armor_segments:
			seg.queue_free()
		_armor_segments.clear()

		var seg_width: float = 38.0 if max_hp <= 5 else 30.0
		for i: int in max_hp:
			var seg := PanelContainer.new()
			seg.custom_minimum_size = Vector2(seg_width, 16.0)
			armor_container.add_child(seg)
			_armor_segments.append(seg)

	if current_hp < _last_player_hp and _last_player_hp <= _armor_segments.size():
		var lost_idx: int = _last_player_hp - 1
		if lost_idx >= 0 and lost_idx < _armor_segments.size():
			_flash_segment_white(_armor_segments[lost_idx])
	_last_player_hp = current_hp

	for i: int in max_hp:
		var seg: PanelContainer = _armor_segments[i]
		if i < current_hp:
			if current_hp == 1:
				seg.add_theme_stylebox_override("panel", UIThemeBuilder.panel_style(UIThemeBuilder.SEMANTIC_DANGER, Color("#FF8888"), 2, 1))
			else:
				seg.add_theme_stylebox_override("panel", UIThemeBuilder.panel_style(UIThemeBuilder.SEMANTIC_ALLY, Color("#84C458"), 2, 1))
		else:
			seg.add_theme_stylebox_override("panel", UIThemeBuilder.panel_style(UIThemeBuilder.UI_SURFACE, UIThemeBuilder.UI_BORDER_STEEL, 2, 1))

	if armor_status_lbl != null:
		if current_hp == 1:
			armor_status_lbl.text = "CRITICAL"
			armor_status_lbl.label_settings.font_color = UIThemeBuilder.SEMANTIC_DANGER
		elif current_hp == 2:
			armor_status_lbl.text = "CAUTION"
			armor_status_lbl.label_settings.font_color = UIThemeBuilder.SEMANTIC_WARN
		else:
			armor_status_lbl.text = "NOMINAL"
			armor_status_lbl.label_settings.font_color = UIThemeBuilder.SEMANTIC_ALLY

	if current_hp == 1:
		crimson_vignette.color.a = 0.16
		if _critical_tween == null or not _critical_tween.is_running():
			_critical_tween = create_tween().set_loops()
			_critical_tween.tween_property(_armor_segments[0], "modulate:a", 0.55, 0.25)
			_critical_tween.tween_property(_armor_segments[0], "modulate:a", 1.0, 0.25)
	else:
		crimson_vignette.color.a = 0.0
		if _critical_tween != null and _critical_tween.is_running():
			_critical_tween.kill()
			if _armor_segments.size() > 0:
				_armor_segments[0].modulate.a = 1.0

func _flash_segment_white(seg: PanelContainer) -> void:
	var flash_style := UIThemeBuilder.panel_style(Color.WHITE, Color.WHITE, 2, 1)
	seg.add_theme_stylebox_override("panel", flash_style)
	var tween := create_tween()
	tween.tween_interval(0.15)
	tween.tween_callback(func() -> void:
		seg.add_theme_stylebox_override("panel", UIThemeBuilder.panel_style(UIThemeBuilder.UI_SURFACE, UIThemeBuilder.UI_BORDER_STEEL, 2, 1))
	)

func draw_tactical(canvas: CanvasItem) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	var viewport_size: Vector2 = canvas.get_viewport_rect().size
	_draw_off_screen_arrows(canvas, viewport_size)
	_draw_minimap(canvas, viewport_size)

func _draw_off_screen_arrows(canvas: CanvasItem, viewport_size: Vector2) -> void:
	var center: Vector2 = viewport_size * 0.5
	var safe_rect: Rect2 = Rect2(Vector2(POINTER_MARGIN, POINTER_MARGIN), viewport_size - Vector2(POINTER_MARGIN, POINTER_MARGIN) * 2.0)
	var camera: Camera2D = canvas.get_viewport().get_camera_2d()

	for node: Node in get_tree().get_nodes_in_group("capture_zone"):
		var zone: Node2D = node as Node2D
		if zone == null or bool(zone.get("captured")):
			continue
		var zone_state: int = int(zone.get("state"))
		_draw_direction_arrow(canvas, viewport_size, center, safe_rect, zone.global_position, camera, _zone_color(zone_state))

	for node: Node in get_tree().get_nodes_in_group("boss"):
		var boss: Node2D = node as Node2D
		if boss != null:
			_draw_direction_arrow(canvas, viewport_size, center, safe_rect, boss.global_position, camera, UIThemeBuilder.SEMANTIC_DANGER)

func _draw_direction_arrow(canvas: CanvasItem, viewport_size: Vector2, center: Vector2, safe_rect: Rect2, world_position: Vector2, camera: Camera2D, color: Color) -> void:
	var screen_position: Vector2 = canvas.get_viewport().get_canvas_transform() * world_position
	if safe_rect.has_point(screen_position):
		return
	var direction: Vector2 = (screen_position - center)
	if direction.is_zero_approx():
		return
	direction = direction.normalized()
	var half: Vector2 = viewport_size * 0.5 - Vector2(POINTER_MARGIN, POINTER_MARGIN)
	var scale_x: float = INF
	var scale_y: float = INF
	if absf(direction.x) > 0.001:
		scale_x = half.x / absf(direction.x)
	if absf(direction.y) > 0.001:
		scale_y = half.y / absf(direction.y)
	var distance: float = minf(scale_x, scale_y)
	var tip: Vector2 = center + direction * distance
	var base: Vector2 = tip - direction * 18.0
	var side: Vector2 = direction.orthogonal() * 6.0
	var points: PackedVector2Array = PackedVector2Array([tip, base + side, base - side])
	canvas.draw_colored_polygon(points, color)

	var dist_m: int = int((world_position - (camera.global_position if camera != null else center)).length() / 10.0)
	var text := "%dm" % dist_m
	var font := UIThemeBuilder.build_system_font()
	canvas.draw_string(font, tip - direction * 30.0 + Vector2(-10, 4), text, HORIZONTAL_ALIGNMENT_CENTER, -1, UIThemeBuilder.TYPE_MICRO, UIThemeBuilder.UI_TEXT_PRIMARY)

func _draw_minimap(canvas: CanvasItem, viewport_size: Vector2) -> void:
	var rect := Rect2(Vector2(viewport_size.x - MINIMAP_SIZE.x - SAFE_MARGIN, SAFE_MARGIN + 70.0), MINIMAP_SIZE)

	canvas.draw_rect(rect, UIThemeBuilder.UI_BG_DARK)
	canvas.draw_rect(rect, UIThemeBuilder.UI_BORDER_STEEL, false, 2.0)

	canvas.draw_line(Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y), Vector2(rect.position.x + rect.size.x * 0.5, rect.end.y), Color(1, 1, 1, 0.12), 1.0)
	canvas.draw_line(Vector2(rect.position.x, rect.position.y + rect.size.y * 0.5), Vector2(rect.end.x, rect.position.y + rect.size.y * 0.5), Color(1, 1, 1, 0.12), 1.0)
	canvas.draw_string(UIThemeBuilder.build_system_font(), rect.position + Vector2(4, 12), "A1", HORIZONTAL_ALIGNMENT_LEFT, -1, UIThemeBuilder.TYPE_MICRO, UIThemeBuilder.UI_TEXT_MUTED)
	canvas.draw_string(UIThemeBuilder.build_system_font(), rect.position + Vector2(rect.size.x - 18, rect.size.y - 4), "B2", HORIZONTAL_ALIGNMENT_LEFT, -1, UIThemeBuilder.TYPE_MICRO, UIThemeBuilder.UI_TEXT_MUTED)

	var sweep_end: Vector2 = rect.get_center() + Vector2.RIGHT.rotated(_radar_angle) * (rect.size.length() * 0.5)
	canvas.draw_line(rect.get_center(), sweep_end, Color(0.369, 0.580, 0.231, 0.35), 2.0)

	var inner := rect.grow(-4.0)

	for node: Node in get_tree().get_nodes_in_group("bouncy_surface"):
		var obs: Node2D = node as Node2D
		if obs != null:
			canvas.draw_circle(_to_minimap(obs.global_position, inner), 2.0, UIThemeBuilder.UI_ORNAMENT_DIM)

	for node: Node in get_tree().get_nodes_in_group("capture_zone"):
		var zone: Node2D = node as Node2D
		if zone == null:
			continue
		var point: Vector2 = _to_minimap(zone.global_position, inner)
		canvas.draw_circle(point, 6.0, _zone_color(int(zone.get("state"))))

	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	var limit: int = mini(enemies.size(), MINIMAP_ENEMY_LIMIT)
	for i: int in limit:
		var enemy: Node2D = enemies[i] as Node2D
		if enemy != null:
			canvas.draw_circle(_to_minimap(enemy.global_position, inner), 2.5, UIThemeBuilder.SEMANTIC_DANGER)

	for node: Node in get_tree().get_nodes_in_group("boss"):
		var boss: Node2D = node as Node2D
		if boss != null:
			var point: Vector2 = _to_minimap(boss.global_position, inner)
			canvas.draw_circle(point, 5.0, UIThemeBuilder.SEMANTIC_DANGER)
			canvas.draw_arc(point, 6.0, 0.0, TAU, 12, Color.WHITE, 1.5)

	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		var p_pos: Vector2 = _to_minimap(player.global_position, inner)
		canvas.draw_circle(p_pos, 3.5, Color.WHITE)
		var turret_dir: Vector2 = Vector2.RIGHT.rotated(player.rotation)
		canvas.draw_line(p_pos, p_pos + turret_dir * 9.0, Color.WHITE, 1.5)

func _to_minimap(world_position: Vector2, inner: Rect2) -> Vector2:
	var normalized: Vector2 = (world_position - _active_bounds.position) / _active_bounds.size
	normalized = Vector2(clampf(normalized.x, 0.0, 1.0), clampf(normalized.y, 0.0, 1.0))
	return inner.position + normalized * inner.size

func _zone_color(zone_state: int) -> Color:
	match zone_state:
		1:
			return UIThemeBuilder.SEMANTIC_WARN
		2:
			return UIThemeBuilder.SEMANTIC_DANGER
		3:
			return UIThemeBuilder.SEMANTIC_ALLY
		_:
			return UIThemeBuilder.UI_SURFACE

class ChassisIcon:
	extends Control

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		draw_rect(Rect2(c - Vector2(10, 14), Vector2(20, 28)), Color("#556B2F"))
		draw_line(c, c + Vector2(0, -18), Color.WHITE, 2.0)
		draw_circle(c, 5.0, UIThemeBuilder.UI_BORDER_STEEL)

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
