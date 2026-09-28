class_name VoiceAllocator
extends RefCounted
## Decide qual voz um som usa (009 FR-903). Lógica pura, sem nós; o AudioManager aplica.
## Ordem: (1) cooldown do mesmo som → recusa; (2) max_voices do som cheio → rouba a mais antiga
## dele; (3) voz livre; (4) pool cheio → rouba a mais antiga de prioridade ≤; senão recusa.

var size: int = 0

var _sound := PackedStringArray()
var _prio := PackedInt32Array()
var _started := PackedFloat64Array()
var _last_play: Dictionary[StringName, float] = {}


func _init(p_size: int) -> void:
	size = p_size
	_sound.resize(size)
	_prio.resize(size)
	_started.resize(size)


## Retorna o índice da voz a usar, ou -1 se o som não deve tocar agora. `now` em segundos.
func request(id: StringName, max_voices: int, cooldown_ms: int, priority: int, now: float) -> int:
	if _last_play.has(id) and (now - _last_play[id]) * 1000.0 < float(cooldown_ms) - 0.001:
		return -1
	var v: int = -1
	if active_count(id) >= maxi(1, max_voices):
		v = _oldest(func(i: int) -> bool: return _sound[i] == String(id))
	if v < 0:
		v = _sound.find("")
	if v < 0:
		v = _oldest(func(i: int) -> bool: return _prio[i] <= priority)
	if v < 0:
		return -1
	_sound[v] = String(id)
	_prio[v] = priority
	_started[v] = now
	_last_play[id] = now
	return v


func release(v: int) -> void:
	if v >= 0 and v < size:
		_sound[v] = ""


func sound_of(v: int) -> StringName:
	return StringName(_sound[v])


func is_busy(v: int) -> bool:
	return _sound[v] != ""


func active_count(id: StringName) -> int:
	return _sound.count(String(id))


func busy_count() -> int:
	return size - _sound.count("")


func _oldest(accept: Callable) -> int:
	var best: int = -1
	for i: int in size:
		if _sound[i] != "" and accept.call(i) and (best < 0 or _started[i] < _started[best]):
			best = i
	return best
