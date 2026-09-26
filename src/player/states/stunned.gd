extends PlayerState
## Atordoado (heresia, FR-019): não se move. msg = {"time": float}.

var _left: float = 0.0


func enter(msg: Dictionary = {}) -> void:
	_left = msg.get("time", 0.5)
	player.velocity = Vector2.ZERO
	player.play_anim(&"idle")


func physics_update(delta: float) -> void:
	_left -= delta
	player.move(Vector2.ZERO)
	if _left <= 0.0:
		transition_requested.emit(&"Idle", {})
