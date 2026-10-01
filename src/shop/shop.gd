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
var _visits: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	offer = ShopOffer.new(tuning.deck, tuning)


## Abre a loja depois da onda `wave` (1-based).
func open(wave: int) -> void:
	var owned: Array[StringName] = []
	var lo: Loadout = GameState.loadout
	if lo != null:
		owned.append_array(lo.owned_ids())
	if GameState.repulse_level > 0:
		owned.append(GameState.repulse.id)
	# 1ª loja com o espaço 2 vazio: as vagas de item são armas (rules-agent §7).
	var first: bool = _visits == 0 and lo != null and not lo.is_full()
	_visits += 1
	offer.open_visit(wave, GameState.run_stats, GameState.unlocked_words, GameState.rng, owned, first)
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


## Comprar esta carta troca a arma ativa? (os 2 espaços cheios; a tela pede confirmação)
func replaces_weapon(i: int) -> bool:
	if i < 0 or i >= offer.cards.size() or offer.cards[i] == null or offer.cards[i].kind != &"weapon":
		return false
	return GameState.loadout != null and GameState.loadout.is_full()


func _apply(card: ShopItemData) -> void:
	if card.kind == &"weapon" or card.kind == &"passive":
		GameState.run_stats.apply(card)  # sem stat: só conta a compra (max_buys)
	match card.kind:
		&"weapon":
			RunUpgrade.equip_weapon(card.weapon)
			return
		&"passive":
			RunUpgrade.level_repulse()
			return
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
	RunUpgrade.apply(card, player, letter_field)
