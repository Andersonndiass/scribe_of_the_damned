extends GutTest
## T601 AttackPicker (006 FR-603, SC-602): pesos da fase, sem 3 iguais seguidos, cooldown e
## condição de distância.

const P1 := preload("res://data/bosses/asmodeus_phase_1.tres")
const P2 := preload("res://data/bosses/asmodeus_phase_2.tres")
const P3 := preload("res://data/bosses/asmodeus_phase_3.tres")

var _rng: RandomNumberGenerator
var _picker: AttackPicker


func before_each() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 6
	_picker = AttackPicker.new(_rng)


func _run(phase: PhaseData, n: int, distance: float) -> Array[StringName]:
	var out: Array[StringName] = []
	var t: float = 0.0
	for i: int in n:
		var a: AttackData = _picker.pick(phase, t, distance)
		if a != null:
			_picker.record(a, t)
			out.append(a.id)
		t += 1.0
	return out


func test_only_attacks_of_the_phase() -> void:
	var ids := _run(P1, 200, 30.0)
	for id: StringName in ids:
		assert_true(id in [&"beam", &"swipe"], "F1 só tem Raio e Swipe (SC-601)")


func test_never_three_in_a_row() -> void:
	for phase: PhaseData in [P1, P2, P3]:
		var ids := _run(phase, 500, 30.0)
		for i: int in range(2, ids.size()):
			assert_false(ids[i] == ids[i - 1] and ids[i] == ids[i - 2], "SC-602 em %s" % ids[i])


func test_distance_condition_removes_swipe() -> void:
	var ids := _run(P1, 100, 200.0)
	assert_does_not_have(ids, &"swipe", "Swipe só perto do escriba")
	assert_true(ids.size() > 0)


func test_cooldown_is_respected() -> void:
	var last: Dictionary = {}
	var t: float = 0.0
	for i: int in 400:
		var a: AttackData = _picker.pick(P2, t, 30.0)
		if a != null:
			if a.cooldown > 0.0 and last.has(a.id):
				assert_true(t - float(last[a.id]) >= a.cooldown - 0.001, "%s respeita o cooldown" % a.id)
			last[a.id] = t
			_picker.record(a, t)
		t += 0.5


func test_weights_shape_the_distribution() -> void:
	var ids := _run(P1, 2000, 30.0)
	var beams: int = ids.count(&"beam")
	assert_between(float(beams) / ids.size(), 0.5, 0.7, "Raio ~60% na F1")


func test_same_seed_same_sequence() -> void:
	var a := _run(P2, 50, 30.0)
	_rng.seed = 6
	_picker = AttackPicker.new(_rng)
	assert_eq(_run(P2, 50, 30.0), a)
