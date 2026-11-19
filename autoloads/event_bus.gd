extends Node

signal player_damaged(current_hp: int, max_hp: int)
signal player_died()
signal enemy_destroyed(enemy_position: Vector2, base_score: int, was_ricochet: bool)
signal score_updated(new_score: int, ricochet_kills: int)
signal camera_shake_requested(intensity: float, duration: float)
signal bullet_ricocheted(impact_position: Vector2, impact_normal: Vector2)
signal game_state_changed(new_state: int)
