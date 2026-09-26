extends GutTest
## T024 Ataque automático a cada attack_interval; sem alvo, não dispara (FR-002).

const INK_DROP_SCENE := preload("res://src/player/ink_drop.tscn")


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


func before_each() -> void:
	PoolManager.clear_all()
	_origin = Node2D.new()
	add_child_autofree(_origin)
	var layer := Node2D.new()
	_origin.add_child(layer)
	PoolManager.register(InkDrop.POOL_KEY, INK_DROP_SCENE, 8, layer)
	_attack = AutoAttack.new()
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
	PoolManager.clear_all()


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


func test_uses_pool_without_instantiating() -> void:
	var before: int = PoolManager.instantiate_count
	_simulate(4.0)
	assert_eq(PoolManager.instantiate_count, before)
