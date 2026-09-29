extends BossState
## Pausa depois do golpe (`AttackData.recover`).


func _tick(_delta: float) -> void:
	var rec: float = boss.current_attack.recover if boss.current_attack != null else 0.0
	if elapsed >= rec:
		transition_requested.emit(&"Idle", {})
