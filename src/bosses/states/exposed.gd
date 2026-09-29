extends BossState
## Janela de exposição (FR-609b; D-062): por `exposed_time` s as palavras ferem +25%.


func _on_enter(_msg: Dictionary) -> void:
	boss.filter.expose()
	EventBus.boss_exposed.emit(boss.data.exposed_time)


func _tick(_delta: float) -> void:
	if elapsed >= boss.data.exposed_time:
		transition_requested.emit(&"Idle", {})
