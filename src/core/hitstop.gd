extends Node
## Congela o jogo por alguns milissegundos (art bible §14). Autoload "Hitstop".
## Pedidos sobrepostos não somam: vale o que termina mais tarde.

var _until_msec: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.hitstop_requested.connect(request)


func request(duration_ms: int) -> void:
	var now: int = Time.get_ticks_msec()
	_until_msec = maxi(_until_msec, now + duration_ms)
	TimeScale.set_factor(&"hitstop", 0.0)


func is_active() -> bool:
	return _until_msec > Time.get_ticks_msec()


func _process(_delta: float) -> void:
	if _until_msec > 0 and Time.get_ticks_msec() >= _until_msec:
		_until_msec = 0
		TimeScale.clear(&"hitstop")  # volta para a câmera lenta, se houver, e não para ×1
