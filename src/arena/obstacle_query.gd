class_name ObstacleQuery
extends RefCounted
## Ponto único de consulta aos obstáculos (004; mesmo molde do EnemyQuery): o Arena registra o mapa
## ao montar a página e zera ao sair. Sem mapa (testes sem arena), tudo está livre.

static var map: ObstacleMap = null


static func is_free(p: Vector2, r: float, mask: int = ObstacleTypeData.Block.WALK) -> bool:
	return map == null or map.is_free(p, r, mask)


static func constrain(p: Vector2, r: float, mask: int = ObstacleTypeData.Block.WALK) -> Vector2:
	return p if map == null else map.constrain(p, r, mask)


static func nearest_free(p: Vector2, r: float) -> Vector2:
	return p if map == null else map.nearest_free(p, r)


static func blocks(p: Vector2, mask: int) -> bool:
	return map != null and map.blocks(p, mask)
