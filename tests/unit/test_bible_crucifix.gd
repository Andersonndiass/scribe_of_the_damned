extends GutTest
## 017 T1714–T1715: a Bíblia liga o raio enquanto é a ativa (D-087 item 5), segue a mira presa a
## 32 direções e desliga na troca; o Crucifixo antecipa 0,2 s dentro do intervalo (0,8 s no nv 1; T1820), a troca
## no meio cancela sem gastar a recarga; a cruz atravessa a fila e fere cada um uma vez.

const PEN := preload("res://data/weapons/pen.tres")
const BIBLE := preload("res://data/weapons/bible.tres")
const CRUCIFIX := preload("res://data/weapons/crucifix.tres")
const IMP := preload("res://data/enemies/imp.tres")
const DISSOLVE_SCENE := preload("res://src/enemies/dissolve_fx.tscn")
const DT := 1.0 / 60.0


class FakeEnemies:
	extends RefCounted
	var target: Vector2 = Vector2(100, 0)

	func query_nearest(pos: Vector2, radius: float) -> Vector2:
		return target if pos.distance_to(target) <= radius else Vector2.INF

	func query_hit(_pos: Vector2, _radius: float, _damage: int) -> bool:
		return false


var _origin: Node2D
var _arsenal: Arsenal
var _proj: PlayerProjectileManager
var _shots: int = 0
var _was_mouse: bool
var _was_point: Vector2


func before_each() -> void:
	_shots = 0
	_was_mouse = GameState.aim_with_mouse
	_was_point = GameState.aim_point
	WeaponZones.clear()
	_origin = Node2D.new()
	add_child_autofree(_origin)
	_proj = PlayerProjectileManager.new()
	_origin.add_child(_proj)
	_proj.set_physics_process(false)
	_arsenal = Arsenal.new()
	_arsenal.projectiles = _proj
	_origin.add_child(_arsenal)
	_arsenal.set_physics_process(false)
	EnemyQuery.provider = FakeEnemies.new()
	_arsenal.fired.connect(func(_t: Vector2) -> void: _shots += 1)


func after_each() -> void:
	EnemyQuery.provider = null
	WeaponZones.clear()
	GameState.aim_with_mouse = _was_mouse
	GameState.aim_point = _was_point


func _run(seconds: float) -> void:
	for k: int in roundi(seconds / DT):
		_arsenal._physics_process(DT)


func test_new_weapons_are_valid_data() -> void:
	assert_eq(BIBLE.validate(), "")
	assert_eq(CRUCIFIX.validate(), "")
	var top := WeaponSlot.new(BIBLE)
	for k: int in 4:
		top.rank_up(&"rate")
	assert_almost_eq(top.stats().interval, 0.42, 0.0001, "T1830: cadência no teto, 0,42 s")
	assert_eq(CRUCIFIX.base.speed, 360.0)
	assert_eq(CRUCIFIX.base.pierce, 8)


func test_bible_beam_is_on_while_active_and_follows_the_aim() -> void:
	_arsenal.loadout = Loadout.new(2, BIBLE)
	_arsenal.loadout.equip(PEN)
	GameState.aim_with_mouse = true
	GameState.aim_point = _origin.global_position + BIBLE.muzzle + Vector2(0, 100)
	_run(DT)
	assert_true(_arsenal.beam.on, "sempre ligada quando ativa")
	assert_true(WeaponZones.active().has(_arsenal.beam.zone))
	assert_almost_eq(_arsenal.beam.zone.dir.angle(), PI / 2.0, 0.001, "mira para baixo")
	assert_almost_eq(_arsenal.beam.zone.length, 100.0, 0.001, "D-098: chega até o cursor")
	assert_eq(_arsenal.beam.zone.max_targets, 2)
	GameState.aim_point = _origin.global_position + BIBLE.muzzle + Vector2(100, 5)
	_run(DT)
	assert_almost_eq(_arsenal.beam.zone.dir.angle(), 0.0, 0.001, "presa a 32 direções")
	GameState.aim_point = _origin.global_position + BIBLE.muzzle + Vector2(900, 0)
	_run(DT)
	assert_eq(_arsenal.beam.zone.length, 200.0, "longe: para no alcance do nível")
	GameState.aim_point = _origin.global_position + BIBLE.muzzle + Vector2(5, 0)
	_run(DT)
	assert_eq(_arsenal.beam.zone.length, BIBLE.beam_min_length, "perto: o mínimo")
	assert_true(_arsenal.switch_to(1))
	_run(DT)
	assert_false(_arsenal.beam.on, "a troca desliga o raio na hora")
	assert_true(WeaponZones.active().is_empty())


