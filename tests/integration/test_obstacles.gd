extends GutTest
## T412 Obstáculos na cena principal (004 FR-410, FR-411; SC-406): inimigo do outro lado de cada
## peça contorna e chega ao escriba; nada nasce nem cai dentro (10 mil sorteios); contato através
## do banco não fere; o dash da Gárgula para na borda; o tiro do Monge para no vitral.

const MAIN_SCENE := preload("res://src/main/main.tscn")
const IMP := preload("res://data/enemies/imp.tres")
const GARGOYLE := preload("res://data/enemies/gargoyle.tres")
const PAGE_SHOT := preload("res://data/projectiles/prj_page.tres")
const DT := 1.0 / 60.0
## Até 12 s de simulação para contornar uma peça.
const MAX_TICKS := 720
const WALK := ObstacleTypeData.Block.WALK

var _main: Node2D
var _player: Player
var _m: EnemyManager
var _field: LetterField


func before_each() -> void:
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_player.vitals.iframes_left = 1.0e6
	_player.set_physics_process(false)
	_field = _main.get_node("World/LetterField")
	_m = _main.get_node("World/EnemyManager")
	_m.dissolve_all()
	_m.set_physics_process(false)


## Simula o gerenciador tick a tick; devolve em quantos ticks o slot 0 encostou no escriba (-1 = nunca).
func _run_until_touch(max_ticks: int) -> int:
	var body: Vector2 = _player.global_position + EnemyManager.PLAYER_BODY_OFFSET
	for t: int in max_ticks:
		_m._physics_process(DT)
		var p: Vector2 = _m.positions[0]
		assert_true(ObstacleQuery.is_free(p, _m.radius_of[0] - 0.5), "nunca dentro da peça (%s)" % p)
		if p.distance_to(body) <= _m.radius_of[0] + _m.player_hurt_radius + 1.0:
			return t
	return -1


func test_enemy_goes_around_every_obstacle() -> void:
	# Inimigo e escriba em lados opostos, na reta que passa pelo meio da peça (o pior caso).
	var cases: Array[Array] = [
		[Vector2(40, 80), Vector2(120, 84)],     # furo de cima à esquerda, na horizontal
		[Vector2(80, 44), Vector2(80, 124)],     # o mesmo furo, na vertical
		[Vector2(600, 280), Vector2(520, 284)],  # furo de baixo à direita
		[Vector2(34, 140), Vector2(34, 224)],    # vitral encostado na parede esquerda
		[Vector2(586, 150), Vector2(586, 214)],  # altar encostado na parede direita
		[Vector2(90, 330), Vector2(150, 334)],   # banco encostado embaixo
	]
	for c: Array in cases:
		_m.dissolve_all()
		_player.global_position = c[1]
		_m.spawn(IMP, c[0])
		var ticks: int = _run_until_touch(MAX_TICKS)
		assert_gt(ticks, 0, "de %s chega ao escriba em %s" % [c[0], c[1]])


func test_nothing_spawns_or_falls_inside() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var map: ObstacleMap = ObstacleQuery.map
	for k: int in 10000:
		var p := Vector2(rng.randf_range(24, 616), rng.randf_range(24, 336))
		var drop: Vector2 = ObstacleQuery.drop_point(p)
		if not map.is_free(drop, map.drop_margin):
			fail_test("letra/tinta dentro da peça: %s → %s" % [p, drop])
			return
		var r: float = rng.randf_range(4.0, 9.0)
		var spawn: Vector2 = ObstacleQuery.spawn_point(p, r)
		if not map.is_free(spawn, r + map.spawn_clearance):
			fail_test("nascimento dentro da peça: %s → %s (r %s)" % [p, spawn, r])
			return
	pass_test("10 mil sorteios fora das peças")


func test_real_spawns_and_letters_are_pushed_out() -> void:
	var hole := Vector2(80, 80)
	var slot: int = _m.spawn(IMP, hole)
	assert_true(ObstacleQuery.is_free(_m.positions[slot], IMP.radius), "inimigo nasce fora do furo")
	_player.global_position = Vector2(560, 300)
	var l: Letter = _field.spawn_letter("A", false, false, hole)
	assert_true(ObstacleQuery.is_free(l.global_position, ObstacleQuery.map.drop_margin), "letra fora do furo")
	assert_eq(_field.active_count(), 1, "a letra não é descartada")


func test_contact_does_not_cross_a_bench() -> void:
	# Banco solto no meio (o do Cap. 1 encosta na parede): inimigo e escriba colados, um de cada lado.
	var arena := ArenaData.new()
	var o := ObstacleData.new()
	o.type = load("res://data/arena/obstacle_types/bench.tres")
	o.position = Vector2i(300, 200)
	arena.obstacles = [o]
	(_main.get_node("Arena") as Arena).load_page(arena)
	var body := Vector2(316, 207)
	var slot: int = _m.spawn(IMP, Vector2(316, 150))
	_m.positions[slot] = Vector2(316, 199)
	_m.prev_positions[slot] = _m.positions[slot]
	assert_false(_m._touches_player(slot, body), "o banco separa")
	ObstacleQuery.map = ObstacleMap.from_arena(null, false)
	assert_true(_m._touches_player(slot, body), "sem o banco, encosta")


func test_gargoyle_dash_stops_at_the_edge() -> void:
	_player.global_position = Vector2(130, 84)
	var slot: int = _m.spawn(GARGOYLE, Vector2(44, 80))
	var hole: Rect2 = Rect2(72, 72, 16, 16)
	var dashed: bool = false
	var stop_x: float = INF
	for t: int in 120:
		_m._physics_process(DT)
		if _m.state[slot] == EnemyBehavior.STATE_DASH:
			dashed = true
		elif dashed and stop_x == INF:
			stop_x = _m.positions[slot].x
		assert_false(hole.grow(_m.radius_of[slot] - 0.5).has_point(_m.positions[slot]), "não atravessa o furo")
	assert_true(dashed, "a Gárgula deu o dash")
	# Sem o furo, o dash (110 px) a levaria de x=44 até além de x=130.
	assert_lt(stop_x, 72.0, "o dash acabou na borda do furo")


func test_gargoyle_telegraph_is_clipped() -> void:
	var dasher: DasherBehavior = GARGOYLE.behavior
	var full: float = dasher.dash_speed * dasher.dash_time
	var clipped: float = ObstacleQuery.clip_segment(Vector2(44, 80), Vector2.RIGHT, full, GARGOYLE.radius)
	assert_lt(clipped, 72.0 - 44.0, "a linha para no furo")
	assert_gt(clipped, 0.0)


func test_monk_shot_stops_at_the_window() -> void:
	var shots: EnemyProjectileManager = _main.get_node("World/EnemyProjectiles")
	_player.global_position = Vector2(560, 300)
	shots.fire(PAGE_SHOT, Vector2(90, 180), Vector2.LEFT)
	# 90 px/s: da x=90 até a borda do vitral (x=44) leva ~0,5 s; a página só acabaria em x=0 (1 s).
	await wait_seconds(0.7)
	assert_eq(shots.count, 0, "o vitral parou o tiro")
