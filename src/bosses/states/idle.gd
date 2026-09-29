extends BossState
## Espera o intervalo da fase e escolhe o próximo ataque (FR-603).


func _on_enter(_msg: Dictionary) -> void:
	boss.current_attack = null
	boss.current_executor = null


func _tick(_delta: float) -> void:
	if elapsed < boss.phase().interval:
		return
	var attack: AttackData = boss.picker.pick(boss.phase(), boss.clock, boss.distance_to_player())
	if attack == null:
		elapsed = 0.0
		return
	boss.picker.record(attack, boss.clock)
	transition_requested.emit(&"Telegraph", {"attack": attack})
