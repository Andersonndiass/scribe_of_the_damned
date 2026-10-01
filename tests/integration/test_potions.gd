extends GutTest
## 018 Fase 2 (T1805–T1810): dados das 4 poções; o cinto (começa com 1 Óleo, teto de cargas, nível
## só das compradas); beber com as guardas (fora da onda, velas cheias, sem carga, intervalo,
## atordoado, menu da letra) sem gastar; o Óleo acende vela; o Vinho prende o espaço; o fim da
## onda encerra os efeitos; a lista de teclas das Opções em 2 colunas.

const MAIN_SCENE := preload("res://src/main/main.tscn")
const OPTIONS := preload("res://src/ui/screens/options_screen.tscn")

var _main: Node2D
var _player: Player
var _user: PotionUser
var _refused: Array[StringName] = []


func before_each() -> void:
	_refused.clear()
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_player = _main.get_node("World/Player")
	_player.arsenal.enabled = false
	_user = _player.potion_user
	_user.set_physics_process(false)
	EventBus.potion_refused.connect(_on_refused)


func after_each() -> void:
	EventBus.potion_refused.disconnect(_on_refused)
	RefugeZones.clear()
	GameState.letter_menu_open = false
	TimeScale.reset()


func _on_refused(_id: StringName, reason: StringName) -> void:
	_refused.append(reason)


func _start_wave() -> void:
	EventBus.wave_started.emit(1, 60.0)


func test_data_is_valid() -> void:
	assert_eq(GameState.potion_tuning.validate(), "")
	assert_eq(GameState.potion_tuning.order.map(func(p: PotionData) -> StringName: return p.id),
		[&"oil", &"holy_water", &"wine", &"illumination"], "teclas 3, 4, 5, 6")


func test_belt_starts_with_one_oil_and_respects_caps() -> void:
	var b: PotionBelt = GameState.potions
	assert_eq(b.charges(&"oil"), 1)
	assert_eq(b.level(&"oil"), 1)
	assert_false(b.owned(&"wine"))
	assert_false(b.can_level(&"wine"), "selo só de poção comprada")
	assert_true(b.add_charge(&"wine"))
	assert_true(b.add_charge(&"wine"))
	assert_false(b.add_charge(&"wine"), "teto 2")
	assert_eq(b.level(&"wine"), 1, "a 1ª compra põe no nível 1")
	assert_true(b.level_up(&"wine"))
	assert_true(b.level_up(&"wine"))
	assert_false(b.level_up(&"wine"), "nível 3 é o máximo")


func test_outside_a_wave_nothing_is_drunk() -> void:
	EventBus.wave_ended.emit(1)  # entre ondas (a cena começa a onda 1 ao carregar)
	_player.vitals.candles = 1
	assert_false(_user.drink(0))
	assert_eq(_refused, [&"blocked"] as Array[StringName])
	assert_eq(GameState.potions.charges(&"oil"), 1, "não gastou")


func test_oil_lights_a_candle_but_not_when_full() -> void:
	_start_wave()
	_player.vitals.candles = _player.vitals.max_candles
	assert_false(_user.drink(0), "velas cheias")
	assert_eq(_refused[-1], &"full")
	assert_eq(GameState.potions.charges(&"oil"), 1)
	_player.vitals.candles = 1
	assert_true(_user.drink(0))
	assert_eq(_player.vitals.candles, 2, "acendeu 1")
	assert_eq(GameState.potions.charges(&"oil"), 0)


func test_gap_empty_stunned_and_letter_menu_refuse_without_spending() -> void:
	_start_wave()
	GameState.potions.add_charge(&"wine")
	GameState.potions.add_charge(&"wine")
	assert_true(_user.drink(2))
	assert_false(_user.drink(2), "intervalo de 1,5 s")
	assert_eq(_refused[-1], &"gap")
	_user._physics_process(1.6)
	GameState.letter_menu_open = true
	assert_false(_user.drink(2))
	assert_eq(_refused[-1], &"blocked")
	GameState.letter_menu_open = false
	assert_false(_user.drink(1), "Água Benta sem carga")
	assert_eq(_refused[-1], &"empty")
	_player.stun(1.0)
	assert_false(_user.drink(2))
	assert_eq(_refused[-1], &"stunned")
	assert_eq(GameState.potions.charges(&"wine"), 1, "nenhuma recusa gastou")


