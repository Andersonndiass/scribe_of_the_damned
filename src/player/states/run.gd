extends PlayerState


func enter(_msg: Dictionary = {}) -> void:
	player.play_anim(&"run")


func physics_update(_delta: float) -> void:
	var dir: Vector2 = player.input_direction()
	if dir.is_zero_approx():
		transition_requested.emit(&"Idle", {})
		return
	player.move(dir)
