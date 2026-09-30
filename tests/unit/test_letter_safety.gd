extends GutTest
## T603 LetterSafety (006 FR-605, SC-604; 017): passado `wait` s sem menu de letra, pede um menu;
## respeita o cooldown; volta a contar quando um menu abre (useful >= min_useful).

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
	assert_eq(_ticks(TUNING.wait - 0.1, 0), 0, "ainda não passou o tempo de espera")
	assert_eq(_ticks(0.2, 0), 1, "passou do tempo: pede o menu")


func test_no_drop_with_enough_letters() -> void:
	assert_eq(_ticks(30.0, TUNING.min_useful), 0)


func test_cooldown_between_drops() -> void:
	assert_eq(_ticks(TUNING.wait * 3.0 + 0.5, 0), 3, "a cada `wait` s, nunca mais que isso (SC-604)")


func test_counter_resets_when_ground_fills() -> void:
	_ticks(TUNING.wait - 1.0, 0)
	_ticks(0.1, TUNING.min_useful)
	assert_eq(_ticks(TUNING.wait - 0.5, 0), 0, "a contagem recomeçou")

