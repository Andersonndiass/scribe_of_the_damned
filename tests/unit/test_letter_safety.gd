extends GutTest
## T603 LetterSafety (006 FR-605, SC-604): com menos de N letras úteis por T s, solta uma letra;
## respeita o cooldown; volta a contar quando o chão se enche.

const TUNING := preload("res://data/tuning/letter_safety.tres")

var _s: LetterSafety


func before_each() -> void:
	_s = LetterSafety.new(TUNING)


func _ticks(seconds: float, useful: int) -> int:
	var drops: int = 0
	for i: int in roundi(seconds / 0.1):
		if _s.tick(0.1, useful):
			drops += 1
	return drops


func test_drops_after_wait_below_minimum() -> void:
	assert_eq(_ticks(3.9, 0), 0, "ainda não passaram 4 s")
	assert_eq(_ticks(0.2, 0), 1, "passou de 4 s: solta")


func test_no_drop_with_enough_letters() -> void:
	assert_eq(_ticks(30.0, 3), 0)


func test_cooldown_between_drops() -> void:
	assert_eq(_ticks(12.05, 0), 3, "a cada 4 s, nunca mais que isso (SC-604)")


func test_counter_resets_when_ground_fills() -> void:
	_ticks(3.0, 0)
	_ticks(0.1, 5)
	assert_eq(_ticks(3.5, 0), 0, "a contagem recomeçou")


func test_drop_position_is_in_the_ring_and_inside_the_page() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var rect := Rect2(24, 24, 592, 312)
	for i: int in 50:
		var p: Vector2 = _s.drop_position(Vector2(30, 30), rng, rect)
		assert_true(rect.has_point(p), "dentro da página")
	var q: Vector2 = _s.drop_position(Vector2(320, 180), rng, rect)
	var d: float = q.distance_to(Vector2(320, 180))
	assert_between(d, TUNING.min_distance - 0.5, TUNING.max_distance + 0.5)
