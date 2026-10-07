extends GutTest
## 012 F1: dados do Cap. 2 (T1200 §1–2), liberação ao vencer o Cap. 1 (D-107 1a) e abertura
## (virada de página; a abertura do escriba é só do Cap. 1).

const CH2: ChapterData = preload("res://data/chapters/chapter_2.tres")
const ROSTER: CharacterRoster = preload("res://data/player/roster.tres")


func after_each() -> void:
	Progress.reset()


func test_chapter_2_has_nine_waves_in_order() -> void:
	assert_eq(CH2.chapter, 2)
	assert_eq(CH2.waves.size(), 9, "D-102: 9 ondas")
	for i: int in CH2.waves.size():
		assert_eq(CH2.waves[i].chapter, 2)
		assert_eq(CH2.waves[i].index, i + 1)
	assert_eq(CH2.validate_stages(), "", "o estágio da página nunca volta")


func test_wave_3_introduces_the_moth_mother_alone() -> void:
	var w3: WaveData = CH2.waves[2]
	assert_eq(w3.groups.size(), 1)
	assert_eq(w3.groups[0].enemy.id, &"moth_mother")
	for i: int in 2:
		for g: SpawnGroup in CH2.waves[i].groups:
			assert_ne(g.enemy.id, &"moth_mother", "não aparece antes da onda 3")


func test_chapter_2_waves_are_denser_than_chapter_1() -> void:
	var ch1: ChapterData = load("res://data/chapters/chapter_1.tres")
	# A onda 1 ficou sem Traças pelo A1 da T1200 (recuo previsto); a curva fica acima a partir da 2.
	for i: int in [1, 8]:
		assert_gt(_end_rate(CH2.waves[i]), _end_rate(ch1.waves[i]), "onda %d" % (i + 1))


func test_chapter_2_arena_is_valid_and_has_more_holes() -> void:
	assert_eq(CH2.arena.chapter, 2)
	assert_eq(CH2.arena.validate(), "")
	var ch1: ChapterData = load("res://data/chapters/chapter_1.tres")
	assert_gt(CH2.arena.obstacles.size(), ch1.arena.obstacles.size(), "biblioteca roída: mais furos")


func test_chapter_2_opens_after_winning_chapter_1() -> void:
	assert_true(Progress.is_chapter_open(0))
	assert_false(Progress.is_chapter_open(1))
	Progress.chapters_won.append(1)
	assert_true(Progress.is_chapter_open(1))


func test_unlock_all_opens_every_chapter() -> void:
	Progress.debug_all = true
	assert_true(Progress.is_chapter_open(1))


func test_chapter_2_opens_with_the_page_turn_and_no_scribe_intro() -> void:
	for id: StringName in [&"anselmo", &"tome"]:
		var q: Array[StringName] = CutsceneScreen.pending_intro(CH2, ROSTER.by_id(id))
		assert_eq(q, [&"c2_00"] as Array[StringName], "%s: só a virada de página" % id)
	var s: CutsceneScript = CutsceneScript.load_file(CutsceneScript.DIR + "c2_00.json")
	assert_gt(s.events.size(), 0)


func _end_rate(w: WaveData) -> float:
	var total: float = 0.0
	for g: SpawnGroup in w.groups:
		if g.end_time >= w.duration:
			total += g.spawn_rate_end
	return total
