extends GutTest
## T304 A loja na cena real, sem tela (003 FR-301, FR-306, FR-309..FR-312, SC-302, SC-303; D-058).

const MAIN_SCENE := preload("res://src/main/main.tscn")

var _main: Node2D
var _shop: Shop
var _player: Player
var _field: LetterField
var _caster: Caster


func before_each() -> void:
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_shop = _main.get_node("Shop")
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_field = _main.get_node("World/LetterField")
	_caster = _main.get_node("Caster")
	(_main.get_node("World/EnemyManager") as EnemyManager).dissolve_all()


func after_each() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0


func _card(id: StringName) -> ShopItemData:
	for c: ShopItemData in _shop.tuning.deck:
		if c.id == id:
			return c
	return null


## Reabre a loja na mesma onda e força a carta `id` na vaga 0, pelo preço da onda.
func _offer(id: StringName) -> void:
	_shop.open(_shop.offer.wave)
	_shop.offer.cards[0] = _card(id)
	_shop.offer.prices[0] = _shop.offer.price_of(_card(id), _shop.offer.wave)


func test_wave_end_pays_the_tithe_and_shop_opens_and_closes() -> void:
	var opened: Array[int] = []
	var on_open := func(w: int) -> void: opened.append(w)
	EventBus.shop_opened.connect(on_open)
	var before: int = GameState.gold_ink
	EventBus.wave_ended.emit(1)
	assert_eq(GameState.gold_ink, before + _shop.tuning.wave_clear_ink, "dízimo (D-058)")
	await wait_seconds(_main.get("between_waves") + 0.3)
	EventBus.shop_opened.disconnect(on_open)
	assert_eq(opened, [1] as Array[int], "a loja abriu depois da onda 1")
	assert_false(_shop.is_open, "fora do jogo de verdade ela fecha sozinha")


func test_buying_the_shelf_grows_the_atril_up_to_8() -> void:
	GameState.gold_ink = 999
	_shop.open(1)
	for i: int in 3:
		_offer(&"new_shelf")
		assert_true(_shop.buy(0))
	assert_eq(_field.atril.capacity, 8, "SC-302")
	assert_false(GameState.run_stats.can_offer(_card(&"new_shelf")))


func test_buying_without_ink_does_nothing() -> void:
	GameState.gold_ink = 0
	_shop.open(1)
	_offer(&"double_inkwell")
	assert_false(_shop.buy(0))
	assert_eq(GameState.run_stats.value(&"double_letter_chance"), 0.0)


func test_buying_charges_the_price() -> void:
	GameState.gold_ink = 20
	_shop.open(3)
	_offer(&"double_inkwell")
	var price: int = _shop.offer.prices[0]
	assert_true(_shop.buy(0))
	assert_eq(GameState.gold_ink, 20 - price)
	assert_almost_eq(GameState.run_stats.value(&"double_letter_chance"), 0.1, 0.001)


func test_apocrypha_card_unlocks_the_word_at_once() -> void:
	GameState.unlocked_words.clear()
	GameState.gold_ink = 999
	_shop.open(1)
	_offer(&"apocrypha_fides")
	_field.atril.set_capacity(6)
	for ch: String in "FIDES":
		_field.collect(ch, false)
	assert_ne(_field.atril.state(_field.lexicon), Atril.Status.VALID, "antes da compra não vale")
	_field.atril.take_all()
	assert_true(_shop.buy(0))
	for ch: String in "FIDES":
		_field.collect(ch, false)
	assert_eq(_field.atril.state(_field.lexicon), Atril.Status.VALID, "vale na hora (SC-303)")
	GameState.unlocked_words.clear()


func test_reroll_spends_ink() -> void:
	# 016 (rules-agent): reroll 3, +2 a cada vez.
	GameState.gold_ink = 7
	_shop.open(1)
	assert_true(_shop.reroll())
	assert_eq(GameState.gold_ink, 4)
	assert_false(_shop.reroll(), "o 2º custa 5")


func test_blessings_never_show_up_in_the_shop() -> void:
	# SC-1603 (016): os 7 itens pequenos viraram bênçãos do level-up.
	var gone: Array[StringName] = [&"lodestone", &"sandals", &"blessed_candle", &"copyist_lenses",
		&"rosary", &"alms_purse", &"fine_quill"]
	for c: ShopItemData in _shop.tuning.deck:
		assert_false(gone.has(c.id), "%s saiu do baralho" % c.id)
	GameState.gold_ink = 9999
	for w: int in range(1, 10):
		_shop.open(w)
		for r: int in 5:
			for c: ShopItemData in _shop.offer.cards:
				if c != null:
					assert_false(gone.has(c.id), "%s na oferta" % c.id)
			_shop.reroll()
