extends GutTest
## T211 SC-201 (D-099): os 5 combos disparam com a palavra guardada + a parceira pronta no atril,
## em qualquer ordem, e o milagre da 2ª palavra não acontece. T213: efeito principal de cada combo
## na cena real. A guardada sozinha sai com Espaço; a janela de 2,5 s não existe mais.

const MAIN_SCENE := preload("res://src/main/main.tscn")
const PAIRS: Array = [
	[&"vapor", "AQUA", "IGNIS", &"ignis"],
	[&"flamma", "LUX", "IGNIS", &"ignis"],
	[&"caecitas", "LUX", "PAX", &"pax"],
	[&"martyrium", "CRUX", "LUX", &"lux"],
	[&"requiem", "MORTIS", "PAX", &"pax"],
]

var _main: Node2D
var _player: Player
var _field: LetterField
var _caster: Caster
var _manager: EnemyManager
var _imp: EnemyData
var _combos: Array[StringName] = []


func before_each() -> void:
	_combos.clear()
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_player.vitals.iframes_left = 1.0e6
	_field = _main.get_node("World/LetterField")
	_field.atril.set_capacity(6)
	_caster = _main.get_node("Caster")
	_manager = _main.get_node("World/EnemyManager")
	_manager.dissolve_all()
	_imp = load("res://data/enemies/imp.tres")
	EventBus.combo_cast.connect(_on_combo)


func after_each() -> void:
	EventBus.combo_cast.disconnect(_on_combo)
	TimeScale.reset()


func _on_combo(combo: ComboData, _power: float) -> void:
	_combos.append(combo.id)


func _write(word: String) -> void:
	for ch: String in word:
		assert_true(_field.collect(ch, false), "coletou %s" % ch)


func _cast(word: String) -> bool:
	_write(word)
	return _caster.cast()


## Escreve as duas (a 1ª vai para a guarda) e aperta Espaço uma vez.
func _combo(first: String, second: String) -> bool:
	_write(first)
	_write(second)
	return _caster.cast()


func _pen() -> Vector2:
	return _player.global_position + Caster.PEN_OFFSET


func test_all_pairs_in_both_orders_replace_the_second_word() -> void:
	for pair: Array in PAIRS:
		for order: int in 2:
			var first: String = pair[1] if order == 0 else pair[2]
			var second: String = pair[2] if order == 0 else pair[1]
			var second_id: StringName = StringName(second.to_lower())
			_field.guard.clear()
			_combos.clear()
			_write(first)
			assert_true(_field.guard.is_held(), "%s foi para a guarda" % first)
			_write(second)
			var free_before: int = PoolManager.free_count(second_id)
			assert_true(_caster.cast())
			assert_eq(_combos, [pair[0]] as Array[StringName], "%s + %s" % [first, second])
			assert_eq(PoolManager.free_count(second_id), free_before, "o milagre de %s não saiu" % second)
			assert_false(_field.guard.is_held(), "o combo gasta a guardada")
			await wait_physics_frames(2)
	await wait_seconds(5.0)  # deixa os milagres voltarem ao pool


## Resposta "1b": com guardada e o atril pela metade, Espaço solta a guardada e as letras ficam.
func test_space_with_half_atril_releases_the_stored_word() -> void:
	var heresies: Array[int] = [0]
	var on_heresy := func(_p: Vector2) -> void: heresies[0] += 1
	EventBus.heresy_committed.connect(on_heresy)
	_write("LUX")
	_write("PA")
	assert_true(_caster.cast(), "solta o LUX")
	EventBus.heresy_committed.disconnect(on_heresy)
	assert_eq(heresies[0], 0, "sem heresia")
	assert_eq(_field.atril.text(), "PA", "as letras do atril ficam")
	assert_false(_field.guard.is_held())


func test_heresy_and_moth_do_not_touch_the_stored_word() -> void:
	_write("LUX")
	_field.steal_last_letter()
	assert_true(_field.guard.is_held(), "a Traça só rouba do atril")
	_field.guard.clear()
	_write("PQ")
	assert_false(_caster.cast(), "sem guardada e atril inválido: heresia, como antes")


func test_pair_without_combo_casts_the_atril_and_keeps_the_stored() -> void:
	_write("CRUX")
	_write("PAX")
	assert_true(_caster.cast())
	assert_eq(_combos.size(), 0)
	assert_eq(_field.guard.word.id, &"crux", "a guardada fica")


func test_combo_does_not_chain() -> void:
	assert_true(_combo("LUX", "IGNIS"))
	assert_true(_cast("LUX"))
	assert_eq(_combos, [&"flamma"] as Array[StringName], "o combo não encadeia; o LUX seguinte sai sozinho")


func test_caecitas_blinds_and_damages() -> void:
	var near: int = _manager.spawn(_imp, _pen() + Vector2(60, 0))
	_manager.hp[near] = 100
	_combo("LUX", "PAX")
	assert_gt(_manager.blind_left[near], 0.0, "cego")
	assert_lt(_manager.hp[near], 100, "levou o clarão")


func test_requiem_kills_and_only_guaranteed_deaths_ask_for_a_menu() -> void:
	# 017: a letra garantida vira pedido de menu (fila de 1: o excedente é contado como perdido).
	# Sem chance normal de letra, só as `guaranteed_drop_cap` mortes do REQUIEM pedem.
	var saved_mul: float = GameState.letter_drop_mul
	GameState.letter_drop_mul = 0.0
	var asked: Array[int] = [0]
	var on_open := func(_o: Array) -> void: asked[0] += 1
	var on_lost := func() -> void: asked[0] += 1
	EventBus.letter_menu_opened.connect(on_open)
	EventBus.letter_offer_dropped.connect(on_lost)
	for i: int in 10:
		_manager.spawn(_imp, Vector2(200 + i * 20, 100))
	_combo("PAX", "MORTIS")
	await wait_physics_frames(10)
	EventBus.letter_menu_opened.disconnect(on_open)
	EventBus.letter_offer_dropped.disconnect(on_lost)
	GameState.letter_drop_mul = saved_mul
	var cap: int = (load("res://data/combos/requiem.tres") as WordData).guaranteed_drop_cap
	assert_eq(_combos, [&"requiem"] as Array[StringName])
	assert_eq(_manager.count, 0)
	assert_eq(asked[0] + _field.menu.queued(), cap, "no máximo 2 pedidos (abertos + perdidos + na fila)")


func test_vapor_hides_the_scribe_from_enemies_outside() -> void:
	_combo("IGNIS", "AQUA")
	await wait_physics_frames(3)
	assert_true(_manager.is_player_hidden(), "escriba dentro da nuvem")


func test_martyrium_follows_the_scribe() -> void:
	_combo("LUX", "CRUX")
	await wait_physics_frames(2)
	var target: Vector2 = _player.global_position + Vector2(40, 0)
	_player.global_position = target
	await wait_physics_frames(2)
	var em: EnemyManager = _manager
	var found: bool = false
	for n: Node in _main.get_node("MiracleLayer").get_children():
		if n.visible and n.get_script() != null and String(n.get_script().resource_path).contains("martyrium"):
			found = n.global_position.distance_to(em.player_body()) < 1.0
	assert_true(found, "a cruz acompanha o escriba")
