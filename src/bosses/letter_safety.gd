class_name LetterSafety
extends RefCounted
## Garantia de letras na luta (006 FR-605): se o chão ficar com menos de `min_useful` letras
## úteis por `wait` s, avisa para soltar uma (no máximo uma a cada `cooldown` s). Lógica pura:
## quem conta as letras e as solta é a luta (LetterField + drop ponderado).

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


## Onde a letra cai: num anel em volta do escriba, dentro da página.
func drop_position(player: Vector2, rng: RandomNumberGenerator, page: Rect2) -> Vector2:
	var best := Vector2.ZERO
	for attempt: int in 8:
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(tuning.min_distance, tuning.max_distance)
		best = player + Vector2.RIGHT.rotated(angle) * dist
		if page.has_point(best):
			return best
	return best.clamp(page.position, page.end - Vector2.ONE)
