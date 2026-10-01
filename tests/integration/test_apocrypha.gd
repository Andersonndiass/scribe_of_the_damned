extends GutTest
## T221 Os 5 apócrifos na cena real (002 FR-206..FR-211, SC-202; D-055).

const MAIN_SCENE := preload("res://src/main/main.tscn")

var _main: Node2D
var _player: Player
var _field: LetterField
var _caster: Caster
var _manager: EnemyManager
var _imp: EnemyData
var _events: Array[StringName] = []


func before_each() -> void:
	_events.clear()
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_field = _main.get_node("World/LetterField")
	_field.atril.set_capacity(6)
	_caster = _main.get_node("Caster")
	_manager = _main.get_node("World/EnemyManager")
	_manager.dissolve_all()
	_imp = load("res://data/enemies/imp.tres")
	for word: WordData in _field.lexicon_data.words:
		if word.requires_unlock:
			GameState.unlock_word(word)
	EventBus.shield_broken.connect(_on_shield)
	EventBus.verbum_failed.connect(_on_fail)
	EventBus.heresy_committed.connect(_on_heresy)


func after_each() -> void:
	EventBus.shield_broken.disconnect(_on_shield)
	EventBus.verbum_failed.disconnect(_on_fail)
	EventBus.heresy_committed.disconnect(_on_heresy)
	GameState.unlocked_words.clear()
	TimeScale.reset()


func _on_shield(_p: Vector2) -> void:
	_events.append(&"shield")


func _on_fail() -> void:
	_events.append(&"verbum_failed")


func _on_heresy(_p: Vector2) -> void:
	_events.append(&"heresy")


func _cast(word: String) -> bool:
	for ch: String in word:
		assert_true(_field.collect(ch, false), "coletou %s" % ch)
	return _caster.cast()


func _pen() -> Vector2:
	return _player.global_position + Caster.PEN_OFFSET


func test_fides_absorbs_the_next_hit() -> void:
	var candles: int = _player.vitals.candles
	assert_true(_cast("FIDES"))
	assert_true(_player.buffs.has_shield())
	_player.take_hit(2, &"contact")
	assert_eq(_player.vitals.candles, candles, "o escudo absorveu o golpe forte")
	assert_has(_events, &"shield")
	assert_false(_player.buffs.has_shield())
	assert_true(_player.vitals.is_invulnerable(), "i-frames normais depois do escudo")


func test_fides_ends_with_the_wave() -> void:
	_cast("FIDES")
	EventBus.wave_ended.emit(1)
	assert_false(_player.buffs.has_shield())


func test_lumen_doubles_the_letter_chance() -> void:
	assert_eq(_player.buffs.letter_chance_mul(), 1.0)
	assert_true(_cast("LUMEN"))
	assert_eq(_player.buffs.letter_chance_mul(), 2.0)


func test_gloria_multiplies_damage_only() -> void:
	var i: int = _manager.spawn(_imp, _pen() + Vector2(60, 0))
	_manager.hp[i] = 100
	assert_true(_cast("GLORIA"))
	_player.facing = Vector2.RIGHT
	assert_true(_cast("LUX"))
	var lux: WordData = _field.lexicon.word_for("LUX")
	assert_eq(_manager.hp[i], 100 - roundi(lux.damage * lux.power_budget * 1.5), "LUX ×1.5")


func test_verbum_repeats_the_last_word_with_same_power() -> void:
	var i: int = _manager.spawn(_imp, _pen() + Vector2(60, 0))
	_manager.hp[i] = 100
	_player.facing = Vector2.RIGHT
	assert_true(_cast("LUX"))
	var after_one: int = _manager.hp[i]
	assert_true(_cast("VERBUM"))
	assert_eq(_manager.hp[i], after_one - (100 - after_one), "o eco fere igual")


func test_verbum_does_not_touch_the_combo_window() -> void:
	var combos: Array[StringName] = []
	var on_combo := func(c: ComboData, _p: float) -> void: combos.append(c.id)
	EventBus.combo_cast.connect(on_combo)
	_cast("LUX")
	_cast("VERBUM")
	assert_true(_caster.combo_book.is_open(), "a janela do LUX continua aberta")
	assert_eq(_caster.combo_book.last_word.id, &"lux")
	_cast("PAX")
	EventBus.combo_cast.disconnect(on_combo)
	assert_eq(combos, [&"caecitas"] as Array[StringName], "LUX + PAX fecha depois do eco")


func test_verbum_without_anything_to_repeat_fizzles() -> void:
	assert_false(_cast("VERBUM"))
	assert_has(_events, &"verbum_failed")
	assert_does_not_have(_events, &"heresy", "falha não é heresia")
	assert_eq(_field.atril.size(), 0, "as letras se perdem")


func test_purgo_kills_commons_and_only_scratches_champions() -> void:
	var before: int = PoolManager.instantiate_count
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i: int in 299:
		_manager.spawn(_imp, Vector2(rng.randf_range(30, 610), rng.randf_range(30, 330)))
	var champ: int = _manager.spawn(_imp, Vector2(320, 60), true)
	_manager.hp[champ] = 500
	_field.menu.enabled = false  # D-098: o menu da letra pausaria o jogo no meio da varredura
	assert_true(_cast("PURGO"))
	var purgo: WordData = _field.lexicon.word_for("PURGO")
	await wait_physics_frames(15)
	assert_eq(_manager.count, 1, "só o campeão sobrou")
	# 10 literais da varredura + o golpe da zona letal (D-084); segue só arranhado.
	assert_lt(_manager.hp[0], 500 - int(purgo.damage) + 1, "levou os 10 de dano")
	assert_gt(_manager.hp[0], 450, "e só arranhou")
	assert_eq(PoolManager.instantiate_count, before, "zero instantiate (SC-202)")


func test_b_only_drops_after_verbum_is_unlocked() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var dropper := LetterDropper.new()
	var none: Array[StringName] = []
	var with_verbum: Array[StringName] = [&"verbum"]
	var b_locked: int = 0
	var b_open: int = 0
	for i: int in 2000:
		if dropper.roll(_field.atril, _field.lexicon, _field.tuning, rng, none)["letter"] == "B":
			b_locked += 1
		if dropper.roll(_field.atril, _field.lexicon, _field.tuning, rng, with_verbum)["letter"] == "B":
			b_open += 1
	assert_eq(b_locked, 0)
	assert_gt(b_open, 0)
