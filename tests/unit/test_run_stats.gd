extends GutTest
## T300 RunStats (003 FR-309, FR-310; D-058): base = PlayerData; itens somam (% da base, valor
## absoluto) ou multiplicam, sempre com teto; compra única; Círio no teto só acende vela.

var _base: PlayerData
var _stats: RunStats


func _item(stat: StringName, mode: StringName, amount: float, cap: float, max_buys: int = 0) -> ShopItemData:
	var it := ShopItemData.new()
	it.id = StringName("%s_%s" % [stat, mode])
	it.kind = &"item"
	it.stat = stat
	it.mode = mode
	it.amount = amount
	it.cap = cap
	it.max_buys = max_buys
	return it


func before_each() -> void:
	_base = PlayerData.new()
	_base.move_speed = 90.0
	_base.attack_interval = 0.8
	_base.magnet_radius = 40.0
	_base.atril_capacity = 5
	_base.start_candles = 3
	_stats = RunStats.new(_base)


func test_starts_equal_to_the_base() -> void:
	assert_eq(_stats.value(&"move_speed"), 90.0)
	assert_eq(_stats.value(&"attack_interval"), 0.8)
	assert_eq(_stats.value(&"magnet_radius"), 40.0)
	assert_eq(_stats.value(&"atril_capacity"), 5.0)
	assert_eq(_stats.value(&"max_candles"), 3.0)
	assert_eq(_stats.value(&"target_bonus_add"), 0.0)
	assert_eq(_stats.value(&"double_letter_chance"), 0.0)
	assert_eq(_stats.value(&"heresy_stun_mul"), 1.0)
	assert_eq(_stats.value(&"gold_mul"), 1.0)


func test_percent_of_base_is_additive_and_capped() -> void:
	var sandals := _item(&"move_speed", &"percent", 0.10, 135.0)
	for i: int in 3:
		_stats.apply(sandals)
	assert_almost_eq(_stats.value(&"move_speed"), 117.0, 0.001, "+10% da base, 3×")
	for i: int in 5:
		_stats.apply(sandals)
	assert_eq(_stats.value(&"move_speed"), 135.0, "teto de +50%")
	assert_false(_stats.can_offer(sandals), "no teto sai do baralho")


func test_multiplicative_goes_down_to_a_floor() -> void:
	var quill := _item(&"attack_interval", &"mul", 0.85, 0.40)
	_stats.apply(quill)
	assert_almost_eq(_stats.value(&"attack_interval"), 0.68, 0.001)
	for i: int in 10:
		_stats.apply(quill)
	assert_eq(_stats.value(&"attack_interval"), 0.40, "piso de 0,40 s")


func test_add_with_integer_cap() -> void:
	var shelf := _item(&"atril_capacity", &"add", 1.0, 8.0)
	for i: int in 3:
		assert_true(_stats.can_offer(shelf))
		_stats.apply(shelf)
	assert_eq(_stats.int_value(&"atril_capacity"), 8)
	assert_false(_stats.can_offer(shelf), "Estante no 8 sai do baralho (SC-302)")


func test_max_buys_limits_single_purchase_items() -> void:
	var rosary := _item(&"heresy_stun_mul", &"mul", 0.5, 0.0, 1)
	assert_true(_stats.can_offer(rosary))
	_stats.apply(rosary)
	assert_eq(_stats.value(&"heresy_stun_mul"), 0.5)
	assert_false(_stats.can_offer(rosary), "compra única")
	assert_eq(_stats.buys_of(rosary.id), 1)


func test_candle_item_at_cap_stays_offered_to_heal() -> void:
	var candle := _item(&"max_candles", &"add", 1.0, 8.0)
	candle.after_cap = &"heal_only"
	for i: int in 5:
		_stats.apply(candle)
	assert_eq(_stats.int_value(&"max_candles"), 8)
	assert_true(_stats.can_offer(candle), "no teto ainda acende 1 vela")
	assert_true(_stats.is_capped(candle))


func test_of_falls_back_to_a_neutral_stats_for_other_data() -> void:
	var other := PlayerData.new()
	other.move_speed = 70.0
	assert_eq(RunStats.of(other).value(&"move_speed"), 70.0)


func test_word_damage_starts_at_one_and_respects_its_cap() -> void:
	# 016: Tinta Consagrada (+0,15 até 1,6).
	assert_true(_stats.has_stat(&"word_damage_mul"))
	assert_eq(_stats.value(&"word_damage_mul"), 1.0)
	var ink: BlessingData = load("res://data/blessings/consecrated_ink.tres")
	for i: int in 6:
		_stats.apply(ink)
	assert_almost_eq(_stats.value(&"word_damage_mul"), 1.6, 0.001, "teto de 4 escolhas")


func test_upgrade_without_stat_only_counts() -> void:
	var full: BlessingData = load("res://data/blessings/grace_full.tres")
	assert_false(_stats.apply(full))
	assert_false(_stats.has_stat(&""), "não grava na chave vazia")
	assert_eq(_stats.buys_of(&"grace_full"), 1)
