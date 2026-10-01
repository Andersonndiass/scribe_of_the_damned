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
