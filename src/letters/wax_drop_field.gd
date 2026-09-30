class_name WaxDropField
extends Node2D
## Pingos de cera no chão (016 FR-1615): em pool, soltos raramente por inimigo comum (campeão já
## dá vela), pisar acende velas; com as velas cheias o pingo fica e balança. Sorteio no RNG da
## Graça (não mexe nas letras). Fim da onda e começo do chefe limpam o chão.

const PLAYER_BODY_OFFSET := Vector2(0, -6)

@export var player: Player
@export var manager: EnemyManager
var tuning: WaxDropTuning = preload("res://data/tuning/wax_drop.tres")
## Desligado fora do jogo de verdade (como a Graça): testes antigos não ganham velas por acaso.
var active: bool = true

var _active: Array[WaxDrop] = []


func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.wave_ended.connect(func(_i: int) -> void: clear())
	EventBus.boss_spawned.connect(func(_b: BossData) -> void: clear())


func active_count() -> int:
	return _active.size()


func _on_enemy_killed(slot: int, data: EnemyData, pos: Vector2) -> void:
	if not active or data.wax_drop_chance <= 0.0:
		return
	# O sinal sai antes do swap-remove: o slot ainda é o do morto.
	if manager != null and slot >= 0 and slot < manager.count and manager.champion[slot] == 1:
		return
	if GameState.grace_rng.randf() >= data.wax_drop_chance:
		return
	drop(pos)


## Solta um pingo em `pos` (acima do teto do pool ele não aparece: nunca instancia na onda).
func drop(pos: Vector2) -> WaxDrop:
	var w := PoolManager.try_acquire(WaxDrop.POOL_KEY) as WaxDrop
	if w == null:
		return null
	w.start(ObstacleQuery.drop_point(pos), tuning)
	_active.append(w)
	return w


func clear() -> void:
	for w: WaxDrop in _active:
		PoolManager.release(w)
	_active.clear()


func _physics_process(delta: float) -> void:
	if _active.is_empty():
		return
	var body: Vector2 = player.global_position + PLAYER_BODY_OFFSET if player != null else Vector2.INF
	for idx: int in range(_active.size() - 1, -1, -1):
		var w: WaxDrop = _active[idx]
		w.tick(delta)
		if w.collecting >= 0.0:
			if w.collecting >= w.tuning.collect_time:
				_release(idx)
			continue
		if w.life <= 0.0:
			_release(idx)
			continue
		var on_top: bool = w.global_position.distance_to(body) <= tuning.pickup_radius
		if not on_top:
			w.rejected = false
			continue
		if not w.can_pick():
			continue
		if player.vitals.candles >= player.vitals.max_candles:
			# Velas cheias: fica guardado; balança uma vez por entrada.
			if not w.rejected:
				w.rejected = true
				w.shake_left = tuning.reject_shake
			continue
		player.heal(tuning.heal_candles)
		w.collecting = 0.0
		EventBus.wax_drop_collected.emit(w.global_position)


func _release(idx: int) -> void:
	var w: WaxDrop = _active[idx]
	_active[idx] = _active[_active.size() - 1]
	_active.pop_back()
	PoolManager.release(w)
