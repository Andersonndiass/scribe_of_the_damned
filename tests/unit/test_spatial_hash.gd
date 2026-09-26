extends GutTest
## T013 [TEST-FIRST] SpatialHash contra força bruta (plan §4.6).

const WORLD := Rect2(0, 0, 640, 360)
const N := 1000

var _positions: PackedVector2Array
var _hash: SpatialHash
var _rng := RandomNumberGenerator.new()


func before_each() -> void:
	_rng.seed = 1348
	_positions = PackedVector2Array()
	_positions.resize(N)
	for i: int in N:
		_positions[i] = Vector2(_rng.randf_range(0.0, 640.0), _rng.randf_range(0.0, 360.0))
	_hash = SpatialHash.new(WORLD, 32.0)
	_hash.rebuild(_positions, N)


func _brute_radius(center: Vector2, r: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	for i: int in N:
		if _positions[i].distance_squared_to(center) <= r * r:
			out.append(i)
	return out


func _sorted(a: PackedInt32Array) -> Array:
	var arr: Array = Array(a)
	arr.sort()
	return arr


func test_query_radius_matches_brute_force() -> void:
	for q: int in 200:
		var center := Vector2(_rng.randf_range(-20.0, 660.0), _rng.randf_range(-20.0, 380.0))
		var r: float = _rng.randf_range(4.0, 120.0)
		var got: Array = _sorted(_hash.query_radius(center, r))
		var expected: Array = _sorted(_brute_radius(center, r))
		assert_eq(got, expected, "consulta %d em %s r=%.1f" % [q, center, r])


func test_nearest_matches_brute_force() -> void:
	for q: int in 200:
		var center := Vector2(_rng.randf_range(0.0, 640.0), _rng.randf_range(0.0, 360.0))
		var max_r: float = _rng.randf_range(10.0, 200.0)
		var best: int = -1
		var best_d: float = INF
		for i: int in N:
			var d: float = _positions[i].distance_squared_to(center)
			if d <= max_r * max_r and d < best_d:
				best_d = d
				best = i
		var got: int = _hash.nearest(center, max_r)
		if best == -1:
			assert_eq(got, -1, "sem vizinho na consulta %d" % q)
		else:
			assert_almost_eq(_positions[got].distance_squared_to(center), best_d, 0.001, "consulta %d" % q)


func test_respects_count_smaller_than_array() -> void:
	_hash.rebuild(_positions, 10)
	var all_found: PackedInt32Array = _hash.query_radius(Vector2(320, 180), 1000.0)
	assert_eq(all_found.size(), 10)
	for slot: int in all_found:
		assert_lt(slot, 10)


func test_points_outside_world_are_clamped_not_lost() -> void:
	var pts := PackedVector2Array([Vector2(-50, -50), Vector2(700, 400)])
	_hash.rebuild(pts, 2)
	assert_eq(_hash.query_radius(Vector2(-50, -50), 1.0).size(), 1)
	assert_eq(_hash.query_radius(Vector2(700, 400), 1.0).size(), 1)


func test_empty_hash_returns_nothing() -> void:
	_hash.rebuild(PackedVector2Array(), 0)
	assert_eq(_hash.query_radius(Vector2(320, 180), 500.0).size(), 0)
	assert_eq(_hash.nearest(Vector2(320, 180), 500.0), -1)
