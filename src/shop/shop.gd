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
	# 1ª loja com o espaço 2 vazio: as vagas de item são armas (rules-agent §7). Nas outras, com
	# espaço vazio (depois de vender), 1 vaga é arma (D-103 resposta 3a).
	var empty_slot: bool = lo != null and not lo.is_full()
	var first: bool = _visits == 0 and empty_slot
	_visits += 1
	offer.open_visit(wave, GameState.run_stats, GameState.unlocked_words, GameState.rng, owned, first, empty_slot)
	is_open = true
	EventBus.shop_opened.emit(wave)


func close() -> void:
	if not is_open:
		return
	is_open = false
	EventBus.shop_closed.emit()


## Compra a carta `i`. Relíquia com os 2 espaços cheios: `relic_slot` diz qual sai (sem ele, a 1ª).
## O que sai é vendido na hora (D-103 resposta 2a). Retorna true se comprou.
func buy(i: int, relic_slot: int = -1) -> bool:
	var price: int = offer.buy(i, GameState.gold_ink)
	if price < 0:
		return false
	var card: ShopItemData = offer.cards[i]
	GameState.gold_ink -= price
	_apply(card, price, relic_slot)
	EventBus.item_bought.emit(card, price)
	_refresh_owned()
	return true


func _refresh_owned() -> void:
	if GameState.loadout != null:
		offer.set_owned(GameState.loadout.owned_ids())


# --- Venda (019; rules-agent T1900 §c): nunca dá lucro; vale mais com os postos ---

## Preço de venda de algo que custou `paid` e tem `ranks` postos.
func sell_value(paid: int, ranks: int) -> int:
	var hi: int = maxi(tuning.sell_min, paid - tuning.sell_margin)
	return clampi(floori(tuning.sell_rate * float(paid)) + tuning.sell_per_rank * ranks, tuning.sell_min, hi)


func can_sell_weapon(slot: int) -> bool:
	var lo: Loadout = GameState.loadout
	return lo != null and slot >= 0 and slot < lo.slots.size() and lo.slots[slot] != null and lo.weapon_count() > 1


func sell_price_weapon(slot: int) -> int:
	if GameState.loadout == null or slot < 0 or slot >= GameState.loadout.slots.size() or GameState.loadout.slots[slot] == null:
		return -1
	var s: WeaponSlot = GameState.loadout.slots[slot]
	return sell_value(s.paid if s.paid > 0 else tuning.starter_ref_price, s.bought())


func sell_weapon(slot: int) -> bool:
	if not can_sell_weapon(slot):
		EventBus.shop_purchase_denied.emit()
		return false
	var price: int = sell_price_weapon(slot)
	var w: WeaponData = GameState.loadout.slots[slot].weapon
	RunUpgrade.remove_weapon(slot, &"sold")
	GameState.gold_ink += price
	EventBus.item_sold.emit(&"weapon", w.id, price)
	_refresh_owned()
	return true


func can_sell_relic(slot: int) -> bool:
	return GameState.loadout != null and GameState.loadout.relic(slot) != null


func sell_price_relic(slot: int) -> int:
	var r: RelicSlot = GameState.loadout.relic(slot) if GameState.loadout != null else null
	return sell_value(r.paid, r.bought()) if r != null else -1


func sell_relic(slot: int) -> bool:
	if not can_sell_relic(slot):
		EventBus.shop_purchase_denied.emit()
		return false
	var price: int = sell_price_relic(slot)
	var rd: RelicData = GameState.loadout.relic(slot).relic
	RunUpgrade.remove_relic(slot, &"sold")
	GameState.gold_ink += price
	EventBus.item_sold.emit(&"relic", rd.id, price)
	_refresh_owned()
	return true


func can_sell_potion(i: int) -> bool:
	return GameState.potions != null and i >= 0 and i < potion_count() and GameState.potions.charges(potion_at(i).id) > 0


