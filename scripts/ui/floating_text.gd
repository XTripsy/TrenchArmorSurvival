extends Node2D

const FLOAT_DISTANCE: float = 32.0
const DURATION: float = 0.70

@onready var label: Label = Label.new()

func _ready() -> void:
	z_index = 30
	add_child(label)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(300, 40)
	label.position = Vector2(-150, -20)

func setup(text: String, type: String = "normal") -> void:
	if not is_node_ready():
		await ready
	
	label.text = text
	
	var font_size := UIThemeBuilder.TYPE_LABEL
	var font_color := UIThemeBuilder.UI_TEXT_PRIMARY
	var scale_factor := 1.0
	
	match type:
		"ricochet":
			font_size = UIThemeBuilder.TYPE_HEADER
			font_color = UIThemeBuilder.SEMANTIC_CRIT
			scale_factor = 1.25
		"outpost":
			font_size = UIThemeBuilder.TYPE_HEADER
			font_color = UIThemeBuilder.SEMANTIC_ALLY
		"sector":
			font_size = UIThemeBuilder.TYPE_HEADER
			font_color = UIThemeBuilder.UI_TEXT_PRIMARY
		_:
			font_size = UIThemeBuilder.TYPE_LABEL
			font_color = UIThemeBuilder.UI_TEXT_PRIMARY
	
	label.label_settings = UIThemeBuilder.create_label_settings(font_size, font_color)
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "global_position:y", global_position.y - FLOAT_DISTANCE, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	if scale_factor > 1.0:
		scale = Vector2(0.5, 0.5)
		tween.tween_property(self, "scale", Vector2(scale_factor, scale_factor), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