func test_wine_binds_to_the_active_slot_and_ends() -> void:
	_start_wave()
	GameState.potions.add_charge(&"wine")
	assert_true(_user.drink(2))
	var b: PotionBelt = GameState.potions
	assert_eq(b.fervor_slot, GameState.loadout.active)
	assert_almost_eq(b.cadence_mul(GameState.loadout.active), 0.8, 0.001, "nível 1: ×0,80")
	assert_eq(b.cadence_mul(1 - GameState.loadout.active), 1.0, "a outra arma não ganha")
	var ended: Array[StringName] = []
	var on_end := func(_id: StringName, reason: StringName) -> void: ended.append(reason)
	EventBus.potion_effect_ended.connect(on_end)
	_user._physics_process(8.1)
	EventBus.potion_effect_ended.disconnect(on_end)
	assert_eq(ended, [&"timeout"] as Array[StringName])
	assert_eq(b.cadence_mul(b.fervor_slot), 1.0)


func test_wave_end_closes_effects() -> void:
	_start_wave()
	GameState.potions.add_charge(&"wine")
	_user.drink(2)
	EventBus.wave_ended.emit(1)
	assert_false(GameState.potions.active(&"wine"))
	assert_eq(_user.phase, PotionUser.Phase.OFF)


func test_options_key_list_fits_in_two_columns() -> void:
	var screen: Node = OPTIONS.instantiate()
	screen.embedded = true
	add_child_autofree(screen)
	var rects: Array[Rect2] = []
	for i: int in Settings.REBINDABLE.size():
		var r: Rect2 = screen.key_rect(i)
		assert_true(Rect2(0, 40, 640, 230).encloses(r), "linha %d dentro da tela" % i)
		for o: Rect2 in rects:
			assert_false(o.intersects(r), "linhas não se cobrem")
		rects.append(r)
	assert_has(Settings.REBINDABLE, &"potion_4")


# --- Fase 3 (T1811–T1812) -------------------------------------------------------------------

func test_wine_speeds_only_the_slot_it_was_drunk_on_with_a_floor() -> void:
	_start_wave()
	GameState.loadout.equip(load("res://data/weapons/crucifix.tres"))
	var pen_slot: WeaponSlot = GameState.loadout.slots[0]
	var base: float = _player.arsenal.interval_of(pen_slot)
	GameState.potions.add_charge(&"wine")
	assert_true(_user.drink(2))
	assert_almost_eq(_player.arsenal.interval_of(pen_slot), base * 0.8, 0.0001, "×0,80 na arma do momento")
	var other: WeaponSlot = GameState.loadout.slots[1]
	assert_almost_eq(_player.arsenal.interval_of(other), other.stats().interval, 0.0001, "a outra não")
	for k: int in 3:
		GameState.run_stats.apply(load("res://data/blessings/fine_quill.tres"))
	GameState.potions.level_up(&"wine")
	GameState.potions.level_up(&"wine")
	GameState.potions.fervor_mul = GameState.potions.stats(&"wine").interval_mul
	assert_almost_eq(_player.arsenal.interval_of(pen_slot), pen_slot.stats().interval * 0.55, 0.0001,
		"Pena de Ganso 0,70 × Vinho 0,70 = 0,49 → piso 0,55")


func test_illumination_opens_a_menu_now_with_useful_letters_by_level() -> void:
	_start_wave()
	var menu: LetterMenu = (_main.get_node("World/LetterField") as LetterField).menu
	menu.set_process(false)
	GameState.potions.add_charge(&"illumination")
	GameState.potions.level_up(&"illumination")
	GameState.potions.level_up(&"illumination")
	assert_true(_user.drink(3))
	assert_true(menu.is_open(), "abriu na hora")
	assert_true(menu.illuminated)
	var useful: int = menu.options.filter(func(o: Dictionary) -> bool: return o["useful"]).size()
	assert_eq(useful, 3, "nível 3: as 3 continuam a palavra")
	menu.cancel()


func test_illumination_waits_if_a_menu_is_busy() -> void:
	_start_wave()
	var menu: LetterMenu = (_main.get_node("World/LetterField") as LetterField).menu
	menu.set_process(false)
	GameState.potions.add_charge(&"illumination")
	assert_true(menu.offer())
	assert_false(_user.drink(3), "há pedido na fila")
	assert_eq(_refused[-1], &"menu_busy")
	assert_eq(GameState.potions.charges(&"illumination"), 1, "não gastou")
	menu.cancel()


