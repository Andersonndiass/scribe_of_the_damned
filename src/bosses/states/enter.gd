extends BossState
## Entrada (006 FR-607; animation-agent): invulnerável por `enter_time`; o corpo é revelado de
## baixo para cima entre `enter_rise_start` e `enter_rise_end`. Depois, o intervalo da F1.


func _on_enter(_msg: Dictionary) -> void:
	boss.targetable = false
	boss.reveal = 0.0


func _tick(_delta: float) -> void:
	var d: BossData = boss.data
	boss.reveal = clampf((elapsed - d.enter_rise_start) / maxf(0.001, d.enter_rise_end - d.enter_rise_start), 0.0, 1.0)
	if elapsed >= d.enter_time:
		boss.reveal = 1.0
		boss.targetable = true
		transition_requested.emit(&"Idle", {})
