class_name State
extends Node
## Estado genérico de uma StateMachine (plan §4.4).
## Para trocar de estado, emita transition_requested com o nome do nó do estado de destino.

signal transition_requested(to: StringName, msg: Dictionary)

## Dono da máquina (ex.: o Player). Preenchido pela StateMachine.
var owner_node: Node


func enter(_msg: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass
