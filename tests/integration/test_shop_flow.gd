extends GutTest
## T312 Loja de verdade entre as ondas, só pelo teclado (003 FR-301, FR-306..FR-308, FR-314, SC-305).
## O Main liga a loja manual com a meta "shop_manual": ela pausa a árvore e espera o Enter.

const MAIN_SCENE := preload("res://src/main/main.tscn")

var _main: Node2D
var _shop: Shop
var _screen: ShopScreen
var _started: Array[int] = []


func before_each() -> void:
	_started.clear()
	_main = MAIN_SCENE.instantiate()
	_main.set_meta(&"shop_manual", true)
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_shop = _main.get_node("Shop")
	_screen = _main.get_node("ShopScreen")
	(_main.get_node("World/Player") as Player).auto_attack.enabled = false
	EventBus.wave_started.connect(_on_started)


func after_each() -> void:
	EventBus.wave_started.disconnect(_on_started)
	get_tree().paused = false
	TimeScale.reset()


func _on_started(index: int, _d: float) -> void:
	_started.append(index)


func _press(action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	_screen.handle_input(ev)


## Abre a loja como no jogo: fim de onda, espera, pausa. O timer da árvore ignora a pausa
## (o wait_seconds do GUT pararia junto com a árvore quando a loja abre).
func _open_after_wave_1() -> void:
	EventBus.wave_ended.emit(1)
	await get_tree().create_timer(_shop.tuning.open_delay + 0.2, true).timeout


func test_shop_opens_paused_and_enter_starts_the_next_wave() -> void:
	await _open_after_wave_1()
	assert_true(_shop.is_open)
	assert_true(get_tree().paused, "o jogo fica parado na loja")
	assert_true(_screen.visible)
	_press(&"shop_next")
	assert_false(_shop.is_open)
	assert_false(get_tree().paused)
	assert_has(_started, 2, "Enter começa a onda 2")
	assert_true(_screen.is_closing(), "a tela sai em dithering")
	await get_tree().create_timer(0.6, true).timeout
	assert_false(_screen.visible)


func test_keyboard_selects_buys_locks_and_rerolls() -> void:
	GameState.gold_ink = 0
	await _open_after_wave_1()
	GameState.gold_ink = 100
	assert_eq(_screen.selected, 0)
	_press(&"move_right")
	_press(&"move_right")
	assert_eq(_screen.selected, 2)
	_press(&"move_left")
	assert_eq(_screen.selected, 1)
	var price: int = _shop.offer.prices[1]
	_press(&"cast")
	assert_true(_shop.offer.is_sold(1), "Espaço compra")
	assert_eq(GameState.gold_ink, 100 - price)
	_press(&"move_right")
	_press(&"shop_lock")
	assert_eq(_shop.offer.locked_slot(), 2, "L trava")
	var ink: int = GameState.gold_ink
	_press(&"shop_reroll")
	assert_eq(GameState.gold_ink, ink - _shop.tuning.reroll_base, "R rerola")
	assert_eq(_shop.offer.locked_slot(), 2, "a travada fica")


func test_selection_wraps_and_stays_in_range() -> void:
	await _open_after_wave_1()
	_press(&"move_left")
	assert_eq(_screen.selected, _shop.offer.cards.size() - 1, "← na primeira vai para a última")
	_press(&"move_right")
	assert_eq(_screen.selected, 0)


func test_buying_without_ink_shakes_and_keeps_ink() -> void:
	await _open_after_wave_1()
	GameState.gold_ink = 0
	_press(&"cast")
	assert_false(_shop.offer.is_sold(0))
	assert_eq(_screen.card_state(0), &"no_money")


func test_game_input_is_ignored_while_shopping() -> void:
	await _open_after_wave_1()
	var field: LetterField = _main.get_node("World/LetterField")
	field.collect("L", false)
	var caster: Caster = _main.get_node("Caster")
	_press(&"cast")  # Espaço compra, não conjura
	assert_eq(field.atril.size(), 1, "o atril não foi usado")
	assert_false(caster.combo_book.is_open())
