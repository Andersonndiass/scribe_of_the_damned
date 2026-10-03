extends GutTest
## 012 F2 (FR-1207/1208, SC-1205; T1200 §3): a Traça-Mãe pequena estoura em Traças no fim do tick,
## dentro do teto de vivas, sem nós novos; crias congeladas no começo; zona letal abafa; o fim de
## onda não estoura.

const DISSOLVE_SCENE := preload("res://src/enemies/dissolve_fx.tscn")
const MOTHER := preload("res://data/enemies/moth_mother.tres")
const MOTH := preload("res://data/enemies/moth.tres")
const DT := 1.0 / 60.0

var _manager: EnemyManager
var _bursts: Array = []


func before_each() -> void:
	PoolManager.clear_all()
	KillZones.clear()
	_bursts.clear()
	var root := Node2D.new()
	add_child_autofree(root)
	var fx := Node2D.new()
	root.add_child(fx)
	PoolManager.register(DissolveFx.POOL_KEY, DISSOLVE_SCENE, 64, fx)
	_manager = EnemyManager.new()
	root.add_child(_manager)
	_manager.set_physics_process(false)
	EventBus.brood_burst.connect(_on_burst)


func after_each() -> void:
	EventBus.brood_burst.disconnect(_on_burst)
	KillZones.clear()
	PoolManager.clear_all()


func _on_burst(_p: Vector2, spawned: int, smothered: int) -> void:
	_bursts.append([spawned, smothered])


func _burst() -> BurstOnDeathBehavior:
	return MOTHER.behavior as BurstOnDeathBehavior


func test_mother_bursts_into_moths_at_end_of_tick() -> void:
	var i: int = _manager.spawn(MOTHER, Vector2(300, 180))
	_manager.kill(i)
	assert_eq(_manager.count, 0, "nada nasce no meio da morte")
	_manager._physics_process(DT)
	assert_eq(_manager.count_of(MOTH), _burst().burst_count)
	assert_eq(_bursts, [[3, 0]])
	for j: int in _manager.count:
		assert_gt(_manager.freeze_left[j], 0.0, "cria nasce congelada (sem contato nem roubo)")
		assert_lt(_manager.positions[j].distance_to(Vector2(300, 180)), _burst().burst_radius + 1.0)


func test_burst_respects_live_moth_cap() -> void:
	var cap: int = _burst().burst_max_alive
	for k: int in cap - 1:
		_manager.spawn(MOTH, Vector2(100 + k * 8, 100))
	var i: int = _manager.spawn(MOTHER, Vector2(300, 180))
	_manager.kill(i)
	_manager._physics_process(DT)
	assert_eq(_manager.count_of(MOTH), cap, "não passa do teto")
	assert_eq(_bursts[0], [1, 2])


func test_burst_creates_no_nodes() -> void:
	var before: int = _manager.get_child_count()
	for k: int in 3:
		_manager.kill(_manager.spawn(MOTHER, Vector2(200 + k * 40, 180)))
	_manager._physics_process(DT)
	assert_eq(_manager.get_child_count(), before, "slots SoA, sem instantiate")


func test_lethal_zone_smothers_the_brood() -> void:
	var z := KillZone.new()
	z.open(KillZone.Shape.CIRCLE, 1.0)
	z.origin = Vector2(300, 180)
	z.radius = 40.0
	KillZones.register(z)
	_manager.spawn(MOTHER, Vector2(300, 180))
	for k: int in 3:
		_manager._physics_process(DT)
	assert_eq(_manager.count, 0, "a zona matou a mãe e as crias não nasceram")
	assert_eq(_bursts, [[0, 3]])


func test_mass_kill_in_one_tick_keeps_slots_consistent() -> void:
	for k: int in 5:
		_manager.spawn(MOTHER, Vector2(100 + k * 60, 180))
	for k: int in 5:
		_manager.kill(0)
	_manager._physics_process(DT)
	assert_eq(_manager.count, _manager.count_of(MOTH))
	assert_eq(_manager.count, _burst().burst_max_alive, "15 pedidas, teto 14")


func test_wave_end_does_not_burst() -> void:
	_manager.spawn(MOTHER, Vector2(300, 180))
	_manager.dissolve_all()
	_manager._physics_process(DT)
	assert_eq(_manager.count, 0)
	assert_eq(_bursts.size(), 0)
