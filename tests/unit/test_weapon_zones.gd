extends GutTest
## 017 T1710–T1712, T1715: zona de arma no EnemyManager (fere sem matar na hora, relógio por
## inimigo, só os N mais próximos, precisão 1,5 contra campeão com a fração guardada), a busca por
## segmento na grade e o acerto que atravessa com congelamento (Crucifixo).

const DISSOLVE_SCENE := preload("res://src/enemies/dissolve_fx.tscn")
const IMP := preload("res://data/enemies/imp.tres")
const DT := 1.0 / 60.0

var _manager: EnemyManager
var _tough: EnemyData


func before_each() -> void:
	PoolManager.clear_all()
	KillZones.clear()
	WeaponZones.clear()
	var root := Node2D.new()
	add_child_autofree(root)
	var fx := Node2D.new()
	root.add_child(fx)
	PoolManager.register(DissolveFx.POOL_KEY, DISSOLVE_SCENE, 64, fx)
	_manager = EnemyManager.new()
	root.add_child(_manager)
	_manager.set_physics_process(false)
	_tough = IMP.duplicate()
	_tough.max_hp = 100
	_tough.move_speed = 0.0


func after_each() -> void:
	WeaponZones.clear()
	PoolManager.clear_all()


func _line(damage: int, interval: float, max_targets: int = 0) -> WeaponZone:
	var z := WeaponZone.new()
	z.open(ZoneShape.Shape.LINE)
	z.origin = Vector2(100, 100)
	z.dir = Vector2.RIGHT
	z.length = 200.0
	z.width = 6.0
	z.damage = damage
	z.interval = interval
	z.max_targets = max_targets
	WeaponZones.register(z)
	return z


func _tick(seconds: float) -> void:
	for k: int in roundi(seconds / DT):
		_manager._physics_process(DT)


func _hp_at(pos: Vector2) -> int:
	for i: int in _manager.count:
		if _manager.positions[i].distance_to(pos) < 0.5:
			return _manager.hp[i]
	return -1


func test_zone_shape_keeps_kill_zone_geometry() -> void:
	var k := KillZone.new()
	k.open(KillZone.Shape.LINE, 1.0)
	k.origin = Vector2.ZERO
	k.dir = Vector2.RIGHT
	k.length = 100.0
	k.width = 10.0
	assert_true(k.contains(Vector2(50, 4), 1.0))
	assert_false(k.contains(Vector2(50, 20), 1.0))
	assert_true(k is ZoneShape, "a geometria é a mesma base das armas")


func test_weapon_zone_hurts_inside_only_and_never_kills_outright() -> void:
	_manager.spawn(_tough, Vector2(150, 100))
	_manager.spawn(_tough, Vector2(150, 160))
	_line(1, 0.5)
	_tick(DT)
	assert_eq(_hp_at(Vector2(150, 100)), 99, "dentro: 1 de dano, não morre (só a palavra mata na hora)")
	assert_eq(_hp_at(Vector2(150, 160)), 100, "fora do raio")


func test_each_enemy_has_its_own_clock() -> void:
	_manager.spawn(_tough, Vector2(150, 100))
	_line(1, 0.5)
	_tick(0.3)
	assert_eq(_hp_at(Vector2(150, 100)), 99, "1 toque até 0,5 s")
	_tick(0.3)
	assert_eq(_hp_at(Vector2(150, 100)), 98, "o 2º toque sai no fim do intervalo, checado todo tick")


func test_only_the_nearest_two_along_the_beam() -> void:
	for x: float in [140.0, 180.0, 220.0, 260.0]:
		_manager.spawn(_tough, Vector2(x, 100))
	_line(1, 0.5, 2)
	_tick(DT)
	assert_eq([_hp_at(Vector2(140, 100)), _hp_at(Vector2(180, 100)), _hp_at(Vector2(220, 100)), _hp_at(Vector2(260, 100))],
		[99, 99, 100, 100], "a Bíblia fere os 2 mais próximos")


func test_precision_keeps_the_fraction_against_champions() -> void:
	var i: int = _manager.spawn(_tough, Vector2(150, 100), true)
	var start: int = _manager.hp[i]
	var z := _line(1, 0.1)
	z.precision_mul = 1.5
	var seen: Array[int] = []
	var last: int = start
	for k: int in 4:
		_tick(0.1)
		seen.append(last - _manager.hp[0])
		last = _manager.hp[0]
	assert_eq(seen, [1, 2, 1, 2], "1,5 × 1 de dano: 1, 2, 1, 2 (média 1,5)")


func test_segment_query_finds_the_diagonal_and_skips_the_rest() -> void:
	var near: int = _manager.spawn(_tough, Vector2(200, 200))
	_manager.spawn(_tough, Vector2(500, 60))
	_manager._physics_process(DT)
	var slots: PackedInt32Array = _manager._hash.query_segment(Vector2(100, 100), Vector2(300, 300), 8.0)
	assert_true(slots.has(near), "no caminho do raio")
	assert_eq(slots.size(), 1, "longe do segmento não entra")


func test_pierce_hits_each_once_and_freezes() -> void:
	for x: float in [100.0, 104.0, 108.0]:
		_manager.spawn(_tough, Vector2(x, 100))
	var got: PackedInt32Array = _manager.query_hit_pierce(Vector2(104, 100), 6.0, 4, PackedInt32Array(), 0.05, 2)
	assert_eq(got.size(), 2, "teto de alvos novos")
	var again: PackedInt32Array = _manager.query_hit_pierce(Vector2(104, 100), 6.0, 4, got, 0.05, 8)
	assert_eq(again.size(), 1, "quem já levou deste projétil não leva de novo")
	for i: int in 3:
		assert_eq(_manager.hp[i], 96)
		assert_almost_eq(_manager.freeze_left[i], 0.05, 0.001, "congela 50 ms")
