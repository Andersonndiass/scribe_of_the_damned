extends GutTest
## T030–T033 EnemyManager: loop único, perseguição, separação, dano, morte e contato (FR-007, FR-008).

const DISSOLVE_SCENE := preload("res://src/enemies/dissolve_fx.tscn")
const IMP := preload("res://data/enemies/imp.tres")
const DT := 1.0 / 60.0


class FakePlayer:
	extends Node2D
	var hits: Array[int] = []

	func take_hit(amount: int, _tag: StringName = &"") -> void:
		hits.append(amount)


var _manager: EnemyManager
var _player: FakePlayer


func before_each() -> void:
	PoolManager.clear_all()
	var root := Node2D.new()
	add_child_autofree(root)
	var fx := Node2D.new()
	root.add_child(fx)
	PoolManager.register(DissolveFx.POOL_KEY, DISSOLVE_SCENE, 16, fx)
	_player = FakePlayer.new()
	_player.position = Vector2(320, 180)
	root.add_child(_player)
	_manager = EnemyManager.new()
	_manager.player = _player
	root.add_child(_manager)
	GameState.rng.seed = 7


func after_each() -> void:
	PoolManager.clear_all()


func _step(frames: int) -> void:
	for i: int in frames:
		_manager._physics_process(DT)


func test_spawn_fills_dense_slots() -> void:
	for i: int in 5:
		assert_eq(_manager.spawn(IMP, Vector2(100 + i * 20, 100)), i)
	assert_eq(_manager.count, 5)
	assert_eq(_manager.hp[0], IMP.max_hp)


func test_spawn_is_clamped_to_playable_area() -> void:
	_manager.spawn(IMP, Vector2(-100, 1000))
	assert_true(Arena.PLAYABLE.has_point(_manager.positions[0]) \
		or _manager.positions[0].is_equal_approx(Arena.PLAYABLE.end) \
		or _manager.positions[0].x == Arena.PLAYABLE.position.x)


func test_enemies_chase_the_player() -> void:
	_manager.spawn(IMP, Vector2(100, 180))
	var before: float = _manager.positions[0].distance_to(_player.position)
	_step(30)
	var after: float = _manager.positions[0].distance_to(_player.position)
	# Passos de 2 ticks (STEER_STRIDE): tolera um passo a mais ou a menos.
	assert_almost_eq(before - after, IMP.move_speed * DT * 30.0, IMP.move_speed * DT * EnemyManager.STEER_STRIDE + 0.1)


func test_separation_keeps_enemies_apart() -> void:
	for i: int in 20:
		_manager.spawn(IMP, Vector2(150, 180))
	_player.position = Vector2(150, 180)
	_step(120)
	var min_d: float = INF
	for i: int in _manager.count:
		for j: int in range(i + 1, _manager.count):
			min_d = minf(min_d, _manager.positions[i].distance_to(_manager.positions[j]))
	assert_gt(min_d, 2.0, "não ficam empilhados no mesmo pixel")


func test_damage_kills_and_swap_removes() -> void:
	var killed: Array = []
	EventBus.enemy_killed.connect(func(slot: int, _d: EnemyData, _p: Vector2) -> void: killed.append(slot))
	_manager.spawn(IMP, Vector2(100, 100))
	_manager.spawn(IMP, Vector2(200, 100))
	_manager.spawn(IMP, Vector2(300, 100))
	assert_false(_manager.damage_at(0, 1))
	assert_true(_manager.flash_left[0] > 0.0, "piscou ao levar dano")
	assert_true(_manager.damage_at(0, 10))
	assert_eq(_manager.count, 2)
	assert_eq(killed, [0])
	assert_eq(_manager.positions[0], Vector2(300, 100), "o último ocupou o slot 0")


func test_query_hit_damages_nearest_in_radius() -> void:
	_manager.spawn(IMP, Vector2(100, 100))
	assert_true(_manager.query_hit(Vector2(103, 100), 3.0, 1))
	assert_eq(_manager.hp[0], IMP.max_hp - 1)
	assert_false(_manager.query_hit(Vector2(200, 200), 3.0, 1))


func test_query_nearest() -> void:
	_manager.spawn(IMP, Vector2(100, 100))
	_manager.spawn(IMP, Vector2(150, 100))
	assert_eq(_manager.query_nearest(Vector2(140, 100), 50.0), Vector2(150, 100))
	assert_eq(_manager.query_nearest(Vector2(400, 300), 50.0), Vector2.INF)


func test_contact_hits_player_with_enemy_damage_tier() -> void:
	_manager.spawn(IMP, _player.position + EnemyManager.PLAYER_BODY_OFFSET)
	_step(1)
	assert_eq(_player.hits.size(), 1)
	assert_eq(_player.hits[0], IMP.contact_damage)