# --- Fase 4 (T1813–T1815): Água Benta ---------------------------------------------------------

func _holy_water() -> EnemyManager:
	_start_wave()
	var em: EnemyManager = _main.get_node("World/EnemyManager")
	em.dissolve_all()
	GameState.potions.add_charge(&"holy_water")
	return em


func test_holy_water_expels_and_keeps_enemies_out() -> void:
	var em: EnemyManager = _holy_water()
	var imp: EnemyData = load("res://data/enemies/imp.tres").duplicate()
	imp.max_hp = 999
	var inside: int = em.spawn(imp, _player.global_position + Vector2(10, 0))
	em.spawn(imp, _player.global_position + Vector2(90, 0))
	assert_true(_user.drink(1))
	var r: float = RefugeZones.radius
	assert_eq(r, 32.0, "nível 1: raio 32")
	assert_gte(em.positions[inside].distance_to(RefugeZones.center), r, "quem estava dentro foi para a borda")
	await wait_physics_frames(90)  # 1,5 s andando na direção do escriba
	for i: int in em.count:
		assert_gte(em.positions[i].distance_to(RefugeZones.center), r - 0.5, "ninguém entra")


func test_heresy_inside_puts_out_the_circle_but_not_a_forgiven_one() -> void:
	_holy_water()
	assert_true(_user.drink(1))
	var center: Vector2 = RefugeZones.center
	EventBus.heresy_forgiven.emit(center)
	assert_true(RefugeZones.active, "a perdoada (MISERERE) não apaga")
	EventBus.heresy_committed.emit(center + Vector2(200, 0))
	assert_true(RefugeZones.active, "heresia fora do círculo não apaga")
	EventBus.heresy_committed.emit(center)
	assert_false(RefugeZones.active, "heresia dentro apaga")
	assert_false(GameState.potions.active(&"holy_water"))


func test_standing_in_the_circle_does_not_recover_a_candle() -> void:
	_holy_water()
	_player.vitals.candles = 1
	assert_true(_user.drink(1))
	RefugeZones.open(_player.global_position, 48.0)
	var before: int = _player.vitals.candles
	for k: int in 60 * 9:
		_player.vitals.tick(1.0 / 60.0, false)  # o Player passa idle = falso dentro do círculo
	assert_eq(_player.vitals.candles, before, "parado no círculo não recupera")
	assert_true(RefugeZones.contains(_player.global_position))



# --- Fase 5 (T1816–T1818): loja, selo de poção, VITA ------------------------------------------

func test_shelf_sells_charges_up_to_the_cap_with_wave_price() -> void:
	var shop: Shop = _main.get_node("Shop")
	shop.open(3)
	GameState.gold_ink = 50
	var wine: int = 2
	assert_eq(shop.potion_price(wine), roundi(4 * 1.2), "preço base 4 cresce por onda")
	assert_true(shop.buy_potion(wine))
	assert_true(shop.buy_potion(wine), "pode comprar de novo na mesma visita")
	assert_false(shop.buy_potion(wine), "teto de 2 cargas")
	assert_eq(GameState.potions.charges(&"wine"), 2)
	assert_eq(GameState.gold_ink, 50 - 2 * shop.potion_price(wine))
	GameState.gold_ink = 0
	assert_false(shop.buy_potion(1), "sem tinta")


func test_potion_seal_only_for_bought_potions_and_raises_the_level() -> void:
	var rng := RandomNumberGenerator.new()
	var seen := {}
	for k: int in 120:
		rng.seed = k
		for b: BlessingData in SealPool.draw(GameState.grace_tuning, GameState.run_stats, GameState.loadout, 0, 5, rng):
			if b.kind == &"potion_level":
				seen[b.target] = true
	assert_eq(seen.keys(), [&"oil"], "só o Óleo (a única comprada)")
	RunUpgrade.apply(SealPool.potion_seal(&"oil"), _player, null)
	assert_eq(GameState.potions.level(&"oil"), 2)


func test_vita_lights_two_candles() -> void:
	var vita: WordData = load("res://data/words/vita.tres")
	assert_eq(vita.heal_candles, 2, "VITA 2 > Óleo 1 (D-095)")
