class_name BossState
extends State
## Base dos estados do chefe (006 FR-602): acesso tipado ao Boss e um relógio do estado.

var elapsed: float = 0.0

var boss: Boss:
	get:
		return owner_node as Boss


func enter(msg: Dictionary = {}) -> void:
	elapsed = 0.0
	_on_enter(msg)


func physics_update(delta: float) -> void:
	elapsed += delta
	_tick(delta)


func _on_enter(_msg: Dictionary) -> void:
	pass


func _tick(_delta: float) -> void:
	pass
