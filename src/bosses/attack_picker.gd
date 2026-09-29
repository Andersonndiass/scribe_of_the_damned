class_name AttackPicker
extends RefCounted
## Escolhe o próximo ataque do chefe (006 FR-603). Lógica pura:
##   sorteio ponderado pelos pesos da fase, sem o mesmo ataque 3 vezes seguidas, respeitando o
##   cooldown de cada ataque e a condição de distância (Swipe só perto).

var _rng: RandomNumberGenerator
var _last_used: Dictionary[StringName, float] = {}
var _history: Array[StringName] = []


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng


## O próximo ataque da `phase` no instante `now`, com o escriba a `distance`; null se nenhum serve.
func pick(phase: PhaseData, now: float, distance: float) -> AttackData:
	var options: Array[AttackData] = []
	var weights := PackedFloat32Array()
	var total: float = 0.0
	for i: int in phase.attacks.size():
		var a: AttackData = phase.attacks[i]
		if not _allowed(a, now, distance):
			continue
		var w: float = phase.weights[i] if i < phase.weights.size() else 1.0
		options.append(a)
		weights.append(w)
		total += w
	if options.is_empty():
		return null
	var roll: float = _rng.randf() * total
	for i: int in options.size():
		roll -= weights[i]
		if roll < 0.0:
			return options[i]
	return options[options.size() - 1]


func record(attack: AttackData, now: float) -> void:
	_last_used[attack.id] = now
	_history.append(attack.id)
	if _history.size() > 2:
		_history.pop_front()


func _allowed(a: AttackData, now: float, distance: float) -> bool:
	if a.max_distance > 0.0 and distance > a.max_distance:
		return false
	if a.cooldown > 0.0 and _last_used.has(a.id) and now - _last_used[a.id] < a.cooldown - 0.0001:
		return false
	return not (_history.size() == 2 and _history[0] == a.id and _history[1] == a.id)
