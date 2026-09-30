extends GutTest
## T1640 Pingo de cera (016 FR-1615, SC-1604): cai de inimigo comum com a chance do dado, nunca de
## campeão; pisar acende vela; com as velas cheias fica e balança; some com o tempo; pool com teto;
## o fim da onda limpa o chão. O Main liga o pingo com a Graça (meta "grace_manual").

const MAIN_SCENE := preload("res://src/main/main.tscn")
const IMP := preload("res://data/enemies/imp.tres")

var _main: Node2D
var _field: WaxDropField
var _player: Player
var _sure: EnemyData


func before_each() -> void:
	_main = MAIN_SCENE.instantiate()
	_main.set_meta(&"grace_manual", true)
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	(_main.get_node("World/EnemyManager") as EnemyManager).dissolve_all()
	_field = _main.get_node("World/WaxDropField")
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_player.vitals.iframes_left = 1.0e6
	_sure = IMP.duplicate()
	_sure.wax_drop_chance = 1.0


func test_chance_comes_from_the_enemy_data() -> void:
	EventBus.enemy_killed.emit(-1, _sure, Vector2(100, 100))
	assert_eq(_field.active_count(), 1, "chance 1: cai")
	var never: EnemyData = IMP.duplicate()
	never.wax_drop_chance = 0.0
	EventBus.enemy_killed.emit(-1, never, Vector2(120, 100))
	assert_eq(_field.active_count(), 1, "chance 0: não cai")
	assert_almost_eq(IMP.wax_drop_chance, 0.01, 0.0001, "1% (rules-agent)")


func test_champions_never_drop_wax() -> void:
	var em: EnemyManager = _main.get_node("World/EnemyManager")
	var slot: int = em.spawn(_sure, Vector2(200, 200), true)
	EventBus.enemy_killed.emit(slot, _sure, Vector2(200, 200))
	assert_eq(_field.active_count(), 0, "o campeão já dá vela")


func test_stepping_on_it_lights_a_candle() -> void:
	var got: Array = []
	var on_got := func(p: Vector2) -> void: got.append(p)
	EventBus.wax_drop_collected.connect(on_got)
	_player.vitals.candles = 1
	_field.drop(_player.global_position + WaxDropField.PLAYER_BODY_OFFSET)
	await wait_seconds(_field.tuning.pickup_lock + _field.tuning.collect_time + 0.15)
	EventBus.wax_drop_collected.disconnect(on_got)
	assert_eq(_player.vitals.candles, 2)
	assert_eq(got.size(), 1)
	assert_eq(_field.active_count(), 0)


func test_full_candles_keep_it_on_the_floor() -> void:
	_player.vitals.candles = _player.vitals.max_candles
	var w: WaxDrop = _field.drop(_player.global_position + WaxDropField.PLAYER_BODY_OFFSET)
	await wait_seconds(_field.tuning.pickup_lock + 0.1)
	assert_eq(_field.active_count(), 1, "fica guardado")
	assert_true(w.rejected, "balançou")


func test_it_expires_and_the_pool_has_a_cap() -> void:
	for i: int in 5:
		_field.drop(Vector2(100 + i * 20, 300))
	assert_eq(_field.active_count(), _field.tuning.pool_size, "no máximo 3 no chão")
	var before: int = PoolManager.instantiate_count
	_field.drop(Vector2(400, 300))
	assert_eq(PoolManager.instantiate_count, before, "nunca instancia na onda")
	for w: WaxDrop in _field.get("_active"):
		w.life = 0.05
	await wait_seconds(0.15)
	assert_eq(_field.active_count(), 0, "sumiram")


func test_wave_end_clears_the_floor() -> void:
	_field.drop(Vector2(300, 300))
	EventBus.wave_ended.emit(1)
	assert_eq(_field.active_count(), 0)
