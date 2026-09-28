class_name Miracle
extends Node2D
## Base dos milagres (plan §4.10). Cada palavra estende esta classe e lê SÓ os campos do
## WordData, multiplicados por `power` (FR-018). Pooled com a chave = id da palavra.

var word: WordData
var power: float = 1.0
var origin: Vector2
var direction: Vector2 = Vector2.RIGHT
## GLORIA (002 FR-209): multiplica só o dano e a cura, nunca raio, stun, duração ou limiar.
var damage_mul: float = 1.0


func start(p_word: WordData, p_power: float, p_origin: Vector2, p_direction: Vector2) -> void:
	word = p_word
	power = p_power
	origin = p_origin
	direction = p_direction.normalized() if not p_direction.is_zero_approx() else Vector2.RIGHT
	global_position = origin
	_on_start()


## Dano final de um valor-base do WordData: × power × GLORIA, no mínimo 1.
func dmg(base: float) -> int:
	return maxi(1, roundi(base * power * damage_mul))


## Sobrescrever: aplica o efeito.
func _on_start() -> void:
	pass


## Devolve o milagre ao pool.
func finish() -> void:
	PoolManager.release(self)
