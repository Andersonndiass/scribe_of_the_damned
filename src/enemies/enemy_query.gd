class_name EnemyQuery
extends RefCounted
## Ponto único de consulta aos inimigos para quem precisa mirar ou acertar (AutoAttack, projéteis,
## milagres). O provider real é o EnemyManager (T030); até lá, o TargetDummies de debug.
## O provider implementa:
##   query_nearest(pos: Vector2, radius: float) -> Vector2   (Vector2.INF se não houver)
##   query_hit(pos: Vector2, radius: float, damage: int) -> bool
##   damage_line(origin: Vector2, dir: Vector2, length: float, width: float, damage: int) -> int

static var provider: Object = null:
	set(value):
		provider = value
		_manager = value as EnemyManager

## Atalho tipado quando o provider é o EnemyManager (evita o call() dinâmico no laço quente).
static var _manager: EnemyManager = null


static func nearest(pos: Vector2, radius: float) -> Vector2:
	if _manager != null:
		return _manager.query_nearest(pos, radius)
	if provider == null:
		return Vector2.INF
	return provider.call(&"query_nearest", pos, radius)


## Os `n` alvos mais próximos (inimigos e chefe), do mais perto ao mais longe (017: Pena com várias
## gotas). Provider sem a consulta de lista: só o mais próximo.
static func nearest_list(pos: Vector2, radius: float, n: int) -> PackedVector2Array:
	if _manager != null:
		return _manager.query_nearest_list(pos, radius, n)
	var one: Vector2 = nearest(pos, radius)
	return PackedVector2Array() if one == Vector2.INF else PackedVector2Array([one])


static func hit(pos: Vector2, radius: float, damage: int) -> bool:
	if _manager != null:
		return _manager.query_hit(pos, radius, damage)
	if provider == null:
		return false
	return provider.call(&"query_hit", pos, radius, damage)


## Acerto que atravessa (017 Crucifixo): uids novos atingidos (-1 = chefe). Só com o EnemyManager.
static func hit_pierce(pos: Vector2, radius: float, damage: int, already: PackedInt32Array, freeze: float, max_new: int) -> PackedInt32Array:
	if _manager != null:
		return _manager.query_hit_pierce(pos, radius, damage, already, freeze, max_new)
	if provider != null and max_new > 0 and provider.call(&"query_hit", pos, radius, damage):
		return PackedInt32Array([0])
	return PackedInt32Array()


## Dano em todos os inimigos no retângulo que sai de `origin` na direção `dir`. Retorna quantos acertou.
static func damage_line(origin: Vector2, dir: Vector2, length: float, width: float, damage: int) -> int:
	if provider == null:
		return 0
	return provider.call(&"damage_line", origin, dir, length, width, damage)
