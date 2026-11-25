class_name TacticalFrame
extends Control

@export var show_brackets: bool = true
@export var show_scanlines: bool = true
@export var show_hazard_stripes: bool = false
@export var accent_color: Color = Color("#4D5660")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if get_child_count() == 0 and not is_connected("resized", _on_resized):
		resized.connect(_on_resized)

func _on_resized() -> void:
	queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	
	# 1. Background Fill
	draw_rect(r, Color(0.078, 0.086, 0.094, 0.92))
	
	# 2. Hazard Stripes (if enabled)
	if show_hazard_stripes:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var stripe_w := 6.0
		var stride := 18.0
		var max_dim := maxf(size.x, size.y) * 2.0
		var i := -int(max_dim)
		while i < int(max_dim):
			var p1 = Vector2(float(i), -50.0)
			var p2 = Vector2(float(i) + max_dim, max_dim + 50.0)
			draw_line(p1, p2, Color(0.898, 0.584, 0.157, 0.18), stripe_w)
			i += int(stride)
	
	# 3. Micro Scanlines (if enabled)
	if show_scanlines:
		var y := 2.0
		while y < size.y:
			draw_line(Vector2(2.0, y), Vector2(size.x - 2.0, y), Color(1, 1, 1, 0.03), 1.0)
			y += 4.0
	
	# 4. Main Steel Border
	draw_rect(r, accent_color, false, 2.0)
	
	# 5. Corner L-Brackets (if enabled)
	if show_brackets:
		var bl := 10.0
		var bw := 2.0
		var col := Color("#6E7A87")
		# Top-Left
		draw_line(Vector2(3, 3), Vector2(3 + bl, 3), col, bw)
		draw_line(Vector2(3, 3), Vector2(3, 3 + bl), col, bw)
		# Top-Right
		draw_line(Vector2(size.x - 3, 3), Vector2(size.x - 3 - bl, 3), col, bw)
		draw_line(Vector2(size.x - 3, 3), Vector2(size.x - 3, 3 + bl), col, bw)
		# Bottom-Left
		draw_line(Vector2(3, size.y - 3), Vector2(3 + bl, size.y - 3), col, bw)
		draw_line(Vector2(3, size.y - 3), Vector2(3, size.y - 3 - bl), col, bw)
		# Bottom-Right
		draw_line(Vector2(size.x - 3, size.y - 3), Vector2(size.x - 3 - bl, size.y - 3), col, bw)
		draw_line(Vector2(size.x - 3, size.y - 3), Vector2(size.x - 3, size.y - 3 - bl), col, bw)
