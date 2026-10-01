class_name RefugeZones
extends RefCounted
## Círculo da Água Benta (018 T1813; mechanics-agent T1801): registro estático, como o KillZones.
## No máximo 1 círculo; o EnemyManager não deixa comuns, voadores e campeões entrarem (o chefe
## ignora); o Player não recupera vela parado dentro. Limpar no Main e nos testes.

static var active: bool = false
static var center: Vector2 = Vector2.ZERO
static var radius: float = 0.0


static func open(p_center: Vector2, p_radius: float) -> void:
	active = true
	center = p_center
	radius = p_radius


static func clear() -> void:
	active = false
	radius = 0.0


static func contains(p: Vector2, margin: float = 0.0) -> bool:
	return active and p.distance_to(center) < radius + margin
