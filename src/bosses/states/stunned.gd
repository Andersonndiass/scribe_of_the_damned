extends BossState
## Atordoado (DOMINUS, já com o `stun_mul` do chefe; D-062 3A).

var _time: float = 0.0


func _on_enter(msg: Dictionary) -> void:
	boss.cancel_attack()
	_time = msg.get("time", 1.0)


func _tick(_delta: float) -> void:
	if elapsed >= _time:
		transition_requested.emit(&"Idle", {})
