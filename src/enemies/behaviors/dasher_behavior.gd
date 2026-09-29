class_name DasherBehavior
extends EnemyBehavior
## Gárgula-Marginália (005 FR-505): anda até `trigger_range`, telegrafa por `windup` s com linha
## tracejada BLOOD e dá um dash reto. A direção é TRAVADA no início do windup (esquivável;
## parecer do rules-agent). Depois, cooldown. Contato forte só no dash (EnemyData.dash_contact_damage).

@export var trigger_range: float = 90.0
@export var windup: float = 0.6
@export var dash_speed: float = 220.0
@export var dash_time: float = 0.5
@export var cooldown: float = 2.5
## Velocidade de aproximação durante o cooldown (fração da normal).
@export var cooldown_speed_mul: float = 0.5


func _init() -> void:
	needs_tick = true


func desired_velocity(m: EnemyManager, i: int, target: Vector2, _dt: float) -> Vector2:
	match m.state[i]:
		STATE_WINDUP:
			return Vector2.ZERO
		STATE_DASH:
			# O dash para na borda da peça (004, rules-agent: todas param a Gárgula).
			if ObstacleQuery.stops_dash_at(m.positions[i] + m.aim[i] * dash_speed * _dt, m.radius_of[i]):
				m.state[i] = STATE_COOLDOWN
				m.state_timer[i] = cooldown
				return Vector2.ZERO
			return m.aim[i] * dash_speed
		STATE_COOLDOWN:
			return ChaseBehavior.seek(m, i, target, cooldown_speed_mul)
	if target != Vector2.INF and m.positions[i].distance_to(target) <= trigger_range:
		m.state[i] = STATE_WINDUP
		m.state_timer[i] = windup
		m.aim[i] = (target - m.positions[i]).normalized()
		return Vector2.ZERO
	return ChaseBehavior.seek(m, i, target)


func tick(m: EnemyManager, i: int, dt: float) -> void:
	if m.state[i] == STATE_IDLE:
		return
	m.state_timer[i] -= dt
	if m.state_timer[i] > 0.0:
		return
	match m.state[i]:
		STATE_WINDUP:
			m.state[i] = STATE_DASH
			m.state_timer[i] = dash_time
		STATE_DASH:
			m.state[i] = STATE_COOLDOWN
			m.state_timer[i] = cooldown
		STATE_COOLDOWN:
			m.state[i] = STATE_IDLE


## Linha tracejada BLOOD na direção travada, do tamanho do dash (ficha 09: obrigatória).
func draw_telegraph(m: EnemyManager, i: int, canvas: CanvasItem) -> void:
	if m.state[i] != STATE_WINDUP:
		return
	var from: Vector2 = m.positions[i].round()
	# O caminho mostrado já vem cortado pela peça em que o dash vai parar.
	var length: float = ObstacleQuery.clip_segment(from, m.aim[i], dash_speed * dash_time, m.radius_of[i])
	var dash: float = 4.0
	var t: float = 0.0
	while t < length:
		canvas.draw_line(from + m.aim[i] * t, from + m.aim[i] * minf(t + dash, length), Palette.BLOOD, 1.0)
		t += dash * 2.0
