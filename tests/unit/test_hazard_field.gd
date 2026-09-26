extends GutTest
## 005 T515 [TEST-FIRST] HazardField: poças de lentidão com teto, duração e consulta de lentidão.

var _h: HazardField
var _puddle: PuddleData


func before_each() -> void:
	_h = HazardField.new()
	add_child_autofree(_h)
	_puddle = load("res://data/hazards/puddle_ink.tres")


func test_slow_inside_and_outside() -> void:
	_h.add_puddle(_puddle, Vector2(100, 100))
	assert_almost_eq(_h.slow_at(Vector2(100, 100)), _puddle.player_slow_factor, 0.001)
	assert_almost_eq(_h.slow_at(Vector2(100 + _puddle.size.x, 100)), 1.0, 0.001)


func test_puddle_expires() -> void:
	_h.add_puddle(_puddle, Vector2(100, 100))
	for f: int in roundi(_puddle.duration * 60.0) + 2:
		_h._process(1.0 / 60.0)
	assert_eq(_h.count, 0)
	assert_almost_eq(_h.slow_at(Vector2(100, 100)), 1.0, 0.001)


func test_overlapping_puddles_do_not_stack() -> void:
	_h.add_puddle(_puddle, Vector2(100, 100))
	_h.add_puddle(_puddle, Vector2(102, 100))
	assert_almost_eq(_h.slow_at(Vector2(101, 100)), _puddle.player_slow_factor, 0.001)


func test_capacity_cap() -> void:
	for i: int in HazardField.CAPACITY + 5:
		_h.add_puddle(_puddle, Vector2(40 + i * 10, 100))
	assert_eq(_h.count, HazardField.CAPACITY)
