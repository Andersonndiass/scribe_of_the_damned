class_name ShakeCamera
extends Camera2D
## Câmera da página com screen shake (006 FR-612, D-047 6B; animation-agent). Fica parada no
## centro da página; o shake é um deslocamento em px inteiros que decai linearmente. Um pedido
## novo só substitui o atual se for mais forte (nunca soma). Roda em tempo real (o hit-stop não
## congela o tremor). Desligado por `GameState.shake_enabled` (a tela de Opções, 007, liga/desliga).
## Os HUDs são CanvasLayer: não tremem.

const PAGE_CENTER := Vector2(320, 180)

var strength: float = 0.0

var _duration: float = 0.0
var _left: float = 0.0
var _last_us: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	position = PAGE_CENTER
	make_current()
	EventBus.shake_requested.connect(request)


## Pede um tremor de `p_strength` px por `p_duration` s.
func request(p_strength: float, p_duration: float) -> void:
	if not GameState.shake_enabled or p_duration <= 0.0:
		return
	if p_strength < current_strength():
		return
	strength = p_strength
	_duration = p_duration
	_left = p_duration


## Força que ainda resta do tremor atual.
func current_strength() -> float:
	return strength * (_left / _duration) if _left > 0.0 and _duration > 0.0 else 0.0


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	var dt: float = float(now - _last_us) / 1_000_000.0 if _last_us > 0 else 0.0
	_last_us = now
	step(dt)


## Avança o tremor por `dt` s (tempo real).
func step(dt: float) -> void:
	if _left <= 0.0:
		offset = Vector2.ZERO
		return
	_left = maxf(0.0, _left - dt)
	var s: int = int(round(current_strength()))
	offset = Vector2(_rng.randi_range(-s, s), _rng.randi_range(-s, s)) if s > 0 else Vector2.ZERO
