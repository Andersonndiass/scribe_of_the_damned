class_name LetterEaterBehavior
extends EnemyBehavior
## Traça Gigante (005 FR-504; 017 D-087 item 2): sem letras no chão, ela vai atrás do escriba; ao
## encostar, rouba a última letra do atril (até `max_eaten`) e foge. Ao morrer, a letra volta como
## um menu em que ela é uma das opções (cofre, não ralo).

## Folga além do contato em que a Traça alcança o atril (px).
@export var steal_radius: float = 6.0
@export var max_eaten: int = 1
@export var chase_speed_mul: float = 1.0
@export var flee_speed_mul: float = 1.2


func _init() -> void:
	needs_tick = true


func desired_velocity(m: EnemyManager, i: int, target: Vector2, _dt: float) -> Vector2:
	if m.state[i] == STATE_FLEE:
		return -ChaseBehavior.seek(m, i, target, flee_speed_mul)
	return ChaseBehavior.seek(m, i, target, chase_speed_mul)


func tick(m: EnemyManager, i: int, _dt: float) -> void:
	if m.state[i] == STATE_FLEE or m.carried[i].length() >= max_eaten:
		return
	var body: Vector2 = m.player_body()
	if m.positions[i].distance_to(body) > m.radius_of[i] + m.player_hurt_radius + steal_radius:
		return
	var field: LetterField = m.get_letter_field()
	var stolen: String = field.steal_last_letter() if field != null else ""
	if stolen == "":
		return
	m.carried[i] = m.carried[i] + stolen
	if m.carried[i].length() >= max_eaten:
		m.state[i] = STATE_FLEE


func on_death(m: EnemyManager, i: int) -> void:
	var field: LetterField = m.get_letter_field()
	if field == null:
		return
	var carried: String = m.carried[i]
	for k: int in carried.length():
		field.menu.offer(carried[k])