func test_crucifix_winds_up_inside_its_interval() -> void:
	_arsenal.loadout = Loadout.new(2, CRUCIFIX)
	var interval: float = CRUCIFIX.base.interval
	_run(interval + CRUCIFIX.windup - 0.03)
	assert_eq(_shots, 0, "pronto no intervalo + 0,2 s de antecipação")
	_run(0.05)
	assert_eq(_shots, 1)
	_run(interval - 0.1)
	assert_eq(_shots, 1)
	_run(0.12)
	assert_eq(_shots, 2, "o 2º sai um intervalo depois do 1º: a antecipação conta dentro do intervalo")


func test_swap_during_windup_cancels_without_spending() -> void:
	_arsenal.loadout = Loadout.new(2, CRUCIFIX)
	_arsenal.loadout.equip(PEN)
	var spy: Array[int] = [0]
	_arsenal.windup_started.connect(func(_s: int) -> void: spy[0] += 1)
	_run(CRUCIFIX.base.interval + 0.1)
	assert_eq(spy[0], 1, "começou a subir")
	_arsenal.switch_to(1)
	_run(0.5)
	var pen_shots: int = _shots
	_arsenal.switch_to(0)
	_run(0.1 + 0.2 + 2.0 * DT)
	assert_eq(_shots - pen_shots, 1, "voltou pronto: saque + antecipação e sai a cruz")


func test_crucifix_projectile_pierces_the_line_once_each() -> void:
	PoolManager.clear_all()
	var fx := Node2D.new()
	add_child_autofree(fx)
	PoolManager.register(DissolveFx.POOL_KEY, DISSOLVE_SCENE, 16, fx)
	var manager := EnemyManager.new()
	add_child_autofree(manager)
	manager.set_physics_process(false)
	var tough: EnemyData = IMP.duplicate()
	tough.max_hp = 100
	tough.move_speed = 0.0
	for x: float in [140.0, 160.0, 180.0]:
		manager.spawn(tough, Vector2(x, 100))
	var s: WeaponLevelData = CRUCIFIX.base
	_proj.fire(Vector2(100, 100), Vector2.RIGHT, s.speed, s.damage, s.range * CRUCIFIX.travel_mul,
		CRUCIFIX.projectile_kind, s.width / 2.0, s.pierce, CRUCIFIX.hit_freeze)
	_proj.fire(Vector2(100, 100), Vector2.RIGHT, 220.0, 1, 200.0)  # gota da Pena: para no 1º
	for k: int in 40:
		_proj._physics_process(DT)
	var hp: Array[int] = []
	for i: int in manager.count:
		hp.append(manager.hp[i])
	hp.sort()
	assert_eq(hp, [95, 96, 96], "a cruz fere os 3 uma vez (4); a gota só o primeiro (1)")
	PoolManager.clear_all()


func test_charge_feeds_the_hud() -> void:
	# T1800: rajada = tempo/intervalo; raio = pronta; a ativa no saque não passa do saque.
	_arsenal.loadout = Loadout.new(2, PEN)
	_arsenal.loadout.equip(BIBLE)
	_run(0.4)
	assert_almost_eq(_arsenal.loadout.slots[0].charge, 0.5, 0.03, "0,4 de 0,8 s")
	assert_eq(_arsenal.loadout.slots[1].charge, 1.0, "o raio está sempre pronto")
	_arsenal.switch_to(1)
	_run(DT * 3)
	assert_lt(_arsenal.loadout.slots[1].charge, 1.0, "no saque, ainda subindo")
	_run(0.1)
	assert_eq(_arsenal.loadout.slots[1].charge, 1.0)


func test_every_crucifix_level_fires() -> void:
	# Regressão (017 T1742): a recarga em float de 32 bits travava em 1,39999998 < 1,4 e o Crucifixo
	# nunca atirava. Desde a D-098, cada posto de cadência (0..4) precisa atirar.
	for r: int in CRUCIFIX.upgrade(&"rate").max_rank() + 1:
		_shots = 0
		_arsenal.loadout = Loadout.new(2, CRUCIFIX)
		for k: int in r:
			_arsenal.loadout.slots[0].rank_up(&"rate")
		_arsenal._timers.fill(0.0)
		_run(_arsenal.loadout.slots[0].stats().interval + CRUCIFIX.windup + 0.1)
		assert_eq(_shots, 1, "cadência no posto %d atira" % r)

