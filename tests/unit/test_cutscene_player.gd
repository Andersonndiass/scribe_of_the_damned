extends GutTest
## T813 Tocador das cutscenes (008 FR-802b, FR-805, FR-806, FR-806b): adiantar (o 1º completa o texto,
## o 2º pula a fala); pular em vários pontos chega ao mesmo estado de assistir, com as marcas em ordem
## e `cutscene_finished` por último; toque curto no Esc não pula; o hit-stop não desacelera; roteiro
## quebrado termina na hora (o jogo não trava).

const SPRITE := "res://assets/placeholders/chr_anselmo_idle.png"
const DT := 1.0 / 60.0

var _cs: CutscenePlayer
var _events: Array = []


func _script() -> Dictionary:
	return {
		"id": "test", "version": 1, "duration": 4.0, "play": "always",
		"actors": {
			"anselmo": {"layer": "actors", "kind": "sprite", "src": SPRITE, "init": {"position": [100, 200], "modulate:a": 0.0}},
		},
		"events": [
			{"t": 0.5, "type": "key", "target": "anselmo", "prop": "modulate:a", "value": 1.0, "ease": "out"},
			{"t": 3.0, "type": "key", "target": "anselmo", "prop": "position", "value": [140, 200], "ease": "in_out"},
			{"t": 1.0, "type": "line", "speaker": "anselmo", "expr": "scared", "key": "CS_C1_01_ANSELMO_1", "end": 2.5},
			{"t": 2.6, "type": "caption", "key": "CS_C1_01_CAPTION_1", "end": 3.5},
			{"t": 1.5, "type": "mark", "id": "music_cue"},
			{"t": 3.9, "type": "mark", "id": "boss_bar_shown"},
		],
	}


func before_each() -> void:
	_cs = CutscenePlayer.new()
	add_child_autofree(_cs)
	_cs.set_process(false)
	_events.clear()
	EventBus.cutscene_mark_reached.connect(_on_mark)
	EventBus.cutscene_finished.connect(_on_finished)


func after_each() -> void:
	EventBus.cutscene_mark_reached.disconnect(_on_mark)
	EventBus.cutscene_finished.disconnect(_on_finished)
	TimeScale.reset()
	Input.action_release(&"pause")


func _on_mark(_id: StringName, mark: StringName) -> void:
	_events.append(mark)


func _on_finished(_id: StringName, skipped: bool) -> void:
	_events.append(&"finished_skipped" if skipped else &"finished")


func _start(d: Dictionary = _script()) -> void:
	assert_true(_cs.load_script(CutsceneScript.parse(d)))
	_cs.play()


func _run_to(t: float) -> void:
	while _cs.is_playing() and _cs.current_time() < t - 0.0001:
		_cs.tick(DT)


func _actor() -> Sprite2D:
	return _cs.stage.get_node("actors/anselmo")


func test_watching_reaches_the_end() -> void:
	_start()
	_run_to(10.0)
	assert_false(_cs.is_playing())
	assert_eq(_events, [&"music_cue", &"boss_bar_shown", &"finished"])
	assert_almost_eq(_actor().position.x, 140.0, 0.01)
	assert_almost_eq(_actor().modulate.a, 1.0, 0.01)


func test_first_press_completes_text_second_jumps_to_line_end() -> void:
	_start()
	_run_to(1.1)
	assert_true(_cs.band.typing(), "a fala está aparecendo")
	_cs.advance()
	assert_false(_cs.band.typing())
	assert_true(_cs.band.has_line(), "texto completo, fala ainda na tela")
	assert_eq(_cs.band.visible_text(), PixelFont.normalize(tr(&"CS_C1_01_ANSELMO_1")))
	_cs.advance()
	assert_almost_eq(_cs.current_time(), 2.5, DT + 0.001, "pulou para o fim da fala")
	assert_false(_cs.band.has_line())
	assert_eq(_events, [&"music_cue"], "a marca no meio do trecho pulado disparou")
	assert_true(_cs.is_playing(), "adiantar não termina a cena")


func test_skip_anywhere_equals_watching() -> void:
	for at: float in [0.0, 1.2, 2.7, 3.95]:
		_events.clear()
		_start()
		_run_to(at)
		_cs.skip()
		assert_false(_cs.is_playing(), "pulou em %s" % at)
		assert_almost_eq(_actor().position.x, 140.0, 0.01, "posição final (pulou em %s)" % at)
		assert_almost_eq(_actor().modulate.a, 1.0, 0.01, "opacidade final (pulou em %s)" % at)
		assert_eq(_events, [&"music_cue", &"boss_bar_shown", &"finished_skipped"], "marcas em ordem e fim por último (pulou em %s)" % at)
		assert_false(_cs.band.has_line(), "sem fala na tela")


func test_short_esc_tap_does_not_skip_but_holding_does() -> void:
	_cs.tuning = _cs.tuning.duplicate()
	_cs.tuning.skip_hold = 0.3
	_cs.set_process(true)
	_start()
	Input.action_press(&"pause")
	await get_tree().create_timer(0.1).timeout
	Input.action_release(&"pause")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(_cs.is_playing(), "toque curto não pula")
	assert_eq(_cs.skip_progress, 0.0, "soltar zera")
	Input.action_press(&"pause")
	await get_tree().create_timer(0.5).timeout
	assert_false(_cs.is_playing(), "segurar pula")
	assert_eq(_events.back(), &"finished_skipped")


func test_hitstop_does_not_slow_the_scene() -> void:
	_cs.set_process(true)
	_start()
	Engine.time_scale = 0.1
	await get_tree().create_timer(0.3, true, false, true).timeout
	assert_gt(_cs.current_time(), 0.2, "a cena anda em tempo real")


func test_broken_script_finishes_at_once() -> void:
	var d: Dictionary = _script()
	d["events"][0]["target"] = "ninguem"
	assert_false(_cs.load_script(CutsceneScript.parse(d)))
	_cs.play()
	assert_false(_cs.is_playing())
	assert_eq(_events, [&"finished"], "fail-open: o fim sai mesmo assim")
	assert_push_error("ator inexistente", "o erro do roteiro é avisado")
