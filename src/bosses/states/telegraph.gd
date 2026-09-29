extends BossState
## Telegrafia (SC-605): nunca menor que `BossData.min_telegraph`.

var _duration: float = 0.0


func _on_enter(msg: Dictionary) -> void:
	var attack: AttackData = msg["attack"]
	boss.current_attack = attack
	boss.current_executor = boss.executor_for(attack)
	_duration = maxf(attack.telegraph, boss.data.min_telegraph)
	if boss.current_executor != null:
		boss.current_executor.begin(attack, boss)


func _tick(_delta: float) -> void:
	if elapsed >= _duration:
		transition_requested.emit(&"Attack", {})
