extends GutTest
## 017 T1735: selos com nível de arma, status e ímã reverso (SealPool; rules-agent §5), loja de
## armas e do ímã (exclui o que já se tem; 1ª loja com armas; troca a ativa com confirmação) e o
## pulso do ímã reverso (empurra; fere do nível 3; o campeão leva meio empurrão).

const MAIN_SCENE := preload("res://src/main/main.tscn")
const PEN := preload("res://data/weapons/pen.tres")
const BIBLE := preload("res://data/weapons/bible.tres")
const CRUCIFIX := preload("res://data/weapons/crucifix.tres")
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
	_manager = _main.get_node("World/EnemyManager")
	_manager.dissolve_all()
	_tough = IMP.duplicate()
	_tough.max_hp = 100
	_tough.move_speed = 0.0


func after_each() -> void:
	get_tree().paused = false
	TimeScale.reset()
	GameState.repulse_level = 0


func _draw_many(n: int) -> Array[BlessingData]:
	var rng := RandomNumberGenerator.new()
	var all: Array[BlessingData] = []
	for k: int in n:
		rng.seed = k
		all.append_array(SealPool.draw(GameState.grace_tuning, GameState.run_stats, GameState.loadout,
			GameState.repulse_level, GameState.repulse.max_level(), rng))
	return all


func test_every_offer_has_a_weapon_seal_and_one_per_slot() -> void:
	GameState.loadout.equip(BIBLE)
	var rng := RandomNumberGenerator.new()
	for k: int in 80:
		rng.seed = k
		var o: Array[BlessingData] = SealPool.draw(GameState.grace_tuning, GameState.run_stats,
			GameState.loadout, 0, 5, rng)
		assert_eq(o.size(), 3)
		var slots: Array[int] = []
		var seen: Array[String] = []
		for b: BlessingData in o:
			if b.kind == &"weapon_level":
				var key: String = "%d:%s" % [b.slot, b.target]
				assert_does_not_have(seen, key, "D-098: nunca o mesmo atributo 2× na oferta")
				seen.append(key)
				slots.append(b.slot)
			assert_ne(b.kind, &"passive_level", "sem ímã comprado, sem selo de ímã")
		assert_gt(slots.size(), 0, "pelo menos 1 selo de arma")


func test_maxed_weapon_leaves_the_draw_and_magnet_joins_when_bought() -> void:
	GameState.loadout.slots[0].auto_rank_up_times(PEN.max_upgrades)
	GameState.repulse_level = 1
	var kinds := {}
	for b: BlessingData in _draw_many(60):
		kinds[b.kind] = true
		assert_ne(b.kind, &"weapon_level", "Pena no nível máximo e sem outra arma: nenhum selo de arma")
	assert_true(kinds.has(&"passive_level"), "com o ímã comprado, o selo do ímã aparece")


func test_weapon_seal_levels_the_slot_and_magnet_seal_the_magnet() -> void:
	var seal: BlessingData = SealPool.weapon_seal(GameState.loadout, 0, PEN.upgrade(&"rate"))
	assert_eq(seal.target, &"rate")
	RunUpgrade.apply(seal, _player, null)
	assert_eq(GameState.loadout.slots[0].level, 2)
	assert_eq(GameState.loadout.slots[0].rank(&"rate"), 1, "D-098: o selo sobe o atributo dele")
	assert_almost_eq(GameState.loadout.slots[0].stats().interval, 0.71, 0.0001)
	GameState.repulse_level = 1
	RunUpgrade.apply(SealPool.passive_seal(1), _player, null)
	assert_eq(GameState.repulse_level, 2)


func test_first_shop_offers_weapons_and_hides_owned_ones() -> void:
	_shop.open(1)
	for i: int in _shop.tuning.item_slots:
		var c: ShopItemData = _shop.offer.cards[i]
		assert_eq(c.kind, &"weapon", "1ª loja com o espaço 2 vazio: armas")
	GameState.loadout.equip(BIBLE)
	for k: int in 10:
		_shop.open(2)
		for c: ShopItemData in _shop.offer.cards:
			if c != null and c.kind == &"weapon":
				assert_ne(c.weapon.id, &"bible", "arma que já tem não aparece")
				assert_ne(c.weapon.id, &"pen")


