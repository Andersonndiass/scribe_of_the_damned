extends GutTest
## 012 F6 (SC-1201, SC-1210): vencer a Mãe emite chapter_completed(2) e grava no Progress (jogo de
## verdade); as cenas do Cap. 2 carregam com os 5 escribas.

const MAIN_SCENE := preload("res://src/main/main.tscn")
const MAE: BossData = preload("res://data/bosses/mae_tracas.tres")
const CH2: ChapterData = preload("res://data/chapters/chapter_2.tres")
const ROSTER: CharacterRoster = preload("res://data/player/roster.tres")

var _completed: Array[int] = []


func after_each() -> void:
	Progress.reset()
	GameState.run_counts = false
	GameState.picked_character = &""
	PlayArea.reset()


func _on_completed(c: int) -> void:
	_completed.append(c)


func test_killing_the_mother_completes_chapter_2() -> void:
	var main: Node2D = MAIN_SCENE.instantiate()
	var ch: ChapterData = CH2.duplicate()
	var fast: BossData = MAE.duplicate()
	fast.enter_time = 0.1
	fast.enter_rise_start = 0.0
	fast.enter_rise_end = 0.05
	fast.death_time = 0.2
	fast.death_burst_at = 0.1
	fast.chapter_end_delay = 0.2
	ch.boss = fast
	main.set("chapter", ch)
	add_child_autofree(main)
	main.get_node("WaveDirector").stop()
	var boss: Boss = main.get_node("World/Boss")
	EventBus.chapter_completed.connect(_on_completed)
	main.call("start_boss")
	await wait_seconds(0.3)
	GameState.run_counts = true
	boss.filter.phase_index = 2
	boss.filter.hp = 10
	boss.take(50, &"mortis", 1)
	await wait_seconds(0.6)
	EventBus.chapter_completed.disconnect(_on_completed)
	assert_eq(_completed, [2] as Array[int], "SC-1201")
	assert_true(Progress.chapters_won.has(2))
	assert_true(Progress.is_chapter_open(2), "o Cap. 3 abriria (quando tiver dados)")


func test_chapter_2_cutscenes_load_for_every_scribe() -> void:
	for id: StringName in [CH2.boss_cutscene, CH2.outro_cutscene]:
		assert_ne(id, &"", "o capítulo tem as duas cenas")
		for c: PlayerData in ROSTER.characters:
			GameState.picked_character = c.id
			var s: CutsceneScript = CutsceneScript.load_file(CutsceneScript.DIR + String(id) + ".json")
			assert_gt(s.events.size(), 0, "%s com %s" % [id, c.id])
			for e: Dictionary in s.events:
				assert_ne(str(e.get("speaker", "")), "@player", "o falante virou o escriba")
