class_name StateMachine
extends Node
## Máquina de estados genérica (plan §4.4). Os estados são nós-filhos do tipo State.

signal state_changed(from: StringName, to: StringName)

@export var initial_state: State

var current: State
var _states: Dictionary[StringName, State] = {}


func _ready() -> void:
	var owner_node: Node = owner if owner != null else get_parent()
	for child: Node in get_children():
		if child is State:
			var s := child as State
			_states[s.name] = s
			s.owner_node = owner_node
			s.transition_requested.connect(transition_to)
	if initial_state == null and not _states.is_empty():
		initial_state = _states.values()[0]
	# Os filhos ficam prontos antes do pai: espera o dono terminar o _ready
	# para que os @onready dele existam quando o estado inicial entrar.
	if owner_node != null and not owner_node.is_node_ready():
		await owner_node.ready
	if initial_state != null:
		current = initial_state
		current.enter()


func _process(delta: float) -> void:
	if current != null:
		current.update(delta)


func _physics_process(delta: float) -> void:
	if current != null:
		current.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current != null:
		current.handle_input(event)


func has_state(state_name: StringName) -> bool:
	return _states.has(state_name)


func transition_to(to: StringName, msg: Dictionary = {}) -> void:
	if not _states.has(to):
		push_error("StateMachine '%s': estado inexistente '%s'" % [name, to])
		return
	var from: StringName = current.name if current != null else &""
	if current != null:
		current.exit()
	current = _states[to]
	current.enter(msg)
	state_changed.emit(from, to)
