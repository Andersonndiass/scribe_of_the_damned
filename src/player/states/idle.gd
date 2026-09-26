extends PlayerState


func enter(_msg: Dictionary = {}) -> void:
	player.velocity = Vector2.ZERO
	player.play_anim(&"idle")


func physics_update(_delta: float) -> void:
	if not player.input_direction().is_zero_approx():
		transition_requested.emit(&"Run", {})
		return
	player.move(Vector2.ZERO)
