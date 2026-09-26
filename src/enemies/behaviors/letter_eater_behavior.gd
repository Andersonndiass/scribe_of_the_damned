class_name LetterEaterBehavior
extends EnemyBehavior
## Traça Gigante (005 FR-504): vai até a letra no chão mais próxima (menos as que o ímã já puxa),
## marca a letra-alvo, leva `eat_time` s para comer, come no máximo `max_eaten` e então foge do
## jogador. Ao morrer, devolve ao chão as letras que comeu (cofre, não ralo).

@export var seek_radius: float = 160.0
@export var eat_radius: float = 6.0
@export var eat_time: float = 0.4
@export var max_eaten: int = 1
## Sem letra por perto: aproxima-se do jogador a esta fração da velocidade.
@export var idle_speed_mul: float = 0.4
@export var flee_speed_mul: float = 1.2


func _init() -> void:
	needs_tick = true


func desired_velocity(m: EnemyManager, i: int, target: Vector2, _dt: float) -> Vector2:
	match m.state[i]:
		STATE_EATING:
			return Vector2.ZERO
		STATE_FLEE:
			return -ChaseBehavior.seek(m, i, target, flee_speed_mul)
	var field: LetterField = m.get_letter_field()
	var letter: Letter = field.nearest_edible(m.positions[i], seek_radius) if field != null else null
	if letter == null:
		return ChaseBehavior.seek(m, i, target, idle_speed_mul)
	letter.moth_mark = 0.2
	if m.positions[i].distance_to(letter.global_position) <= eat_radius:
		m.state[i] = STATE_EATING
		m.state_timer[i] = eat_time
		m.aim[i] = letter.global_position
		letter.lock_left = maxf(letter.lock_left, eat_time)
		return Vector2.ZERO
	var to: Vector2 = letter.global_position - m.positions[i]
	return to.normalized() * m.data_of[i].move_speed * m.slow_factor[i] * m.speed_mul[i]


func tick(m: EnemyManager, i: int, dt: float) -> void:
	if m.state[i] != STATE_EATING:
		return
	m.state_timer[i] -= dt
	if m.state_timer[i] > 0.0:
		return
	var field: LetterField = m.get_letter_field()
	var eaten: String = field.eat_letter_near(m.aim[i], eat_radius) if field != null else ""
	if eaten != "":
		m.carried[i] = m.carried[i] + eaten
	m.state[i] = STATE_FLEE if m.carried[i].length() >= max_eaten else STATE_IDLE


func on_death(m: EnemyManager, i: int) -> void:
	var field: LetterField = m.get_letter_field()
	if field == null:
		return
	var carried: String = m.carried[i]
	for k: int in carried.length():
		field.spawn_letter(carried[k], false, false, m.positions[i] + Vector2(k * 8, 0))
