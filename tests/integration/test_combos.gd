extends GutTest
## T211 SC-201: os 5 combos disparam só com o par certo, dentro da janela, em qualquer ordem, e o
## milagre da 2ª palavra não acontece. T213: efeito principal de cada combo na cena real.

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
	Engine.time_scale = 1.0


func _on_combo(combo: ComboData, _power: float) -> void:
	_combos.append(combo.id)


func _write(word: String) -> void:
	for ch: String in word:
		assert_true(_field.collect(ch, false), "coletou %s" % ch)


func _cast(word: String) -> bool:
	_write(word)
	return _caster.cast()


func _pen() -> Vector2:
	return _player.global_position + Caster.PEN_OFFSET


func test_all_pairs_in_both_orders_replace_the_second_word() -> void:
	for pair: Array in PAIRS:
		for order: int in 2:
			var first: String = pair[1] if order == 0 else pair[2]
			var second: String = pair[2] if order == 0 else pair[1]
			var second_id: StringName = StringName(second.to_lower())
			_caster.combo_book.close()
			_combos.clear()
			assert_true(_cast(first))
			var free_before: int = PoolManager.free_count(second_id)
			assert_true(_cast(second))
			assert_eq(_combos, [pair[0]] as Array[StringName], "%s + %s" % [first, second])
			assert_eq(PoolManager.free_count(second_id), free_before, "o milagre de %s não saiu" % second)
			await wait_physics_frames(2)
	await wait_seconds(5.0)  # deixa os milagres voltarem ao pool


func test_no_combo_outside_the_window() -> void:
	assert_true(_cast("LUX"))
	_field.collect("P", false)  # 1ª letra: os 2,5 s começam
	_caster.combo_book.tick(2.6)
	_field.collect("A", false)
	_field.collect("X", false)
	assert_true(_caster.cast())
	assert_eq(_combos.size(), 0, "janela vencida: sai PAX, não CAECITAS")


func test_pair_without_combo_casts_normally() -> void:
	assert_true(_cast("CRUX"))
	assert_true(_cast("PAX"))
	assert_eq(_combos.size(), 0)


func test_combo_does_not_chain() -> void:
	assert_true(_cast("LUX"))
	assert_true(_cast("IGNIS"))
	assert_true(_cast("LUX"))
	assert_eq(_combos, [&"flamma"] as Array[StringName], "o IGNIS do combo não abre outro")


func test_caecitas_blinds_and_damages() -> void:
	var near: int = _manager.spawn(_imp, _pen() + Vector2(60, 0))
	_manager.hp[near] = 100
	_cast("LUX")
	_cast("PAX")
	assert_gt(_manager.blind_left[near], 0.0, "cego")
	assert_lt(_manager.hp[near], 100, "levou o clarão")


func test_requiem_kills_and_every_death_drops_a_letter() -> void:
	var dropped: Array[int] = [0]
	var on_drop := func(_l: String, _r: bool, _t: bool, _p: Vector2) -> void: dropped[0] += 1
	EventBus.letter_dropped.connect(on_drop)
	for i: int in 10:
		_manager.spawn(_imp, Vector2(200 + i * 20, 100))
	_cast("PAX")
	_cast("MORTIS")
	await wait_physics_frames(10)
	EventBus.letter_dropped.disconnect(on_drop)
	assert_eq(_combos, [&"requiem"] as Array[StringName])
	assert_eq(_manager.count, 0)
	assert_eq(dropped[0], 10, "letra garantida em cada morte")


func test_vapor_hides_the_scribe_from_enemies_outside() -> void:
	_cast("IGNIS")
	_cast("AQUA")
	await wait_physics_frames(3)
	assert_true(_manager.is_player_hidden(), "escriba dentro da nuvem")


func test_martyrium_follows_the_scribe() -> void:
	_cast("LUX")
	_cast("CRUX")
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
