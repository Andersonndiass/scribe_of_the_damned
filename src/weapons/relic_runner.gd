class_name RelicRunner
extends Node2D
## Roda as relíquias equipadas (D-103; mechanics-agent 019), filho do Player (criado no _ready,
## nunca na onda). Tempo de jogo (`_physics_process`: pausa, loja e selos congelam). Por gatilho:
##   pulse  (Ímã, Sino): pronto a cada `interval`; sem ninguém no raio espera pronto; empurra/fere
##          (EnemyManager.repulse) ou atordoa (stun_pulse).
##   aura   (Sal Bento): a cada `interval` (tique) aplica lentidão no raio (slow_aura).
##   on_hit (Relicário): ao perder vela, se pronto, explode (repulse com dano) e dá invulnerabilidade.
##   shield (Selo de Cera): recarrega 1 carga por `interval` até o máximo; `absorb_hit()` gasta.
## Visual: anel que cresce até o raio (como o ímã, VFX_REPEL_WAVE) e o aro da aura; abaixo dos inimigos.

const BODY := Vector2(0, -4)
const WAVE_TIME := 0.25
const RING := 3
const TUNING := preload("res://data/tuning/relics.tres")

var player: Node2D
var _wave_left := PackedFloat32Array([0.0, 0.0])
var _wave_radius := PackedFloat32Array([0.0, 0.0])
var _wave_hurts: Array[bool] = [false, false]


func _ready() -> void:
	top_level = true
	z_index = -1
	if player == null:
		player = get_parent() as Node2D
	EventBus.player_damaged.connect(_on_player_damaged)


func _slots() -> Array[RelicSlot]:
	var lo: Loadout = GameState.loadout
	return lo.relics if lo != null else ([] as Array[RelicSlot])


func _em() -> EnemyManager:
	return EnemyQuery.provider as EnemyManager


func _physics_process(delta: float) -> void:
	var redraw: bool = false
	for i: int in _wave_left.size():
		if _wave_left[i] > 0.0:
			_wave_left[i] -= delta
			redraw = true
	if player == null:
		return
	global_position = (player.global_position + BODY).round()
	var slots: Array[RelicSlot] = _slots()
	for i: int in slots.size():
		var rs: RelicSlot = slots[i]
		if rs == null:
			continue
		var s: RelicLevelData = rs.stats()
		match rs.relic.trigger:
			&"pulse":
				_tick_pulse(i, rs, s, delta)
			&"aura":
				redraw = true
				rs.charge = 1.0
				rs.timer += delta
				if rs.timer >= s.interval:
					rs.timer -= s.interval
					var em: EnemyManager = _em()
					if em != null:
						em.slow_aura(global_position, s.radius, s.slow_factor, s.slow_time)
			&"on_hit":
				rs.timer = minf(rs.timer + delta, s.interval)
				rs.charge = rs.timer / s.interval
			&"shield":
				_tick_shield(i, rs, s, delta)
	if redraw:
		queue_redraw()


func _tick_pulse(i: int, rs: RelicSlot, s: RelicLevelData, delta: float) -> void:
	rs.timer = minf(rs.timer + delta, s.interval)
	rs.charge = rs.timer / s.interval
	if rs.timer < s.interval:
		return
	var em: EnemyManager = _em()
	if em == null:
		return
	var center: Vector2 = global_position
	if rs.relic.hold_when_empty and em.query_nearest(center, s.radius) == Vector2.INF:
		return
	rs.timer = 0.0
	var hits: int = 0
	if rs.relic.effect == &"stun":
		hits = em.stun_pulse(center, s.radius, s.stun, rs.relic.champion_mul)
	else:
		hits = em.repulse(center, s.radius, s.knockback, rs.relic.champion_mul, s.damage)
	_wave(i, s.radius, s.damage > 0)
	EventBus.relic_pulsed.emit(i, rs.relic.id, center, s.radius, hits)


func _tick_shield(i: int, rs: RelicSlot, s: RelicLevelData, delta: float) -> void:
	if rs.charges >= s.charges:
		rs.timer = 0.0
		rs.charge = 1.0
		return
	rs.timer += delta
	rs.charge = rs.timer / s.interval
	if rs.timer >= s.interval:
		rs.timer = 0.0
		rs.charges += 1
		EventBus.relic_shield_changed.emit(i, rs.charges, s.charges)


## Selo de Cera: gasta 1 carga e devolve o espaço; −1 se nenhuma relíquia de escudo tem carga.
func absorb_hit() -> int:
	var slots: Array[RelicSlot] = _slots()
	for i: int in slots.size():
		var rs: RelicSlot = slots[i]
		if rs != null and rs.relic.effect == &"absorb" and rs.charges > 0:
			rs.charges -= 1
			EventBus.relic_shield_changed.emit(i, rs.charges, rs.stats().charges)
			return i
	return -1


## Relicário: perdeu vela (e continua vivo) → explode em volta se pronto.
func _on_player_damaged(_amount: int, candles: int) -> void:
	if candles <= 0 or player == null:
		return
	var slots: Array[RelicSlot] = _slots()
	for i: int in slots.size():
		var rs: RelicSlot = slots[i]
		if rs == null or rs.relic.effect != &"burst":
			continue
		var s: RelicLevelData = rs.stats()
		if rs.timer < s.interval:
			continue
		rs.timer = 0.0
		var em: EnemyManager = _em()
		var hits: int = 0
		if em != null:
			hits = em.repulse(global_position, s.radius, s.knockback, rs.relic.champion_mul, s.damage)
		var vitals: Variant = player.get(&"vitals")
		if vitals != null and s.iframes_bonus > 0.0:
			vitals.iframes_left = minf(vitals.iframes_left + s.iframes_bonus, TUNING.max_iframes)
		_wave(i, s.radius, true)
		EventBus.relic_pulsed.emit(i, rs.relic.id, global_position, s.radius, hits)


func _wave(i: int, radius: float, hurts: bool) -> void:
	if i >= _wave_left.size():
		return
	_wave_left[i] = WAVE_TIME
	_wave_radius[i] = radius
	_wave_hurts[i] = hurts
	queue_redraw()


func _draw() -> void:
	for i: int in _wave_left.size():
		if _wave_left[i] <= 0.0:
			continue
		var t: float = 1.0 - _wave_left[i] / WAVE_TIME
		var r: int = maxi(RING + 1, roundi(_wave_radius[i] * t))
		if _wave_hurts[i]:
			UiStyle.ring(self, Vector2.ZERO, r + 1, Palette.INK, 1)
		UiStyle.ring(self, Vector2.ZERO, r, Palette.INK_SOFT, RING)
	for rs: RelicSlot in _slots():
		if rs != null and rs.relic.effect == &"slow":
			UiStyle.ring(self, Vector2.ZERO, roundi(rs.stats().radius), Palette.INK_SOFT, 1)  # o aro do Sal
