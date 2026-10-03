extends GutTest
## 012 F5 (FR-1212, SC-1203): a área jogável só encolhe, nunca abaixo do mínimo; faixas e alvos por
## borda; peças que não cabem (ou deixam fresta) saem do mapa.

const MIN := Vector2(400, 220)


func after_each() -> void:
	PlayArea.reset()


func test_starts_as_the_whole_page() -> void:
	PlayArea.reset()
	assert_eq(PlayArea.rect, Arena.PLAYABLE)
	assert_false(PlayArea.is_shrunk())


func test_shrink_never_grows() -> void:
	PlayArea.shrink_to(Rect2(100, 24, 400, 312))
	var r: Rect2 = PlayArea.rect
	PlayArea.shrink_to(Arena.PLAYABLE.grow(50))
	assert_eq(PlayArea.rect, r, "pedir maior não cresce")


func test_six_bites_reach_the_minimum_and_stop() -> void:
	for side: StringName in [&"left", &"right", &"bottom", &"left", &"right", &"bottom", &"left", &"bottom"]:
		var depth: float = 46.0 if side == &"bottom" else 48.0
		PlayArea.shrink_to(PlayArea.target(side, depth, MIN))
	assert_eq(PlayArea.rect, Rect2(120, 24, 400, 220), "mínimo da T1200, preso no topo")
	for side: StringName in [&"left", &"right", &"bottom"]:
		assert_almost_eq(PlayArea.slack(side, MIN), 0.0, 0.01)


func test_strip_is_the_eaten_band() -> void:
	var s: Rect2 = PlayArea.strip(&"left", 48.0, MIN)
	assert_eq(s, Rect2(24, 24, 48, 312))
	assert_eq(PlayArea.strip(&"bottom", 46.0, MIN), Rect2(24, 290, 592, 46))


func test_push_inside_moves_points_in() -> void:
	PlayArea.shrink_to(Rect2(120, 24, 400, 220))
	assert_eq(PlayArea.push_inside(Vector2(30, 300), 5.0), Vector2(125, 239))


func test_obstacles_that_do_not_fit_leave_the_map() -> void:
	var arena: ArenaData = load("res://data/arena/chapter_2.tres")
	var all: int = arena.active(true).size()
	var bitten: int = arena.active(true, Rect2(120, 24, 400, 220)).size()
	assert_lt(bitten, all, "as peças nas faixas comidas saem")
	for o: ObstacleData in arena.active(true, Rect2(120, 24, 400, 220)):
		assert_true(Rect2(120, 24, 400, 220).encloses(Rect2(o.rect())))
