extends BossState
## Golpe ativo por `AttackData.active` s. Raio/Swipe que erram abrem a exposição (FR-609b).

const EXPOSING: Array[StringName] = [&"beam", &"double_beam", &"swipe"]


func _on_enter(_msg: Dictionary) -> void:
	if boss.current_executor != null:
		boss.current_executor.activate()


func _tick(_delta: float) -> void:
	var attack: AttackData = boss.current_attack
	if attack == null or elapsed < attack.active:
		return
	var ex: BossAttack = boss.current_executor
	var missed: bool = ex != null and not ex.hit_player
	if ex != null:
		ex.finish()
	if missed and attack.kind in EXPOSING:
		transition_requested.emit(&"Exposed", {})
	else:
		transition_requested.emit(&"Recover", {})
