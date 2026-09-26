class_name InkDrop
extends Node2D
## Projétil do ataque automático (PRJ_INK_DROP). Pooled em &"ink_drop" (FR-002).

const POOL_KEY := &"ink_drop"
const HIT_RADIUS := 3.0

var _dir: Vector2 = Vector2.RIGHT
var _speed: float = 0.0
var _damage: int = 1
var _distance_left: float = 0.0


func fire(origin: Vector2, direction: Vector2, speed: float, damage: int, max_distance: float) -> void:
	global_position = origin
	_dir = direction.normalized()
	_speed = speed
	_damage = damage
	_distance_left = max_distance


func _physics_process(delta: float) -> void:
	var t0: int = Prof.start()
	var step: float = _speed * delta
	global_position += _dir * step
	_distance_left -= step
	if EnemyQuery.hit(global_position, HIT_RADIUS, _damage) or _distance_left <= 0.0:
		PoolManager.release(self)
	Prof.stop(&"projeteis_total", t0)
