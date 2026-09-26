class_name ProjectileBlockers
extends RefCounted
## Registro de coisas que bloqueiam projéteis inimigos (CRUX, FR-021). Os projéteis inimigos
## (feature 005) perguntam `ProjectileBlockers.blocks(pos)` a cada frame.
## Cada bloqueador implementa `blocks_point(pos: Vector2) -> bool`.

static var _blockers: Array[Object] = []


static func register(blocker: Object) -> void:
	if not _blockers.has(blocker):
		_blockers.append(blocker)


static func unregister(blocker: Object) -> void:
	_blockers.erase(blocker)


static func blocks(pos: Vector2) -> bool:
	for b: Object in _blockers:
		if is_instance_valid(b) and b.call(&"blocks_point", pos):
			return true
	return false


static func count() -> int:
	_blockers = _blockers.filter(func(b: Object) -> bool: return is_instance_valid(b))
	return _blockers.size()
