class_name FloatingText
extends Node2D

const FLOAT_DISTANCE: float = 30.0
const DURATION: float = 0.8

@onready var label: Label = $Label

func setup(text: String) -> void:
	label.text = text
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", global_position + Vector2(0.0, -FLOAT_DISTANCE), DURATION)
	tween.tween_property(self, "modulate:a", 0.0, DURATION)
	tween.chain().tween_callback(queue_free)
