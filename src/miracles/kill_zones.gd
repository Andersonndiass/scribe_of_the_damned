class_name KillZones
extends RefCounted
## Zonas letais ativas (D-084), no mesmo molde do ProjectileBlockers: os milagres registram, o
## EnemyManager lê a cada tick. Limpar no Main e nos testes para nenhuma zona vazar.

static var _zones: Array[KillZone] = []


static func register(zone: KillZone) -> void:
	if not _zones.has(zone):
		_zones.append(zone)


static func unregister(zone: KillZone) -> void:
	_zones.erase(zone)


static func active() -> Array[KillZone]:
	return _zones


static func clear() -> void:
	_zones.clear()
