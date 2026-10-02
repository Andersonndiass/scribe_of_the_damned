extends GutTest
## 019 (D-103; T1900): Sino atordoa sem empurrar e o chefe é imune; Sal deixa lento e metade no
## campeão; Relicário explode ao perder vela; Selo de Cera segura o golpe depois da FIDES; venda
## nunca dá lucro, vale mais com postos, não vende a última arma; trocar relíquia vende a que sai.

const MAIN_SCENE := preload("res://src/main/main.tscn")
const RELICS := preload("res://data/tuning/relics.tres")
const BIBLE := preload("res://data/weapons/bible.tres")
const IMP := preload("res://data/enemies/imp.tres")

var _main: Node2D
var _shop: Shop
var _player: Player
var _manager: EnemyManager
var _tough: EnemyData


func before_each() -> void:
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_shop = _main.get_node("Shop")
	_player = _main.get_node("World/Player")
	_player.arsenal.enabled = false
	_player.relics.set_physics_process(false)
	_manager = _main.get_node("World/EnemyManager")
	_manager.dissolve_all()
	_tough = IMP.duplicate()
	_tough.max_hp = 100
	_tough.move_speed = 0.0


func after_each() -> void:
	get_tree().paused = false


func _relic(id: StringName) -> RelicData:
	return RELICS.by_id(id)


func _tick(seconds: float) -> void:
	var steps: int = roundi(seconds * 60.0)
	for k: int in steps:
		_player.relics._physics_process(1.0 / 60.0)


func _near() -> Vector2:
	return _player.global_position + RelicRunner.BODY + Vector2(12, 0)


func test_bell_stuns_without_pushing_and_halves_champions() -> void:
	RunUpgrade.equip_relic(_relic(&"vespers_bell"))
	var a: int = _manager.spawn(_tough, _near())
	var before: Vector2 = _manager.positions[a]
	_manager.spawn(_tough, _player.global_position + RelicRunner.BODY + Vector2(-12, 0), true)
	_tick(8.05)
	assert_almost_eq(_manager.positions[0].distance_to(before), 0.0, 0.5, "sem empurrão")
	var stuns: Array[float] = [_manager.stun_left[0], _manager.stun_left[1]]
	stuns.sort()
	assert_almost_eq(stuns[1], 0.5, 0.05, "comum: 0,5 s")
	assert_almost_eq(stuns[0], 0.25, 0.05, "campeão: metade")
	assert_eq(_manager.stun_by_relic[0], 1, "coroa da relíquia, não GOLD (R2)")


func test_salt_slows_inside_the_aura() -> void:
	RunUpgrade.equip_relic(_relic(&"blessed_salt"))
	var i: int = _manager.spawn(_tough, _near())
	_tick(0.2)
	assert_almost_eq(_manager.slow_factor[i], 0.9, 0.001)


func test_reliquary_bursts_when_a_candle_is_lost() -> void:
	RunUpgrade.equip_relic(_relic(&"saint_reliquary"))
	_tick(1.1)
	var i: int = _manager.spawn(_tough, _near())
	_player.take_hit(1)
	assert_eq(_manager.hp[i], 98, "explosão de 2 de dano")


func test_wax_seal_absorbs_after_fides_and_recharges() -> void:
	RunUpgrade.equip_relic(_relic(&"wax_seal"))
	var candles: int = _player.vitals.candles
	_player.take_hit(1)
	assert_eq(_player.vitals.candles, candles, "a cera segurou o golpe")
	assert_eq(GameState.loadout.relic(0).charges, 0)
	_player.vitals.iframes_left = 0.0
	_player.take_hit(1)
	assert_eq(_player.vitals.candles, candles - 1, "sem carga, o golpe passa")
	_tick(25.1)
	assert_eq(GameState.loadout.relic(0).charges, 1, "recarregou em 25 s")


func test_selling_never_profits_and_grows_with_ranks() -> void:
	for paid: int in range(2, 20):
		for ranks: int in 8:
			assert_lt(_shop.sell_value(paid, ranks), paid, "nunca dá lucro (S9)")
	assert_gt(_shop.sell_value(10, 3), _shop.sell_value(10, 0), "vale mais com postos")


func test_last_weapon_cannot_be_sold_and_active_moves() -> void:
	_shop.open(2)
	assert_false(_shop.can_sell_weapon(0), "a última arma não vende")
	RunUpgrade.equip_weapon(BIBLE, 6)
	GameState.loadout.set_active(1)
	var ink: int = GameState.gold_ink
	assert_true(_shop.sell_weapon(1))
	assert_eq(GameState.gold_ink, ink + _shop.sell_value(6, 0))
	assert_eq(GameState.loadout.active, 0, "a ativa vira a outra")
	assert_eq(GameState.loadout.weapon(1), null)


func test_buying_a_relic_with_full_slots_sells_the_one_that_leaves() -> void:
	RunUpgrade.equip_relic(_relic(&"reverse_magnet"), 8)
	RunUpgrade.equip_relic(_relic(&"blessed_salt"), 8)
	_shop.open(2)
	for c: ShopItemData in _shop.tuning.deck:
		if c.id == &"wax_seal":
			_shop.offer.cards[0] = c
	_shop.offer.prices[0] = 10
	GameState.gold_ink = 10
	assert_true(_shop.replaces_relic(0))
	assert_true(_shop.buy(0, 1))
	assert_eq(GameState.loadout.relic(1).relic.id, &"wax_seal")
	assert_eq(GameState.gold_ink, _shop.sell_value(8, 0), "a que saiu foi vendida (D-103 2a)")


func test_potion_sells_one_charge_and_keeps_level() -> void:
	_shop.open(2)
	var oil: int = 0
	var lv: int = GameState.potions.level(_shop.potion_at(oil).id)
	assert_true(_shop.sell_potion(oil))
	assert_eq(GameState.potions.charges(_shop.potion_at(oil).id), 0)
	assert_eq(GameState.potions.level(_shop.potion_at(oil).id), lv)
