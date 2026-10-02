extends GutTest
## D-098 (T1830 §2.3): lentidão de arma — a mais forte vence, a fraca é ignorada, a igual renova;
## campeão leva metade; o acerto do projétil aplica em quem sobreviveu.

var _m: EnemyManager
var _tough: EnemyData


func before_each() -> void:
	_m = EnemyManager.new()
	add_child_autofree(_m)
	_m.set_physics_process(false)
	_tough = (load("res://data/enemies/imp.tres") as EnemyData).duplicate()
	_tough.max_hp = 99


func test_strongest_wins_and_weaker_is_ignored() -> void:
	var i: int = _m.spawn(_tough, Vector2(100, 100))
	_m.apply_slow(i, 0.8, 1.0)
	assert_almost_eq(_m.slow_factor[i], 0.8, 0.001)
	_m.apply_slow(i, 0.9, 5.0)
	assert_almost_eq(_m.slow_left[i], 1.0, 0.001, "a mais fraca não estende")
	_m.apply_slow(i, 0.8, 2.0)
	assert_almost_eq(_m.slow_left[i], 2.0, 0.001, "a igual renova")
	_m.apply_slow(i, 0.75, 0.5)
	assert_almost_eq(_m.slow_factor[i], 0.75, 0.001, "a mais forte vence")


func test_champion_takes_half() -> void:
	var c: int = _m.spawn(_tough, Vector2(100, 100), true)
	_m.apply_slow(c, 0.8, 1.0)
	assert_almost_eq(_m.slow_factor[c], 0.9, 0.001, "1 − 0,2 × 0,5")


func test_projectile_hit_slows_the_survivor() -> void:
	var i: int = _m.spawn(_tough, Vector2(100, 100))
	assert_true(_m.query_hit(Vector2(100, 100), 3.0, 1, 0.8, 1.0))
	assert_almost_eq(_m.slow_factor[i], 0.8, 0.001)
