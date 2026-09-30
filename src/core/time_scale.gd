extends Node
## Dono único do `Engine.time_scale` (017 T1701; animation-agent e mechanics-agent T1700).
## Autoload "TimeScale". `time_scale = base × produto dos fatores`: o hit-stop pede 0, o menu da
## letra pede a câmera lenta, e nenhum apaga o outro ao terminar. Ninguém mais escreve direto.

## 1 no jogo; a sonda de balanceamento põe 4.
var base: float = 1.0
var _factors: Dictionary[StringName, float] = {}


func set_factor(owner: StringName, factor: float) -> void:
	_factors[owner] = maxf(factor, 0.0)
	_apply()


func clear(owner: StringName) -> void:
	if _factors.erase(owner):
		_apply()


func has_factor(owner: StringName) -> bool:
	return _factors.has(owner)


func factor_product() -> float:
	var p: float = 1.0
	for f: float in _factors.values():
		p *= f
	return p


## Volta ao normal (troca de tela, reinício, testes); a base fica.
func reset() -> void:
	_factors.clear()
	_apply()


func set_base(value: float) -> void:
	base = maxf(value, 0.0)
	_apply()


func _apply() -> void:
	Engine.time_scale = base * factor_product()
