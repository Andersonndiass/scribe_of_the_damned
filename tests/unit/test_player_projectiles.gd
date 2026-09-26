extends GutTest
## Projéteis do jogador num laço único (T085 §4 item 2, C-005): andam, acertam, expiram e
## respeitam o teto sem instanciar nada.

const DT := 1.0 / 60.0


class FakeEnemies:
	extends RefCounted
	var hit_at: Vector2 = Vector2.INF
	var hits: int = 0
	var last_damage: int = 0

	func query_nearest(_pos: Vector2, _radius: float) -> Vector2:
		return Vector2.INF

	func query_hit(pos: Vector2, radius: float, damage: int) -> bool:
		if pos.distance_to(hit_at) <= radius:
			hits += 1
			last_damage = damage
			return true
		return false


var _proj: PlayerProjectileManager
var _fake: FakeEnemies


func before_each() -> void:
	_proj = PlayerProjectileManager.new()
	add_child_autofree(_proj)
	_fake = FakeEnemies.new()
	EnemyQuery.provider = _fake


func after_each() -> void:
	EnemyQuery.provider = null


func _step(ticks: int) -> void:
	for i: int in ticks:
		_proj._physics_process(DT)


func test_moves_along_direction_at_speed() -> void:
	assert_true(_proj.fire(Vector2(10, 20), Vector2(2, 0), 120.0, 1, 500.0))
	_step(30)
	assert_eq(_proj.count, 1)
	assert_almost_eq(_proj.position_of(0).x, 10.0 + 60.0, 0.01, "0,5 s a 120 px/s")
	assert_almost_eq(_proj.position_of(0).y, 20.0, 0.01)


func test_hit_removes_and_passes_damage() -> void:
	_fake.hit_at = Vector2(50, 0)
	_proj.fire(Vector2.ZERO, Vector2.RIGHT, 120.0, 3, 500.0)
	_step(40)
	assert_eq(_fake.hits, 1, "acerta uma vez só")
	assert_eq(_fake.last_damage, 3)
	assert_eq(_proj.count, 0, "some ao acertar")


func test_expires_at_max_distance() -> void:
	_proj.fire(Vector2.ZERO, Vector2.RIGHT, 120.0, 1, 60.0)
	_step(29)
	assert_eq(_proj.count, 1, "ainda não chegou a 60 px")
	_step(2)
	assert_eq(_proj.count, 0, "some ao passar do alcance")


func test_capacity_refuses_without_instantiating() -> void:
	var before: int = PoolManager.instantiate_count
	var children: int = _proj.get_child_count()
	for i: int in PlayerProjectileManager.CAPACITY:
		assert_true(_proj.fire(Vector2.ZERO, Vector2.RIGHT, 100.0, 1, 500.0))
	assert_false(_proj.fire(Vector2.ZERO, Vector2.RIGHT, 100.0, 1, 500.0), "teto cheio recusa")
	assert_eq(_proj.count, PlayerProjectileManager.CAPACITY)
	assert_eq(_proj.get_child_count(), children, "nenhum nó por projétil")
	assert_eq(PoolManager.instantiate_count, before)


func test_swap_remove_keeps_the_others() -> void:
	_fake.hit_at = Vector2(20, 0)
	_proj.fire(Vector2.ZERO, Vector2.RIGHT, 120.0, 1, 500.0)  # acerta
	_proj.fire(Vector2(0, 100), Vector2.RIGHT, 120.0, 1, 500.0)
	_proj.fire(Vector2(0, 200), Vector2.RIGHT, 120.0, 1, 500.0)
	_step(12)
	assert_eq(_proj.count, 2)
	var ys: Array[float] = [_proj.position_of(0).y, _proj.position_of(1).y]
	ys.sort()
	assert_eq(ys, [100.0, 200.0])


func test_clear_empties() -> void:
	_proj.fire(Vector2.ZERO, Vector2.RIGHT, 120.0, 1, 500.0)
	_proj.clear()
	assert_eq(_proj.count, 0)
