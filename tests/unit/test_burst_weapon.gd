extends GutTest
## T1705 Arsenal + rajada (017): a Pena nível 1 é o ataque automático de antes (1 gota a cada 0,8 s,
## sem alvo não dispara — FR-002); só a arma ativa ataca; 1/2 trocam com "saque"; a recarga da
## guardada continua; nível 3 = 2 gotas; a Pena de Ganso encurta o intervalo de todas.

const PEN := preload("res://data/weapons/pen.tres")
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
var _fake: FakeEnemies
var _shots: int = 0


func before_each() -> void:
	_shots = 0
	_origin = Node2D.new()
	add_child_autofree(_origin)
	_proj = PlayerProjectileManager.new()
	_origin.add_child(_proj)
	_arsenal = Arsenal.new()
	_arsenal.projectiles = _proj
	_arsenal.loadout = Loadout.new(2, PEN)
	_origin.add_child(_arsenal)
	_arsenal.set_physics_process(false)
	_fake = FakeEnemies.new()
	EnemyQuery.provider = _fake
	_arsenal.fired.connect(func(_t: Vector2) -> void: _shots += 1)


func after_each() -> void:
	EnemyQuery.provider = null


func _run(seconds: float) -> void:
	for k: int in roundi(seconds / DT):
		_arsenal._physics_process(DT)


func test_pen_level_1_keeps_the_old_cadence() -> void:
	var s: WeaponLevelData = PEN.base
	# T1742 (rules-agent): 2 gotas desde o nível 1 (a cadência e o alcance são os de antes).
	assert_eq([s.damage, s.interval, s.range, s.speed, s.count], [1, 0.8, 160.0, 220.0, 2], "2 gotas a cada 0,8 s")
	_run(0.75)
	assert_eq(_shots, 0)
	_run(0.1)
	assert_eq(_shots, 1, "1 gota a cada 0,8 s")
	_run(0.8)
	assert_eq(_shots, 2)


func test_no_target_no_shot() -> void:
	_fake.target = Vector2(1000, 0)
	_run(2.0)
	assert_eq(_shots, 0, "FR-002")


func test_only_the_active_weapon_attacks_and_swap_waits_the_draw() -> void:
	var lo: Loadout = _arsenal.loadout
	lo.equip(PEN)  # 2º espaço
	assert_false(_arsenal.switch_to(0), "já é a ativa")
	_run(1.0)  # a guardada fica pronta (0,8 s) enquanto a ativa atira
	_shots = 0
	assert_true(_arsenal.switch_to(1))
	assert_eq(lo.active, 1)
	_run(0.05)
	assert_eq(_shots, 0, "a arma nova está pronta, mas espera o saque de 0,1 s")
	_run(0.1)
	assert_eq(_shots, 1, "a recarga dela correu guardada: atira assim que o saque acaba")


func test_drop_upgrade_fires_three_drops() -> void:
	_arsenal.loadout.slots[0].rank_up(&"drop")
	_run(0.81)
	assert_eq(_proj.count, 3, "+1 GOTA: 3 gotas (no mesmo alvo quando só há um)")


func test_goose_quill_speeds_up_every_weapon() -> void:
	var data := PlayerData.new()
	_arsenal.data = data
	var stats: RunStats = RunStats.of(data)
	stats.apply(load("res://data/blessings/fine_quill.tres"))
	assert_almost_eq(_arsenal.interval_of(_arsenal.loadout.active_slot()), 0.8 * 0.88, 0.0001)


func test_loadout_equip_fills_then_replaces_the_active() -> void:
	var lo := Loadout.new(2, PEN)
	assert_eq(lo.equip(PEN), 1, "preenche o vazio")
	assert_true(lo.is_full())
	lo.rank_up(0, &"rate")
	lo.set_active(0)
	assert_eq(lo.equip(PEN), 0, "cheio: substitui a ativa")
	assert_eq(lo.slots[0].level, 1, "a arma nova começa no nível 1")


func test_weapon_data_is_valid() -> void:
	assert_eq(PEN.validate(), "")
	assert_eq(PEN.max_level(), 7, "D-098: 1 + 6 compras")
	assert_eq(PEN.validate(load("res://data/weapons/arsenal_tuning.tres")), "", "no teto, dentro dos limites")
