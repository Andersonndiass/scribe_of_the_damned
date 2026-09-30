class_name Miracle
extends Node2D
## Base dos milagres (plan §4.10). Cada palavra estende esta classe e lê SÓ os campos do
## WordData, multiplicados por `power` (FR-018). Pooled com a chave = id da palavra.

var word: WordData
var power: float = 1.0
var origin: Vector2
var direction: Vector2 = Vector2.RIGHT
## GLORIA (002 FR-209) × Tinta Consagrada (016): multiplica só o dano, nunca raio, stun, duração ou
## limiar.
var damage_mul: float = 1.0
## Só GLORIA: a cura (VITA, SALVATOR) não cresce com a Tinta Consagrada (016, rules-agent R1).
var heal_mul: float = 1.0
## Origem para o chefe (006): conjuração e id da palavra/combo. O Caster preenche.
var cast_id: int = 0
var tag: StringName = &""


func start(p_word: WordData, p_power: float, p_origin: Vector2, p_direction: Vector2) -> void:
	word = p_word
	power = p_power
	origin = p_origin
	direction = p_direction.normalized() if not p_direction.is_zero_approx() else Vector2.RIGHT
	global_position = origin
	_on_start()


## Dano final de um valor-base do WordData: × power × GLORIA, no mínimo 1.
func dmg(base: float) -> int:
	begin_hit()
	return maxi(1, roundi(base * power * damage_mul))


## Marca quem fere a partir de agora (DamageSource), para o chefe (006). O dmg() já chama; quem
## calcula o dano por conta própria (PURGO) chama antes do golpe.
func begin_hit() -> void:
	DamageSource.mark(tag if tag != &"" else (word.id if word != null else &"miracle"), cast_id)


## Sobrescrever: aplica o efeito.
func _on_start() -> void:
	pass


## Devolve o milagre ao pool.
func finish() -> void:
	PoolManager.release(self)
