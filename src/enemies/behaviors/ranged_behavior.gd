class_name RangedBehavior
extends EnemyBehavior
## Monge Oco (005 FR-506): mantém distância entre keep_min e keep_max do jogador; a cada
## fire_interval telegrafa por `windup` s (páginas BLOOD) e dispara 1 projétil na direção
## travada no início do windup.

@export var keep_min: float = 110.0
@export var keep_max: float = 150.0
@export var fire_interval: float = 2.2
@export var windup: float = 0.4
## Só inicia o tiro com o jogador a até keep_max × este fator.
@export var fire_range_mul: float = 1.6
@export var projectile: EnemyProjectileData


func _init() -> void:
	needs_tick = true


func desired_velocity(m: EnemyManager, i: int, target: Vector2, _dt: float) -> Vector2:
	if m.state[i] == STATE_WINDUP or target == Vector2.INF:
		return Vector2.ZERO
	var dist: float = m.positions[i].distance_to(target)
	if dist < keep_min:
		return -ChaseBehavior.seek(m, i, target)
	if dist > keep_max:
		return ChaseBehavior.seek(m, i, target)
	return Vector2.ZERO


func tick(m: EnemyManager, i: int, dt: float) -> void:
	var target: Vector2 = m.player_body()
	if m.state[i] == STATE_WINDUP:
		m.state_timer[i] -= dt
		if m.state_timer[i] <= 0.0:
			var pm: EnemyProjectileManager = m.get_projectiles()
			if pm != null and projectile != null:
				pm.fire(projectile, m.positions[i] + Vector2(0, -8), m.aim[i])
				EventBus.enemy_attacked.emit(m.data_of[i].id)
			m.state[i] = STATE_IDLE
			m.state_timer[i] = 0.0
		return
	m.state_timer[i] += dt
	if m.state_timer[i] >= fire_interval and target != Vector2.INF \
			and m.positions[i].distance_to(target) <= keep_max * fire_range_mul:
		m.state[i] = STATE_WINDUP
		m.state_timer[i] = windup
		m.aim[i] = (target - m.positions[i] - Vector2(0, -8)).normalized()


## Páginas BLOOD acima da cabeça durante o windup (ficha 10).
func draw_telegraph(m: EnemyManager, i: int, canvas: CanvasItem) -> void:
	if m.state[i] != STATE_WINDUP:
		return
	var p: Vector2 = m.positions[i].round() + Vector2(-3, -28)
	canvas.draw_rect(Rect2(p, Vector2(3, 4)), Palette.BLOOD)
	canvas.draw_rect(Rect2(p + Vector2(4, 0), Vector2(3, 4)), Palette.BLOOD)
