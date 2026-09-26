extends PlayerState
## Reação curta ao dano. O jogador continua se movendo (survivors-like não tira o controle);
## os i-frames correm em paralelo no PlayerVitals.

const DURATION := 0.15

var _left: float = 0.0


func enter(_msg: Dictionary = {}) -> void:
	_left = DURATION


func physics_update(delta: float) -> void:
	_left -= delta
	var dir: Vector2 = player.input_direction()
	player.move(dir)
	player.play_anim(&"idle" if dir.is_zero_approx() else &"run")
	if _left <= 0.0:
		transition_requested.emit(&"Idle" if dir.is_zero_approx() else &"Run", {})
