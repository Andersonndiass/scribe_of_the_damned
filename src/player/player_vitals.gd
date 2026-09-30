class_name PlayerVitals
extends RefCounted
## Velas, i-frames e recuperação parado do jogador (FR-003, FR-004). Lógica pura, sem nós.
## Recuperação: depois de `idle_regen_delay` s parado, +1 vela a cada `idle_regen_interval` s
## (a 1ª vela chega em delay + interval). Só movimento ou dano zeram a contagem; conjurar parado
## NÃO zera (D-011 revisada: resposta "1c" do autor, 2026-09-26).

var candles: int = 0
## Máximo atual da partida (começa em start_candles; upgrades sobem até cap).
var max_candles: int = 0
## Teto absoluto (8, D-010).
var cap: int = 8
var iframes_left: float = 0.0
var idle_time: float = 0.0

var _data: PlayerData
var _regen_accum: float = 0.0


func setup(data: PlayerData) -> void:
	_data = data
	cap = data.max_candles
	max_candles = mini(data.start_candles, cap)
	candles = max_candles
	iframes_left = 0.0
	notify_action()


func is_alive() -> bool:
	return candles > 0


func is_invulnerable() -> bool:
	return iframes_left > 0.0


## Aplica dano (1 = fraco, 2 = forte). Retorna quanto tirou; 0 se invulnerável ou morto.
func damage(amount: int) -> int:
	if amount <= 0 or not is_alive() or is_invulnerable():
		return 0
	var applied: int = mini(amount, candles)
	candles -= applied
	iframes_left = _data.iframes
	notify_action()
	return applied


## I-frames sem perder vela (golpe absorvido pelo escudo da FIDES).
func grant_iframes() -> void:
	iframes_left = _data.iframes


## Invulnerável por pelo menos `seconds` (016: depois de escolher o selo). Nunca encurta.
func grant_iframes_for(seconds: float) -> void:
	iframes_left = maxf(iframes_left, seconds)


## Acende velas até o máximo atual. Retorna quanto curou.
func heal(amount: int) -> int:
	if amount <= 0 or not is_alive():
		return 0
	var applied: int = mini(amount, max_candles - candles)
	candles += applied
	return applied


## Sobe o máximo atual (upgrades da loja, feature 003). Retorna o novo máximo.
func raise_max(amount: int) -> int:
	max_candles = mini(max_candles + amount, cap)
	return max_candles


## Zera a contagem de "parado" (movimento, conjuração ou dano).
func notify_action() -> void:
	idle_time = 0.0
	_regen_accum = 0.0


## Avança o tempo. Retorna quantas velas foram recuperadas neste passo.
func tick(delta: float, is_idle: bool) -> int:
	iframes_left = maxf(0.0, iframes_left - delta)
	if not is_idle or not is_alive():
		notify_action()
		return 0
	idle_time += delta
	if idle_time < _data.idle_regen_delay:
		return 0
	_regen_accum += minf(delta, idle_time - _data.idle_regen_delay)
	var healed: int = 0
	while _regen_accum >= _data.idle_regen_interval:
		_regen_accum -= _data.idle_regen_interval
		healed += heal(1)
	return healed
