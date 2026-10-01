class_name RepulseAura
extends Node2D
## Ímã reverso (017 FR-1712, T1734; rules-agent T1700 §6): com o passivo comprado
## (`GameState.repulse_level` > 0), a cada `intervals[nível]` s de jogo empurra os inimigos em volta
## do escriba e, a partir do nível 3, fere. Sem ninguém no raio, o pulso espera pronto.
## Visual (design-agent VFX_REPEL_WAVE): anel INK_SOFT de 3 px que cresce até o raio (+1 px INK
## quando o nível fere), abaixo dos inimigos.

const BODY := Vector2(0, -4)
const WAVE_TIME := 0.25
const RING := 3

var player: Node2D
var _timer: float = 0.0
var _wave_left: float = 0.0
var _wave_radius: float = 0.0
var _wave_hurts: bool = false


func _ready() -> void:
	top_level = true
	z_index = -1
	if player == null:
		player = get_parent() as Node2D


func _physics_process(delta: float) -> void:
	if _wave_left > 0.0:
		_wave_left -= delta
		queue_redraw()
	var level: int = GameState.repulse_level
	if level <= 0 or player == null:
		return
	var data: RepulseData = GameState.repulse
	var interval: float = data.at(data.intervals, level)
	_timer = minf(_timer + delta, interval)
	if _timer < interval:
		return
	var center: Vector2 = player.global_position + BODY
	var radius: float = data.at(data.radii, level)
	var em := EnemyQuery.provider as EnemyManager
	if em == null:
		return
	if data.hold_when_empty and em.query_nearest(center, radius) == Vector2.INF:
		return
	_timer = 0.0
	var damage: int = data.at(data.damages, level)
	var pushed: int = em.repulse(center, radius, data.at(data.knockbacks, level), data.champion_knockback_mul, damage)
	_wave_left = WAVE_TIME
	_wave_radius = radius
	_wave_hurts = damage > 0
	global_position = center.round()
	EventBus.repulse_pulsed.emit(center, radius, level, pushed)


func _draw() -> void:
	if _wave_left <= 0.0:
		return
	var t: float = 1.0 - _wave_left / WAVE_TIME
	var r: int = maxi(RING + 1, roundi(_wave_radius * t))
	if _wave_hurts:
		UiStyle.ring(self, Vector2.ZERO, r + 1, Palette.INK, 1)
	UiStyle.ring(self, Vector2.ZERO, r, Palette.INK_SOFT, RING)
