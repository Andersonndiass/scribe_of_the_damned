class_name TrailBehavior
extends EnemyBehavior
## Borrão de Tinta (005 FR-507): persegue devagar e deixa uma poça de lentidão a cada
## trail_interval s; ao morrer, deixa uma poça.

@export var trail_interval: float = 2.5
@export var puddle: PuddleData


func _init() -> void:
	needs_tick = true


func tick(m: EnemyManager, i: int, dt: float) -> void:
	m.state_timer[i] += dt
	if m.state_timer[i] >= trail_interval:
		m.state_timer[i] = 0.0
		_drop(m, i)


func on_death(m: EnemyManager, i: int) -> void:
	_drop(m, i)


func _drop(m: EnemyManager, i: int) -> void:
	var h: HazardField = m.get_hazards()
	if h != null and puddle != null:
		h.add_puddle(puddle, m.positions[i])
