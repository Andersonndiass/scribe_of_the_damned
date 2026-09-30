extends GutTest
## 017 T1727 (SC-1702): o menu abre a cada pedido, 1 das 3 continua a palavra, câmera lenta, o
## escriba para, setas + Espaço e clique escolhem, a letra se perde no fim do tempo, fila de 1,
## trava do começo, Lentes somam tempo, fim de onda descarta; a Traça rouba e devolve.

const MAIN_SCENE := preload("res://src/main/main.tscn")
const MOTH := preload("res://data/enemies/moth.tres")
const STEP := 0.05

var _main: Node2D
var _player: Player
var _field: LetterField
var _menu: LetterMenu
var _manager: EnemyManager
var _events: Array[StringName] = []


func before_each() -> void:
	_events.clear()
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_player = _main.get_node("World/Player")
	_player.arsenal.enabled = false
	_field = _main.get_node("World/LetterField")
	_menu = _field.menu
	_menu.set_process(false)
	_manager = _main.get_node("World/EnemyManager")
	_manager.dissolve_all()
	EventBus.letter_lost.connect(_on_lost)
	EventBus.letter_offer_dropped.connect(_on_dropped)


func after_each() -> void:
	EventBus.letter_lost.disconnect(_on_lost)
	EventBus.letter_offer_dropped.disconnect(_on_dropped)
	_menu.cancel()
	TimeScale.reset()
	GameState.letter_menu_open = false


func _on_lost() -> void:
	_events.append(&"lost")


func _on_dropped() -> void:
	_events.append(&"dropped")


## Avança o relógio do menu em `seconds` (tempo de jogo a ×1), como o _process faria.
func _advance(seconds: float) -> void:
	var n: int = roundi(seconds / STEP)
	for k: int in n:
		_menu._process(STEP * TimeScale.factor_product())


func _open() -> void:
	assert_true(_menu.offer())
	_advance(STEP)
	assert_true(_menu.is_open(), "abriu")


func test_offer_roll_always_has_one_letter_that_continues() -> void:
	var rng := RandomNumberGenerator.new()
	_field.collect("L", false)
	_field.collect("U", false)
	for k: int in 60:
		rng.seed = k
		var opts: Array[Dictionary] = LetterOfferRoll.roll(_field.atril, _field.lexicon, _field.tuning, _menu.tuning, rng, GameState.unlocked_words)
		assert_eq(opts.size(), 3)
		var seen := {}
		var useful: int = 0
		for o: Dictionary in opts:
			seen[o["letter"]] = true
			if _field.lexicon.is_prefix("LU" + o["letter"], _field.atril.capacity):
				useful += 1
		assert_eq(seen.size(), 3, "3 letras diferentes")
		assert_gte(useful, 1, "ao menos 1 continua LU…")


func test_champion_letter_is_a_rare_vowel_when_possible() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var opts: Array[Dictionary] = LetterOfferRoll.roll(_field.atril, _field.lexicon, _field.tuning, _menu.tuning, rng, GameState.unlocked_words, "", true)
	var rare := opts.filter(func(o: Dictionary) -> bool: return o["rare"])
	assert_gte(rare.size(), 1, "atril vazio: há palavras que começam por vogal")


func test_open_slows_time_stops_the_scribe_and_pick_collects() -> void:
	_open()
	assert_true(GameState.letter_menu_open, "escriba parado")
	assert_eq(_player.input_direction(), Vector2.ZERO)
	_advance(0.2)
	assert_almost_eq(TimeScale.factor_product(), _menu.tuning.slow_factor, 0.001, "câmera lenta ×0,2")
	var letter: String = _menu.options[_menu.focus]["letter"]
	assert_true(_menu.pick(_menu.focus))
	assert_eq(_field.atril.text(), letter, "a letra foi para o atril")
	assert_false(_menu.is_open())
	assert_false(GameState.letter_menu_open)
	_advance(1.0)
	assert_almost_eq(TimeScale.factor_product(), 1.0, 0.001, "a câmera lenta sai depois do intervalo")


func test_pick_guard_blocks_the_first_instant() -> void:
	_open()
	assert_false(_menu.pick(0), "tecla apertada antes de abrir não escolhe")
	_advance(0.15)
	assert_true(_menu.pick(0))


func test_time_runs_out_and_the_letter_is_lost() -> void:
	_open()
	_advance(_menu.tuning.menu_time - 0.2)
	assert_true(_menu.is_open())
	_advance(0.3)
	assert_false(_menu.is_open())
	assert_has(_events, &"lost")
	assert_eq(_field.atril.size(), 0, "nada entrou no atril")


func test_keys_move_focus_and_pick() -> void:
	_open()
	_advance(0.15)
	assert_eq(_menu.focus, 1, "começa no meio")
	var ev := InputEventAction.new()
	ev.action = &"letter_next"
	ev.pressed = true
	_menu._input(ev)
	assert_eq(_menu.focus, 2)
	var letter: String = _menu.options[2]["letter"]
	ev.action = &"letter_pick"
	_menu._input(ev)
	assert_eq(_field.atril.text(), letter)


func test_click_on_a_card_picks_it() -> void:
	_open()
	_advance(0.15)
	var view: LetterMenuView = _menu.get_node("View")
	view._process(0.0)
	var letter: String = _menu.options[0]["letter"]
	assert_true(_menu.pick(0), "o clique chama pick da carta")
	assert_eq(_field.atril.text(), letter)
	assert_true(view.card_rect(0).size == Vector2(28, 28), "carta 28×28 (design-agent)")


func test_queue_holds_one_and_drops_the_rest() -> void:
	_open()
	assert_true(_menu.offer(), "1 na fila")
	assert_false(_menu.offer(), "o excedente se perde")
	assert_has(_events, &"dropped")
	assert_eq(_menu.queued(), 1)


func test_lenses_add_menu_time() -> void:
	GameState.run_stats.apply(load("res://data/blessings/copyist_lenses.tres"))
	_open()
	assert_almost_eq(_menu.total, _menu.tuning.menu_time + 0.5, 0.001)


func test_wave_end_discards_the_menu() -> void:
	_open()
	_menu.offer()
	EventBus.wave_ended.emit(1)
	assert_false(_menu.is_open())
	assert_eq(_menu.queued(), 0)
	assert_almost_eq(TimeScale.factor_product(), 1.0, 0.001)


func test_full_or_ready_atril_waits_in_the_queue() -> void:
	for ch: String in "LUX":
		_field.collect(ch, false)
	assert_true(_menu.offer())
	_advance(STEP)
	assert_false(_menu.is_open(), "palavra pronta: o menu espera")
	assert_eq(_menu.queued(), 1)


func test_moth_steals_the_last_letter_and_gives_it_back() -> void:
	_field.collect("L", false)
	_field.collect("U", false)
	var i: int = _manager.spawn(MOTH, _manager.player_body())
	MOTH.behavior.tick(_manager, i, 0.016)
	assert_eq(_field.atril.text(), "L", "roubou o U")
	assert_eq(_manager.carried[i], "U")
	_manager.kill(i)
	assert_gte(_menu.queued(), 1, "a letra volta como menu (na frente da fila)")
	_advance(STEP)
	var letters: Array = _menu.options.map(func(o: Dictionary) -> String: return o["letter"])
	assert_has(letters, "U", "a letra roubada é uma das opções")
