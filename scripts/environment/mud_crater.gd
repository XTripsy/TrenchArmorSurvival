class_name MudCrater
extends Area2D

const SLOWDOWN_MULTIPLIER: float = 0.65

func _ready() -> void:
	collision_layer = 32
	collision_mask = 3
	z_index = -1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.get("speed_multiplier") != null:
		body.set("speed_multiplier", SLOWDOWN_MULTIPLIER)

func _on_body_exited(body: Node2D) -> void:
	if body.get("speed_multiplier") != null:
		body.set("speed_multiplier", 1.0)
