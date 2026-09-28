extends GutTest
## T302 ShopOffer (003 FR-303..FR-308, SC-301, SC-302, SC-304; D-058).

const TUNING := preload("res://data/shop/shop_tuning.tres")
const ITEMS_DIR := "res://data/shop/items/"

var _deck: Array[ShopItemData] = []
var _stats: RunStats
var _rng: RandomNumberGenerator
var _offer: ShopOffer
var _none: Array[StringName] = []


func before_each() -> void:
	_deck.clear()
	for f: String in DirAccess.get_files_at(ITEMS_DIR):
		if f.ends_with(".tres"):
			_deck.append(load(ITEMS_DIR + f))
	_stats = RunStats.new(load("res://data/player/anselmo.tres"))
	_rng = RandomNumberGenerator.new()
	_rng.seed = 42
	_offer = ShopOffer.new(_deck, TUNING)


func _card(id: StringName) -> ShopItemData:
	for c: ShopItemData in _deck:
		if c.id == id:
			return c
	return null


func _ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for c: ShopItemData in _offer.cards:
		out.append(c.id if c != null else &"")
	return out


func test_three_items_and_one_apocrypha() -> void:
	_offer.open_visit(1, _stats, _none, _rng)
	assert_eq(_offer.cards.size(), 4)
	var kinds: Array[StringName] = []
	for c: ShopItemData in _offer.cards:
		kinds.append(c.kind)
	assert_eq(kinds.count(&"item"), 3)
	assert_eq(kinds.count(&"apocrypha"), 1)
	var ids := _ids()
	for id: StringName in ids:
		assert_eq(ids.count(id), 1, "sem repetição na oferta")


func test_same_seed_same_offer() -> void:
	_offer.open_visit(3, _stats, _none, _rng)
	var first := _ids()
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 42
	var other := ShopOffer.new(_deck, TUNING)
	other.open_visit(3, _stats, _none, rng2)
	var second: Array[StringName] = []
	for c: ShopItemData in other.cards:
		second.append(c.id)
	assert_eq(second, first, "SC-301")


func test_apocrypha_slot_becomes_an_item_when_all_are_unlocked() -> void:
	var all: Array[StringName] = [&"purgo", &"fides", &"lumen", &"gloria", &"verbum"]
	_offer.open_visit(2, _stats, all, _rng)
	for c: ShopItemData in _offer.cards:
		assert_eq(c.kind, &"item")


func test_unlocked_apocrypha_is_never_offered() -> void:
	var some: Array[StringName] = [&"purgo", &"fides", &"lumen", &"gloria"]
	for v: int in 10:
		_offer.open_visit(v + 1, _stats, some, _rng)
		assert_has(_ids(), &"apocrypha_verbum", "só sobrou o VERBUM")


func test_capped_item_leaves_the_deck() -> void:
	var shelf := _card(&"new_shelf")
	for i: int in 3:
		_stats.apply(shelf)
	for v: int in 20:
		_offer.open_visit(1, _stats, _none, _rng)
		assert_does_not_have(_ids(), &"new_shelf", "SC-302")


func test_price_grows_with_the_wave() -> void:
	var shelf := _card(&"new_shelf")
	assert_eq(_offer.price_of(shelf, 1), 9)
	assert_eq(_offer.price_of(shelf, 8), roundi(9 * 1.7))


func test_buy_needs_ink_and_marks_sold() -> void:
	_offer.open_visit(1, _stats, _none, _rng)
	var price: int = _offer.prices[0]
	assert_eq(_offer.buy(0, price - 1), -1, "sem tinta não compra")
	assert_false(_offer.is_sold(0))
	assert_eq(_offer.buy(0, price), price)
	assert_true(_offer.is_sold(0))
	assert_eq(_offer.buy(0, 999), -1, "vendida não vende de novo")


func test_reroll_cost_grows_within_the_visit_and_keeps_sold() -> void:
	_offer.open_visit(1, _stats, _none, _rng)
	_offer.buy(0, 999)
	var sold_id: StringName = _offer.cards[0].id
	assert_eq(_offer.reroll_cost(), 5)
	assert_eq(_offer.reroll(4, _stats, _none, _rng), -1, "sem tinta não rerola")
	assert_eq(_offer.reroll(100, _stats, _none, _rng), 5)
	assert_eq(_offer.cards[0].id, sold_id, "a vendida fica no lugar")
	assert_eq(_offer.reroll_cost(), 8)
	_offer.reroll(100, _stats, _none, _rng)
	assert_eq(_offer.reroll_cost(), 11)
	_offer.open_visit(2, _stats, _none, _rng)
	assert_eq(_offer.reroll_cost(), 5, "zera na visita seguinte")


func test_lock_survives_reroll_and_next_visit_at_old_price() -> void:
	_offer.open_visit(1, _stats, _none, _rng)
	var locked_id: StringName = _offer.cards[1].id
	var old_price: int = _offer.prices[1]
	assert_true(_offer.toggle_lock(1))
	for i: int in 3:
		_offer.reroll(999, _stats, _none, _rng)
		assert_eq(_offer.cards[1].id, locked_id, "a travada fica")
	_offer.open_visit(8, _stats, _none, _rng)
	var at: int = _ids().find(locked_id)
	assert_ne(at, -1, "volta na próxima visita (SC-304)")
	assert_eq(_offer.prices[at], old_price, "pelo preço da visita em que foi travada")


func test_only_one_lock() -> void:
	_offer.open_visit(1, _stats, _none, _rng)
	_offer.toggle_lock(0)
	_offer.toggle_lock(2)
	assert_eq(_offer.locked_slot(), 2, "travar outra troca a trava")
	_offer.toggle_lock(2)
	assert_eq(_offer.locked_slot(), -1, "travar de novo destrava")


func test_buying_the_locked_card_clears_the_lock() -> void:
	_offer.open_visit(1, _stats, _none, _rng)
	_offer.toggle_lock(0)
	_offer.buy(0, 999)
	assert_eq(_offer.locked_slot(), -1)
	_offer.open_visit(2, _stats, _none, _rng)
	assert_eq(_offer.locked_slot(), -1)
