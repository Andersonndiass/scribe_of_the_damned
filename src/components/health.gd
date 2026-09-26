class_name Health
extends Node
## Vida inteira (velas do jogador, HP de chefes). Não conhece quem a usa.

signal changed(value: int, max_value: int)
signal damaged(amount: int, value: int)
signal healed(amount: int, value: int)
signal depleted()

@export var max_value: int = 3
@export var value: int = 3


func setup(start: int, maximum: int) -> void:
	max_value = maximum
	value = clampi(start, 0, maximum)
	changed.emit(value, max_value)


## Aplica dano e retorna quanto foi efetivamente tirado.
func damage(amount: int) -> int:
	if amount <= 0 or value <= 0:
		return 0
	var applied: int = mini(amount, value)
	value -= applied
	damaged.emit(applied, value)
	changed.emit(value, max_value)
	if value == 0:
		depleted.emit()
	return applied


## Cura e retorna quanto foi efetivamente curado.
func heal(amount: int) -> int:
	if amount <= 0 or value <= 0:
		return 0
	var applied: int = mini(amount, max_value - value)
	if applied == 0:
		return 0
	value += applied
	healed.emit(applied, value)
	changed.emit(value, max_value)
	return applied


func is_full() -> bool:
	return value >= max_value
