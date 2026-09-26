extends GutTest
## 005 T513 [TEST-FIRST] EnemyProjectileManager: laço único, acerto, bloqueio, expiração, teto.

const DT := 1.0 / 60.0


class FakePlayer:
	extends Node2D
	var hits: Array[int] = []

	func take_hit(amount: int, _tag: StringName = &"") -> void:
		hits.append(amount)


class Wall:
	extends RefCounted
	var x: float = 0.0

	func blocks_point(pos: Vector2) -> bool:
		return absf(pos.x - x) <= 3.0


var _pm: EnemyProjectileManager
var _player: FakePlayer
var _data: EnemyProjectileData


func before_each() -> void:
	_player = FakePlayer.new()
	_player.position = Vector2(300, 180)
	add_child_autofree(_player)
	_pm = EnemyProjectileManager.new()
	_pm.player = _player
	add_child_autofree(_pm)
	_data = load("res://data/projectiles/prj_page.tres")


func _step(frames: int) -> void:
	for f: int in frames:
		_pm._physics_process(DT)


func test_projectile_hits_player_and_disappears() -> void:
	_pm.fire(_data, Vector2(200, 180 + EnemyProjectileManager.PLAYER_BODY_OFFSET.y), Vector2.RIGHT)
	_step(80)
	assert_eq(_player.hits, [1], "acerto fraco (D-012)")
	assert_eq(_pm.count, 0)


func test_projectile_is_blocked() -> void:
	var wall := Wall.new()
	wall.x = 250.0
	ProjectileBlockers.register(wall)
	_pm.fire(_data, Vector2(200, 176), Vector2.RIGHT)
	_step(80)
	ProjectileBlockers.unregister(wall)
	assert_eq(_player.hits.size(), 0, "a CRUX (ou qualquer bloqueador) segura o tiro")
	assert_eq(_pm.count, 0)


func test_projectile_expires() -> void:
	_pm.fire(_data, Vector2(100, 100), Vector2.UP * 0.0 + Vector2.RIGHT * 0.0001)
	_step(roundi(_data.lifetime / DT) + 2)
	assert_eq(_pm.count, 0)


func test_projectile_leaves_the_page() -> void:
	_pm.fire(_data, Vector2(40, 40), Vector2.LEFT)
	_step(30)
	assert_eq(_pm.count, 0)


func test_capacity_is_a_hard_cap() -> void:
	for i: int in EnemyProjectileManager.CAPACITY + 10:
		_pm.fire(_data, Vector2(100, 60), Vector2.DOWN)
	assert_eq(_pm.count, EnemyProjectileManager.CAPACITY, "acima do teto o tiro é descartado, nunca instancia")
