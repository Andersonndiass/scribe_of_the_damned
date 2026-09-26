extends GutTest
## T024 Ataque automático a cada attack_interval; sem alvo, não dispara (FR-002).

class FakeEnemies:
	extends RefCounted
	var target: Vector2 = Vector2(100, 0)
	var hits: int = 0

	func query_nearest(pos: Vector2, radius: float) -> Vector2:
		return target if pos.distance_to(target) <= radius else Vector2.INF

	func query_hit(_pos: Vector2, _radius: float, _damage: int) -> bool:
		hits += 1
		return false


var _origin: Node2D
var _attack: AutoAttack
var _fake: FakeEnemies
var _proj: PlayerProjectileManager


func before_each() -> void:
	_origin = Node2D.new()
	add_child_autofree(_origin)
	_proj = PlayerProjectileManager.new()
	_origin.add_child(_proj)
	_attack = AutoAttack.new()
	_attack.projectiles = _proj
	_origin.add_child(_attack)
	var data := PlayerData.new()
	data.attack_interval = 0.8
	data.attack_range = 160.0
	_attack.data = data
	_fake = FakeEnemies.new()
	EnemyQuery.provider = _fake
	watch_signals(_attack)


func after_each() -> void:
	EnemyQuery.provider = null


func _simulate(seconds: float) -> void:
	for i: int in roundi(seconds / 0.1):
		_attack._physics_process(0.1)


func test_fires_every_interval() -> void:
	_simulate(2.0)
	assert_signal_emit_count(_attack, "fired", 2, "0.8s e 1.6s")


func test_does_not_fire_without_target() -> void:
	_fake.target = Vector2(1000, 0)
	_simulate(2.0)
	assert_signal_emit_count(_attack, "fired", 0)


func test_does_not_fire_when_disabled() -> void:
	_attack.enabled = false
	_simulate(2.0)
	assert_signal_emit_count(_attack, "fired", 0)


func test_fires_into_projectile_manager_without_instantiating() -> void:
	var before: int = PoolManager.instantiate_count
	_simulate(0.9)
	assert_eq(_proj.count, 1, "a gota entrou no gerenciador")
	assert_eq(PoolManager.instantiate_count, before)
