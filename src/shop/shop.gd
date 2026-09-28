class_name Shop
extends Node
## A loja no jogo (003 FR-301..FR-311). Liga o ShopOffer à partida: cobra a tinta, aplica o item
## no RunStats e nos sistemas vivos (atril, velas) ou libera o apócrifo. A tela (ShopScreen) só
## chama esta API; os testes e a sonda também.

@export var tuning: ShopTuning = preload("res://data/shop/shop_tuning.tres")

var player: Player
var letter_field: LetterField
var offer: ShopOffer
var is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	offer = ShopOffer.new(tuning.deck, tuning)


## Abre a loja depois da onda `wave` (1-based).
func open(wave: int) -> void:
	offer.open_visit(wave, GameState.run_stats, GameState.unlocked_words, GameState.rng)
	is_open = true
	EventBus.shop_opened.emit(wave)


func close() -> void:
	if not is_open:
		return
	is_open = false
	EventBus.shop_closed.emit()


## Compra a carta `i`. Retorna true se comprou.
func buy(i: int) -> bool:
	var price: int = offer.buy(i, GameState.gold_ink)
	if price < 0:
		return false
	var card: ShopItemData = offer.cards[i]
	GameState.gold_ink -= price
	_apply(card)
	EventBus.item_bought.emit(card, price)
	return true


## Rerola a oferta. Retorna true se pagou.
func reroll() -> bool:
	var cost: int = offer.reroll(GameState.gold_ink, GameState.run_stats, GameState.unlocked_words, GameState.rng)
	if cost < 0:
		return false
	GameState.gold_ink -= cost
	EventBus.shop_rerolled.emit(cost)
	return true


func toggle_lock(i: int) -> bool:
	return offer.toggle_lock(i)


func can_afford(i: int) -> bool:
	return i >= 0 and i < offer.cards.size() and offer.cards[i] != null \
		and not offer.is_sold(i) and GameState.gold_ink >= offer.prices[i]


func _apply(card: ShopItemData) -> void:
	if card.kind == &"apocrypha":
		# A palavra vale na hora (FR-311); o VERBUM libera o B no mesmo instante (D-057).
		GameState.unlock_word(card.word)
		if letter_field != null:
			letter_field.emit_atril()
		return
	var stats: RunStats = GameState.run_stats
	if stats.is_capped(card) and card.after_cap == &"heal_only":
		if player != null:
			player.heal(tuning.heal_only_candles)
		return
	stats.apply(card)
	match card.stat:
		&"atril_capacity":
			if letter_field != null:
				letter_field.atril.set_capacity(stats.int_value(&"atril_capacity"))
				letter_field.emit_atril()
		&"max_candles":
			if player != null:
				player.vitals.max_candles = stats.int_value(&"max_candles")
				player.heal(1)
