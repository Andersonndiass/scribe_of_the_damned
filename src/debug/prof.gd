class_name Prof
extends RefCounted
## Profiler mínimo por seção (T085). Desligado por padrão: custo de um `if` por chamada.
## Uso: var t0: int = Prof.start() ... Prof.stop(&"secao", t0)

static var enabled: bool = false
static var _total_us: Dictionary[StringName, int] = {}
static var _frames: int = 0


static func start() -> int:
	return Time.get_ticks_usec() if enabled else 0


static func stop(key: StringName, t0: int) -> void:
	if enabled:
		_total_us[key] = _total_us.get(key, 0) + (Time.get_ticks_usec() - t0)


static func end_frame() -> void:
	if enabled:
		_frames += 1


static func reset() -> void:
	_total_us.clear()
	_frames = 0


## Média por frame (µs) de cada seção, da mais cara para a mais barata.
static func report() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for key: StringName in _total_us:
		out.append({"key": key, "us": float(_total_us[key]) / maxi(1, _frames)})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["us"] > b["us"])
	return out
