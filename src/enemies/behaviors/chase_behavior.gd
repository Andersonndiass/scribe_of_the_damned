class_name ChaseBehavior
extends EnemyBehavior
## Persegue o alvo, desacelerando ao encostar (Diabrete, FR-503).


func desired_velocity(m: EnemyManager, i: int, target: Vector2, _dt: float) -> Vector2:
	return seek(m, i, target)


## Velocidade até `target` com chegada suave; reutilizada pelos outros comportamentos.
static func seek(m: EnemyManager, i: int, target: Vector2, speed_mul: float = 1.0) -> Vector2:
	if target == Vector2.INF:
		return Vector2.ZERO
	var to_target: Vector2 = target - m.positions[i]
	var dist: float = to_target.length()
	if dist <= 1.0:
		return Vector2.ZERO
	var arrive: float = clampf(dist / (m.radius_of[i] * EnemyManager.ARRIVE_RADIUS_MUL), 0.0, 1.0)
	return to_target / dist * m.data_of[i].move_speed * m.slow_factor[i] * m.speed_mul[i] * arrive * speed_mul