func test_dissolve_all_empties_without_reward() -> void:
	var killed: Array = []
	EventBus.enemy_killed.connect(func(slot: int, _d: EnemyData, _p: Vector2) -> void: killed.append(slot))
	for i: int in 10:
		_manager.spawn(IMP, Vector2(100 + i * 10, 100))
	_manager.dissolve_all()
	assert_eq(_manager.count, 0)
	assert_eq(killed.size(), 0, "fim de onda não dá recompensa")


func test_render_position_interpolates_between_steps() -> void:
	_manager.spawn(IMP, Vector2(100, 180))
	_step(4)
	var r: Vector2 = _manager.render_position(0)
	var a: Vector2 = _manager.prev_positions[0]
	var b: Vector2 = _manager.positions[0]
	assert_true(r.x >= minf(a.x, b.x) - 0.001 and r.x <= maxf(a.x, b.x) + 0.001, "entre o passo anterior e o atual")


func test_every_enemy_moves_within_two_ticks() -> void:
	for i: int in 6:
		_manager.spawn(IMP, Vector2(60 + i * 30, 60))
	var start: PackedVector2Array = _manager.positions.duplicate()
	_step(EnemyManager.STEER_STRIDE)
	for i: int in 6:
		assert_ne(_manager.positions[i], start[i], "inimigo %d andou" % i)


func test_aggro_point_overrides_player() -> void:
	_manager.spawn(IMP, Vector2(300, 180))
	_manager.set_aggro(Vector2(300, 60), 2.0)
	_step(30)
	assert_lt(_manager.positions[0].y, 180.0, "foi em direção à poça, não ao jogador")


func test_blind_enemy_wanders_but_still_hurts_on_contact() -> void:
	# 002 T212 / D-046: CAECITAS não persegue, mas o contato continua ferindo.
	_manager.spawn(IMP, Vector2(200, 180))
	assert_eq(_manager.blind_in_radius(Vector2(200, 180), 20.0, 2.5), 1)
	var before: float = _manager.positions[0].distance_to(_player.position)
	_step(60)
	var after: float = _manager.positions[0].distance_to(_player.position)
	assert_gt(after, before - IMP.move_speed * 0.6, "cego não fecha a distância como quem persegue")
	_manager.spawn(IMP, _player.position + EnemyManager.PLAYER_BODY_OFFSET)
	_manager.blind_in_radius(_player.position, 10.0, 2.5)
	_player.hits.clear()
	_step(1)
	assert_eq(_player.hits.size(), 1, "o cego encostado ainda fere")


func test_blindness_wears_off() -> void:
	_manager.spawn(IMP, Vector2(200, 180))
	_manager.blind_in_radius(Vector2(200, 180), 20.0, 0.5)
	_step(40)
	assert_true(_manager.blind_left[0] <= 0.0, "a cegueira acabou")
	var before: float = _manager.positions[0].distance_to(_player.position)
	_step(30)
	assert_lt(_manager.positions[0].distance_to(_player.position), before, "voltou a perseguir")


func test_hidden_player_only_seen_inside_the_cloud() -> void:
	_manager.spawn(IMP, Vector2(100, 180))  # fora da nuvem
	_manager.spawn(IMP, Vector2(300, 180))  # dentro da nuvem
	var before_out: float = _manager.positions[0].distance_to(_player.position)
	var before_in: float = _manager.positions[1].distance_to(_player.position)
	for i: int in 60:
		_manager.hide_player(_player.position, 40.0, 0.1)
		_step(1)
	assert_true(_manager.is_player_hidden())
	assert_gt(_manager.positions[0].distance_to(_player.position), before_out - IMP.move_speed * 0.6, "fora: perdeu o escriba")
	assert_lt(_manager.positions[1].distance_to(_player.position), before_in, "dentro: ainda persegue")


func test_requiem_step_guarantees_drops_up_to_cap() -> void:
	var drops: Array[bool] = []
	var on_kill := func(slot: int, _d: EnemyData, _p: Vector2) -> void:
		drops.append(_manager.guaranteed_drop[slot] == 1)
	EventBus.enemy_killed.connect(on_kill)
	for i: int in 5:
		_manager.spawn(IMP, Vector2(100 + i * 20, 100))
	var r: Vector2i = _manager.requiem_step(_manager.count - 1, 30, 5, 20, 3)
	EventBus.enemy_killed.disconnect(on_kill)
	assert_eq(r.x, -1, "acabou")
	assert_eq(r.y, 0, "gastou o teto")
	assert_eq(_manager.count, 0)
	assert_eq(drops.count(true), 3, "só 3 com letra garantida")
