extends BossState
## Morte (FR-611; animation-agent): hit-stop de 100 ms e shake forte; dissolução por `death_time`;
## as letras douradas saem em `death_burst_at`; `boss_defeated` no fim.

const HIT_STOP_MS := 100
const SHAKE := 4.0
const SHAKE_TIME := 0.7

var _burst_done: bool = false
var _defeated: bool = false


func _on_enter(_msg: Dictionary) -> void:
	boss.cancel_attack()
	boss.targetable = false
	_burst_done = false
	_defeated = false
	if boss.manager != null and boss.manager.boss_target == boss:
		boss.manager.boss_target = null
	EventBus.hitstop_requested.emit(HIT_STOP_MS)
	EventBus.shake_requested.emit(SHAKE, SHAKE_TIME)


func _tick(_delta: float) -> void:
	if not _burst_done and elapsed >= boss.data.death_burst_at:
		_burst_done = true
		EventBus.boss_letters_burst.emit(boss.global_position, boss.data.death_letters)
	if not _defeated and elapsed >= boss.data.death_time:
		_defeated = true
		boss.fighting = false
		boss.visible = false
		EventBus.boss_defeated.emit(boss.data)
