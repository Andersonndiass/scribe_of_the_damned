class_name WeaponZones
extends RefCounted
## Zonas de arma ativas (017 T1711), no molde do KillZones: a arma registra, o EnemyManager lê a
## cada tick. Limpar no Main e nos testes para nenhuma zona vazar.

static var _zones: Array[WeaponZone] = []


static func register(zone: WeaponZone) -> void:
	if not _zones.has(zone):
		_zones.append(zone)


static func unregister(zone: WeaponZone) -> void:
	_zones.erase(zone)


static func active() -> Array[WeaponZone]:
	return _zones


static func clear() -> void:
	_zones.clear()
