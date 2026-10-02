extends GutTest
## 010 (D-101 6a/7a): o escriba com abertura própria a vê no lugar da C1-01/C1-02 (do Anselmo); a
## fala "@player" da C1-03 vira do escriba, com a variante dele.

const CH1 := preload("res://data/chapters/chapter_1.tres")
const ROSTER := preload("res://data/player/roster.tres")


func after_each() -> void:
	GameState.picked_character = &""


func test_anselmo_keeps_the_chapter_intros() -> void:
	var q: Array[StringName] = CutsceneScreen.pending_intro(CH1, ROSTER.by_id(&"anselmo"))
	assert_has(q, &"c1_01")
	assert_has(q, &"c1_02")


func test_other_scribe_gets_own_intro_instead() -> void:
	var q: Array[StringName] = CutsceneScreen.pending_intro(CH1, ROSTER.by_id(&"tome"))
	assert_eq(q[0], &"intro_tome")
	assert_does_not_have(q, &"c1_01")
	assert_does_not_have(q, &"c1_02")


func test_player_line_becomes_the_scribe() -> void:
	GameState.picked_character = &"beda"
	var s: CutsceneScript = CutsceneScript.load_file(CutsceneScript.DIR + "c1_03.json")
	var line: Dictionary = {}
	for e: Dictionary in s.events:
		if str(e.get("key", "")).begins_with("CS_C1_03_ANSELMO_1"):
			line = e
	assert_eq(line["speaker"], "beda")
	assert_eq(line["key"], "CS_C1_03_ANSELMO_1_BEDA")
	assert_eq(s.errors.size(), 0, "a cena valida com o escriba")
