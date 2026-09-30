class_name LetterSafety
extends RefCounted
## Garantia de letras na luta (006 FR-605; 017): se passar `wait` s sem menu de letra (a luta
## informa `min_useful` quando abriu algum), avisa para pedir um (no máximo um a cada `cooldown`
## s). Lógica pura: quem conta e pede é a luta (LetterField/LetterMenu).

var tuning: LetterSafetyTuning
var _below: float = 0.0
var _cooldown_left: float = 0.0


func _init(p_tuning: LetterSafetyTuning) -> void:
	tuning = p_tuning


## Avança `delta` s com `useful` letras úteis no chão. Retorna true se é hora de soltar uma.
func tick(delta: float, useful: int) -> bool:
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	if useful >= tuning.min_useful:
		_below = 0.0
		return false
	_below += delta
	if _below >= tuning.wait - 0.0001 and _cooldown_left <= 0.0:
		_below = 0.0
		_cooldown_left = tuning.cooldown
		return true
	return false

