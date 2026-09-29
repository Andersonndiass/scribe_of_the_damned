extends BossState
## Troca de fase (FR-602; animation-agent): cancela o ataque; hit-stop de 60 ms e shake médio; o
## chefe fica invulnerável pelo tempo do BossDamageFilter e volta ao Idle na nova fase.

const HIT_STOP_MS := 60
const SHAKE := 2.0
const SHAKE_TIME := 0.4


func _on_enter(_msg: Dictionary) -> void:
	boss.cancel_attack()
	EventBus.hitstop_requested.emit(HIT_STOP_MS)
	EventBus.shake_requested.emit(SHAKE, SHAKE_TIME)
	EventBus.boss_phase_changed.emit(boss.filter.phase_index)


func _tick(_delta: float) -> void:
	if elapsed >= boss.data.phase_shift_invulnerable:
		transition_requested.emit(&"Idle", {})
