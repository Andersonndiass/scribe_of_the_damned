extends GutTest
## T400 Degradação da página (004 FR-401, FR-402, FR-404; SC-401, SC-402): o estágio segue o dado da
## onda, é acumulado e nunca volta no capítulo; a troca animada só acontece no fim da onda; a ameaça
## só liga quando o próximo estágio é maior; a entrada direta aplica na hora.

var _p: PageDegradation
var _degraded: Array[int] = []


func before_each() -> void:
	_p = PageDegradation.new()
	_degraded.clear()
	_p.degraded.connect(func(s: int) -> void: _degraded.append(s))


func test_direct_entry_applies_at_once() -> void:
	_p.apply(2, 3, false)
	assert_eq(_p.stage, 2)
	assert_eq(_p.shown_stage, 2, "sem transição")
	assert_eq(_p.state, PageDegradation.Phase.STEADY)
	assert_eq(_degraded, [2])


func test_animated_change_reveals_then_settles() -> void:
	_p.apply(0, 1, false)
	_p.apply(1, 1, true)
	assert_eq(_p.state, PageDegradation.Phase.TRANSITIONING)
	assert_eq(_p.shown_stage, 0, "o estágio novo ainda está sendo revelado")
	_p.tick(0.1, 0.4)
	assert_almost_eq(_p.reveal, 0.25, 0.001)
	_p.tick(0.4, 0.4)
	assert_eq(_p.state, PageDegradation.Phase.STEADY)
	assert_eq(_p.shown_stage, 1)
	assert_eq(_degraded, [0, 1])


func test_never_goes_back_within_the_chapter() -> void:
	_p.apply(2, 2, false)
	_p.apply(1, 2, true)
	assert_eq(_p.stage, 2, "SC-401: não volta")
	assert_push_error("volta")


func test_same_stage_is_a_no_op() -> void:
	_p.apply(1, 1, false)
	_degraded.clear()
	_p.apply(1, 2, true)
	assert_eq(_p.state, PageDegradation.Phase.STEADY)
	assert_eq(_p.next_stage, 2, "guarda o próximo para a ameaça")
	assert_eq(_degraded, [])


func test_threat_only_when_next_is_higher() -> void:
	_p.apply(0, 0, false)
	_p.on_closing()
	assert_eq(_p.state, PageDegradation.Phase.STEADY, "onda 1→2: ambas 0, sem ameaça")
	_p.apply(0, 1, false)
	_p.on_closing()
	assert_eq(_p.state, PageDegradation.Phase.THREATENED)
	_p.apply(1, 1, true)
	assert_eq(_p.state, PageDegradation.Phase.TRANSITIONING, "a troca desliga a ameaça")


func test_snap_finishes_the_transition() -> void:
	_p.apply(0, 1, false)
	_p.apply(1, 2, true)
	_p.snap()
	assert_eq(_p.state, PageDegradation.Phase.STEADY)
	assert_eq(_p.shown_stage, 1, "a loja abre: encaixa na hora")


func test_chapter_waves_follow_the_data() -> void:
	var chapter: ChapterData = load("res://data/chapters/chapter_1.tres")
	var seen: Array[int] = []
	for slot: int in chapter.waves.size():
		seen.append(chapter.stage_for_wave(slot))
	assert_eq(seen, [0, 0, 1, 1, 2, 2, 3, 3, 3], "SC-401: acumulados nas 9 ondas")
	assert_eq(chapter.stage_after(chapter.waves.size() - 1), chapter.boss_stage)
	assert_eq(chapter.boss_stage, 3)
	assert_eq(chapter.validate_stages(), "", "não decrescente")