func test_buying_a_weapon_fills_the_empty_slot() -> void:
	_shop.open(1)
	GameState.gold_ink = 99
	var c: ShopItemData = _shop.offer.cards[0]
	assert_true(_shop.buy(0))
	assert_eq(GameState.loadout.weapon(1), c.weapon, "foi para o espaço 2")


func test_full_slots_replace_the_active_weapon_after_confirmation() -> void:
	GameState.loadout.equip(BIBLE)
	GameState.loadout.set_active(1)
	_shop.open(2)
	_shop.offer.cards[0] = _card(&"weapon_crucifix")
	_shop.offer.prices[0] = 6
	GameState.gold_ink = 99
	assert_true(_shop.replaces_weapon(0))
	var screen: Node = _main.get_node("ShopScreen")
	screen._try_buy(0)
	assert_eq(screen.confirm_replace, 0, "1º Comprar só pergunta")
	assert_eq(GameState.loadout.weapon(1), BIBLE)
	screen._try_buy(0)
	assert_eq(GameState.loadout.weapon(1), CRUCIFIX, "2º Comprar troca a ativa")
	assert_eq(GameState.loadout.weapon(0), PEN, "a outra fica")


func test_magnet_is_sold_once() -> void:
	_shop.open(2)
	_shop.offer.cards[0] = _card(&"reverse_magnet")
	_shop.offer.prices[0] = 8
	GameState.gold_ink = 99
	assert_true(_shop.buy(0))
	assert_eq(GameState.repulse_level, 1)
	for k: int in 10:
		_shop.open(3)
		for c: ShopItemData in _shop.offer.cards:
			assert_true(c == null or c.id != &"reverse_magnet", "comprado não volta")


func test_magnet_pulse_pushes_hurts_from_level_3_and_halves_champions() -> void:
	var body: Vector2 = _player.global_position + RepulseAura.BODY
	var a: int = _manager.spawn(_tough, body + Vector2(20, 0))
	var c: int = _manager.spawn(_tough, body + Vector2(-20, 0), true)
	var uid_c: int = _manager.uid_of[c]
	GameState.repulse_level = 3
	var data: RepulseData = GameState.repulse
	var pushed: int = _manager.repulse(body, data.at(data.radii, 3), data.at(data.knockbacks, 3), data.champion_knockback_mul, data.at(data.damages, 3))
	assert_eq(pushed, 2)
	for i: int in _manager.count:
		var d: float = _manager.positions[i].distance_to(body)
		if _manager.uid_of[i] == uid_c:
			assert_almost_eq(d, 20.0 + 48.0 * 0.5, 0.5, "campeão: meio empurrão")
		else:
			assert_almost_eq(d, 20.0 + 48.0, 0.5)
			assert_eq(_manager.hp[i], 99, "nível 3 fere 1")


func test_aura_waits_until_someone_is_in_range() -> void:
	GameState.repulse_level = 1
	var aura: RepulseAura = _player.repulse_aura
	aura.set_physics_process(false)
	var pulses: Array[int] = [0]
	var on_pulse := func(_c: Vector2, _r: float, _l: int, _p: int) -> void: pulses[0] += 1
	EventBus.repulse_pulsed.connect(on_pulse)
	for k: int in 420:
		aura._physics_process(1.0 / 60.0)
	assert_eq(pulses[0], 0, "ninguém perto: segura o pulso")
	_manager.spawn(_tough, _player.global_position + Vector2(10, 0))
	aura._physics_process(1.0 / 60.0)
	assert_eq(pulses[0], 1, "pronto há tempo: solta assim que alguém entra")
	EventBus.repulse_pulsed.disconnect(on_pulse)


func _card(id: StringName) -> ShopItemData:
	for c: ShopItemData in _shop.tuning.deck:
		if c.id == id:
			return c
	return null
