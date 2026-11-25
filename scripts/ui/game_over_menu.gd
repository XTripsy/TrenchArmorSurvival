extends CanvasLayer

const BEST_SCORE_SETTING: String = "application/config/best_score"
const REPORT_CONTENT_TOP: float = 130.0
const REPORT_CONTENT_WIDTH: float = 460.0
const REPORT_CONTENT_HEIGHT: float = 300.0
const RECORD_BADGE_TOP: float = 230.0
const RECORD_BADGE_HEIGHT: float = 28.0
var _is_redeploying: bool = false
var _report_card: Panel

@onready var overlay: Control = $Overlay
@onready var header_label: Label = $Overlay/HeaderLabel
@onready var stats_label: Label = $Overlay/StatsLabel
@onready var redeploy_button: Button = $Overlay/RedeployButton
@onready var menu_button: Button = $Overlay/MenuButton
var _lockout_timer: float = 0.0
var _reveal_timer: float = 0.0
var _rank_stamp: RankStamp
var _record_badge: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	EventBus.game_state_changed.connect(_on_game_state_changed)
	UIThemeBuilder.setup_tactical_button(redeploy_button)
	UIThemeBuilder.setup_tactical_button(menu_button)
	redeploy_button.pressed.connect(_on_redeploy_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	header_label.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_DISPLAY, UIThemeBuilder.UI_TEXT_DANGER, 2)
	stats_label.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_LABEL, UIThemeBuilder.UI_TEXT_PRIMARY, 2)
	_build_report_decoration()
	if GameManager.state == GameManager.State.GAME_OVER:
		_show_stats()

func _build_report_decoration() -> void:
	_report_card = Panel.new()
	_report_card.name = "ReportCard"
	_report_card.position = Vector2(410, REPORT_CONTENT_TOP)
	_report_card.custom_minimum_size = Vector2(REPORT_CONTENT_WIDTH, REPORT_CONTENT_HEIGHT)
	_report_card.add_theme_stylebox_override("panel", UIThemeBuilder.panel_style(UIThemeBuilder.UI_BG_DARK, UIThemeBuilder.UI_BORDER_STEEL, 4, 2))
	overlay.add_child(_report_card)

	var frame: TacticalFrame = TacticalFrame.new()
	frame.show_brackets = true
	frame.show_scanlines = true
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_report_card.add_child(frame)
	stats_label.reparent(_report_card)
	stats_label.position = Vector2(0, 108)
	stats_label.size = Vector2(REPORT_CONTENT_WIDTH, 132)

	var report_label: Label = Label.new()
	report_label.text = "AFTER-ACTION COMBAT REPORT"
	report_label.position = Vector2(0, 56)
	report_label.size = Vector2(REPORT_CONTENT_WIDTH, 30)
	report_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	report_label.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_HEADER, UIThemeBuilder.UI_TEXT_MUTED)
	overlay.add_child(report_label)

	_rank_stamp = RankStamp.new()
	_rank_stamp.position = Vector2(850, REPORT_CONTENT_TOP + 18.0)
	_rank_stamp.custom_minimum_size = Vector2(76, 76)
	_rank_stamp.visible = false
	overlay.add_child(_rank_stamp)

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
	if _is_redeploying:
		return
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
	var best_score: int = int(ProjectSettings.get_setting(BEST_SCORE_SETTING, 0))
	var is_record: bool = GameManager.score > best_score
	if is_record:
		ProjectSettings.set_setting(BEST_SCORE_SETTING, GameManager.score)
	header_label.text = "ARMOR DESTROYED"
	header_label.position = Vector2(0, 65)
	stats_label.text = "FINAL SCORE: %06d\nSECTOR REACHED: %02d\nOUTPOSTS CAPTURED: %d/%d\nRICOCHET KILLS: %d\nTIME SURVIVED: %02d:%02d" % [
		GameManager.score,
		GameManager.sector_index,
		GameManager.zones_captured,
		GameManager.zones_total,
		GameManager.ricochet_kills,
		total / 60,
		total % 60,
	]
	if _record_badge == null:
		_record_badge = Label.new()
		_record_badge.position = Vector2(0, RECORD_BADGE_TOP)
		_record_badge.size = Vector2(REPORT_CONTENT_WIDTH, RECORD_BADGE_HEIGHT)
		_record_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_record_badge.label_settings = UIThemeBuilder.create_label_settings(UIThemeBuilder.TYPE_HEADER, UIThemeBuilder.UI_BORDER_ACTIVE, 2)
		_report_card.add_child(_record_badge)
	_record_badge.text = "NEW RECORD!" if is_record else ""
	_rank_stamp.rank_text = _rank_for_score(GameManager.score)
	_rank_stamp.visible = true
	_rank_stamp.scale = Vector2(2.2, 2.2)
	_rank_stamp.rotation = deg_to_rad(-6.0)
	var stamp_tween: Tween = create_tween()
	stamp_tween.tween_property(_rank_stamp, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	overlay.visible = true
	_lockout_timer = 0.8
	redeploy_button.disabled = true

func _rank_for_score(score: int) -> String:
	if score >= 8000:
		return "RANK S"
	if score >= 4500:
		return "RANK A"
	if score >= 2000:
		return "RANK B"
	return "RANK C"

func _unhandled_input(event: InputEvent) -> void:
	if overlay.visible and event.is_action_pressed("ui_accept"):
		if _lockout_timer <= 0.0:
			_on_redeploy_pressed()
		get_viewport().set_input_as_handled()

func _on_redeploy_pressed() -> void:
	if _lockout_timer > 0.0 or _is_redeploying:
		return
	_is_redeploying = true
	overlay.visible = false
	redeploy_button.disabled = true
	GameManager.change_state(GameManager.State.PLAYING)
	var arena: Node = get_parent()
	if arena != null and arena.has_method("restart_run"):
		arena.call("restart_run")

func _on_menu_pressed() -> void:
	var arena: Node = get_parent()
	if arena != null and arena.has_method("return_to_menu"):
		arena.call("return_to_menu")

class RankStamp:
	extends Control

	var rank_text: String = "RANK C"

	func _draw() -> void:
		var center: Vector2 = size * 0.5
		draw_circle(center, 34.0, Color("#1B1E22"))
		draw_arc(center, 34.0, 0.0, TAU, 32, UIThemeBuilder.UI_BORDER_ACTIVE, 3.0)
		draw_string(UIThemeBuilder.build_system_font(), center + Vector2(-27, 5), rank_text, HORIZONTAL_ALIGNMENT_CENTER, 54, UIThemeBuilder.TYPE_MICRO, UIThemeBuilder.UI_BORDER_ACTIVE)
