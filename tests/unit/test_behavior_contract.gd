extends GutTest
## 005 T500–T502: contrato dos comportamentos stateless e arrays de estado do EnemyManager.

const IMP := preload("res://data/enemies/imp.tres")
const DT := 1.0 / 60.0


class FakePlayer:
	extends Node2D
	var hits: Array[int] = []

	func take_hit(amount: int, _tag: StringName = &"") -> void:
		hits.append(amount)


## Comportamento de teste: conta os ticks e manda o inimigo sempre para a direita.
class RightBehavior:
	extends EnemyBehavior
	var ticks: int = 0

	func _init() -> void:
		needs_tick = true

	func desired_velocity(m: EnemyManager, i: int, _t: Vector2, _dt: float) -> Vector2:
		return Vector2.RIGHT * m.data_of[i].move_speed

	func tick(_m: EnemyManager, _i: int, _dt: float) -> void:
		ticks += 1


var _m: EnemyManager
var _player: FakePlayer


func before_each() -> void:
	_player = FakePlayer.new()
	_player.position = Vector2(320, 180)
	add_child_autofree(_player)
	_m = EnemyManager.new()
	_m.player = _player
	add_child_autofree(_m)


func _custom(behavior: EnemyBehavior, dash_damage: int = 0) -> EnemyData:
	var d: EnemyData = IMP.duplicate()
	d.behavior = behavior
	d.dash_contact_damage = dash_damage
	return d


func test_imp_uses_the_chase_resource() -> void:
	assert_true(IMP.behavior is ChaseBehavior)


func test_behavior_drives_velocity_and_tick_runs_every_frame() -> void:
	var b := RightBehavior.new()
	_m.spawn(_custom(b), Vector2(100, 60))
	for f: int in 10:
		_m._physics_process(DT)
	assert_eq(b.ticks, 10, "tick todo frame (needs_tick)")
	assert_gt(_m.positions[0].x, 100.0, "andou para a direita, ignorando o jogador")
	assert_almost_eq(_m.positions[0].y, 60.0, 0.01)


func test_state_arrays_follow_swap_remove() -> void:
	_m.spawn(IMP, Vector2(100, 100))
	_m.spawn(IMP, Vector2(200, 100))
	_m.state[1] = EnemyBehavior.STATE_WINDUP
	_m.aim[1] = Vector2.UP
	_m.state_timer[1] = 0.3
	_m.champion[1] = 1
	_m.kill(0)
	assert_eq(_m.state[0], EnemyBehavior.STATE_WINDUP)
	assert_eq(_m.aim[0], Vector2.UP)
	assert_almost_eq(_m.state_timer[0], 0.3, 0.0001)
	assert_eq(_m.champion[0], 1)


func test_spawn_resets_state() -> void:
	_m.spawn(IMP, Vector2(100, 100), true)
	assert_eq(_m.state[0], EnemyBehavior.STATE_IDLE)
	assert_eq(_m.champion[0], 1)
	assert_eq(_m.max_hp_of[0], roundi(IMP.max_hp * _m.champion_tuning.hp_mul), "campeão: HP × hp_mul")


func test_dash_state_uses_strong_contact_damage() -> void:
	var d := _custom(RightBehavior.new(), 2)
	_m.spawn(d, _player.position + EnemyManager.PLAYER_BODY_OFFSET)
	_m.state[0] = EnemyBehavior.STATE_DASH
	_m._physics_process(DT)
	assert_eq(_player.hits[0], 2, "contato forte durante o dash (D-012)")


func test_new_eventbus_signals_exist() -> void:
	for s: StringName in [&"letter_eaten", &"champion_killed", &"gold_ink_collected", &"chapter_completed"]:
		assert_true(EventBus.has_signal(s), s)