func sell_price_potion(i: int) -> int:
	return maxi(tuning.sell_min, floori(tuning.potion_sell_rate * float(potion_price(i))))


## Vende 1 carga da poção `i` (o nível fica).
func sell_potion(i: int) -> bool:
	if not can_sell_potion(i):
		EventBus.shop_purchase_denied.emit()
		return false
	var price: int = sell_price_potion(i)
	GameState.potions.remove_charge(potion_at(i).id)
	GameState.gold_ink += price
	EventBus.item_sold.emit(&"potion", potion_at(i).id, price)
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
	var ok: bool = offer.toggle_lock(i)
	if ok:
		EventBus.shop_lock_toggled.emit(offer.locked_slot() == i)
	return ok


func can_afford(i: int) -> bool:
	return i >= 0 and i < offer.cards.size() and offer.cards[i] != null \
		and not offer.is_sold(i) and GameState.gold_ink >= offer.prices[i]


# --- Prateleira de poções (018 T1816; FR-1809): fixa, fora do sorteio, sem reroll nem trava ---

func potion_count() -> int:
	return GameState.potion_tuning.order.size()


func potion_at(i: int) -> PotionData:
	return GameState.potion_tuning.order[i]


## Preço da poção `i` nesta visita (cresce por onda como os itens).
func potion_price(i: int) -> int:
	return roundi(potion_at(i).base_price * (1.0 + tuning.price_growth * float(offer.wave - 1)))


func can_buy_potion(i: int) -> bool:
	return GameState.potions != null and not GameState.potions.is_full(potion_at(i).id) \
		and GameState.gold_ink >= potion_price(i)


## Compra 1 carga da poção `i` (pode comprar várias vezes até o teto). Retorna true se comprou.
func buy_potion(i: int) -> bool:
	if i < 0 or i >= potion_count() or not can_buy_potion(i):
		return false
	var price: int = potion_price(i)
	GameState.gold_ink -= price
	GameState.potions.add_charge(potion_at(i).id)
	EventBus.potion_bought.emit(potion_at(i).id, price)
	return true


## Comprar esta relíquia troca uma das 2 equipadas? (a tela pede qual)
func replaces_relic(i: int) -> bool:
	if i < 0 or i >= offer.cards.size() or offer.cards[i] == null or offer.cards[i].kind != &"relic":
		return false
	return GameState.loadout != null and GameState.loadout.relics_full()


## Comprar esta carta troca a arma ativa? (os 2 espaços cheios; a tela pede confirmação)
func replaces_weapon(i: int) -> bool:
	if i < 0 or i >= offer.cards.size() or offer.cards[i] == null or offer.cards[i].kind != &"weapon":
		return false
	return GameState.loadout != null and GameState.loadout.is_full()


func _apply(card: ShopItemData, price: int = 0, relic_slot: int = -1) -> void:
	if card.kind == &"weapon" or card.kind == &"relic":
		GameState.run_stats.apply(card)  # sem stat: só conta a compra
	var lo: Loadout = GameState.loadout
	match card.kind:
		&"weapon":
			if lo != null and lo.is_full():
				_sell_on_replace_weapon(lo.active)  # D-103 2a: a que sai é vendida
			RunUpgrade.equip_weapon(card.weapon, price)
			return
		&"relic":
			var replace: int = -1
			if lo != null and lo.relics_full():
				replace = clampi(relic_slot, 0, lo.relics.size() - 1)
				var gone: RelicSlot = lo.relic(replace)
				var value: int = sell_value(gone.paid, gone.bought())
				GameState.gold_ink += value
				EventBus.item_sold.emit(&"relic", gone.relic.id, value)
			RunUpgrade.equip_relic(card.relic, price, replace)
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


func _sell_on_replace_weapon(slot: int) -> void:
	var value: int = sell_price_weapon(slot)
	if value <= 0:
		return
	GameState.gold_ink += value
	EventBus.item_sold.emit(&"weapon", GameState.loadout.slots[slot].weapon.id, value)
