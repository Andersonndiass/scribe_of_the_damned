class_name BossAttack
extends Node2D
## Executor de um ataque de chefe (006 FR-608, T611). Pré-instanciado com o chefe (nunca durante
## a luta). Desenha em coordenadas globais (top_level): a mira trava no começo da telegrafia.
## Telegrafia (animation-agent): tracejado BLOOD que pisca a 100 ms nos 2/3 iniciais e a 50 ms no
## terço final, sólido no último quadro. Golpe (design-agent): sem BLOOD (só o fogo da F3).

const BLINK_SLOW := 0.1
const BLINK_FAST := 0.05
const DASH := 4
const HIT_STOP_MS := 60
const SHAKE_MEDIUM := 2.0
const SHAKE_MEDIUM_TIME := 0.4

var attack: AttackData
var boss: Boss
## O golpe acertou o escriba nesta ativação (Raio/Swipe que erram abrem a exposição).
var hit_player: bool = false

var _t: float = 0.0
var _stage: StringName = &"off"


func _ready() -> void:
	top_level = true
	z_index = 2
	visible = false


func begin(p_attack: AttackData, p_boss: Boss) -> void:
	attack = p_attack
	boss = p_boss
	hit_player = false
	_t = 0.0
	_stage = &"telegraph"
	global_position = Vector2.ZERO
	EventBus.boss_attack_telegraphed.emit(attack.kind)
	_on_begin()
	visible = true
	queue_redraw()


func activate() -> void:
	_stage = &"active"
	_t = 0.0
	EventBus.boss_attack_started.emit(attack.kind)
	_on_activate()
	queue_redraw()


func finish() -> void:
	if _stage != &"off" and attack != null:
		EventBus.boss_attack_finished.emit(attack.kind)
	_stage = &"off"
	visible = false


func cancel() -> void:
	finish()


func is_telegraphing() -> bool:
	return _stage == &"telegraph"


func is_active() -> bool:
	return _stage == &"active"


func _physics_process(delta: float) -> void:
	if _stage == &"off":
		return
	_t += delta
	if _stage == &"active":
		_active_tick(delta)
	queue_redraw()


## A telegrafia está acesa neste instante?
func telegraph_on() -> bool:
	var total: float = attack.telegraph
	if _t >= total - 1.0 / 60.0:
		return true
	var period: float = BLINK_SLOW if _t < total * 2.0 / 3.0 else BLINK_FAST
	return int(_t / period) % 2 == 0


func player_body() -> Vector2:
	return boss.manager.player_body()


## Fere o escriba (i-frames do escriba impedem o golpe repetido).
func hurt_player(amount: int) -> void:
	hit_player = true
	if amount <= 0 or boss.player == null:
		return
	boss.player.take_hit(amount, &"boss")
	if amount >= 2:
		EventBus.hitstop_requested.emit(HIT_STOP_MS)
		EventBus.shake_requested.emit(SHAKE_MEDIUM, SHAKE_MEDIUM_TIME)


## Distância do escriba ao segmento a→b.
func distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	return Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p)


func dashed_line(a: Vector2, b: Vector2, color: Color) -> void:
	var len: float = a.distance_to(b)
	var d: Vector2 = (b - a) / maxf(len, 0.001)
	var x: float = 0.0
	while x < len:
		draw_line((a + d * x).round(), (a + d * minf(x + DASH, len)).round(), color, 1.0)
		x += DASH * 2


# --- sobrescrever ---
func _on_begin() -> void:
	pass


func _on_activate() -> void:
	pass


func _active_tick(_delta: float) -> void:
	pass
