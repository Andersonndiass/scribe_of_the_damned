extends GutTest
## T060–T068 As 6 palavras restantes, heresia e purge, na cena principal (FR-019..FR-022).

const MAIN_SCENE := preload("res://src/main/main.tscn")

var _main: Node2D
var _player: Player
var _field: LetterField
var _caster: Caster
var _manager: EnemyManager
var _arena: Arena
var _imp: EnemyData
var _heresies: int = 0


func before_each() -> void:
	_heresies = 0
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_field = _main.get_node("World/LetterField")
	_caster = _main.get_node("Caster")
	_manager = _main.get_node("World/EnemyManager")
	_arena = _main.get_node("Arena")
	_manager.dissolve_all()
	_imp = load("res://data/enemies/imp.tres")
	EventBus.heresy_committed.connect(_on_heresy)


func after_each() -> void:
	EventBus.heresy_committed.disconnect(_on_heresy)
	TimeScale.reset()


func _on_heresy(_p: Vector2) -> void:
	_heresies += 1


func _write(word: String) -> void:
	for ch: String in word:
		_field.collect(ch, false)


func _pen() -> Vector2:
	return _player.global_position + Caster.PEN_OFFSET


# --- palavras ------------------------------------------------------------------------------

func test_pax_stuns_and_pushes_enemies_in_radius() -> void:
	var near: int = _manager.spawn(_imp, _pen() + Vector2(40, 0))
	_manager.spawn(_imp, _pen() + Vector2(200, 0))
	_write("PAX")
	assert_true(_caster.cast())
	assert_gt(_manager.stun_left[near], 0.0, "atordoado")
	assert_gt(_manager.positions[near].distance_to(_pen()), 40.0, "empurrado para longe")
	assert_eq(_manager.stun_left[1], 0.0, "fora do raio não é afetado")


func test_crux_damages_on_arms_and_blocks_projectiles() -> void:
	_manager.spawn(_imp, _pen() + Vector2(30, 0))
	_manager.spawn(_imp, _pen() + Vector2(30, 30))
	_write("CRUX")
	assert_true(_caster.cast())
	await wait_seconds(0.6)
	assert_eq(_manager.count, 1, "o do braço morreu; o da diagonal não")
	assert_true(ProjectileBlockers.blocks(_pen() + Vector2(0, -40)), "bloqueia no braço vertical")
	assert_false(ProjectileBlockers.blocks(_pen() + Vector2(30, 30)), "não bloqueia fora da cruz")


func test_crux_stops_blocking_after_duration() -> void:
	_write("CRUX")
	_caster.cast()
	await wait_seconds(4.3)
	assert_eq(ProjectileBlockers.count(), 0)


func test_vita_lights_a_candle() -> void:
	_player.take_hit(1)
	assert_eq(_player.vitals.candles, 2)
	_write("VITA")
	assert_true(_caster.cast())
	assert_eq(_player.vitals.candles, 3)


func test_aqua_slows_enemies_inside() -> void:
	var inside: int = _manager.spawn(_imp, _pen() + Vector2(30, 0))
	_manager.spawn(_imp, _pen() + Vector2(150, 0))
	_write("AQUA")
	assert_true(_caster.cast())
	await wait_physics_frames(3)
	assert_almost_eq(_manager.slow_factor[inside], 0.5, 0.001)
	assert_eq(_manager.slow_factor[1], 1.0)


func test_ignis_burns_enemies_and_the_page() -> void:
	var before: int = _arena.stamps_by_kind.get(&"burn", 0)
	_manager.spawn(_imp, _pen() + Vector2(20, 0))
	_manager.spawn(_imp, _pen() + Vector2(200, 0))
	_write("IGNIS")
	assert_true(_caster.cast())
	await wait_seconds(0.6)
	assert_eq(_manager.count, 1, "queimou o de perto")
	assert_eq(_arena.stamps_by_kind[&"burn"], before + 1, "deixou o queimado na página")


func test_mortis_needs_atril_6() -> void:
	for ch: String in "MORTIS":
		_field.collect(ch, false)
	assert_eq(_field.atril.size(), 5, "atril de 5: o S foi recusado")


func test_mortis_kills_the_whole_screen_in_batches() -> void:
	_field.atril.set_capacity(6)
	for i: int in 120:
		_manager.spawn(_imp, Vector2(40 + (i % 20) * 28, 40 + (i / 20) * 45))
	_write("MORTIS")
	assert_true(_caster.cast())
	await wait_physics_frames(1)
	assert_gt(_manager.count, 0, "não mata tudo num frame só (lotes de 50)")
	await wait_physics_frames(5)
	assert_eq(_manager.count, 0)


func test_every_base_word_has_a_miracle_scene() -> void:
	for w: WordData in _field.lexicon_data.words:
		if w.group != &"base":
			continue  # apócrifos e orações ganham cena nas Fases 3–4 da 002
		assert_not_null(w.miracle_scene, w.latin)
		assert_true(PoolManager.is_registered(w.id), w.latin)


# --- heresia e purge -------------------------------------------------------------------------

func test_heresy_stuns_clears_and_creates_aggro_pool() -> void:
	_write("LQ")
	assert_false(_caster.cast())
	assert_eq(_heresies, 1)
	assert_eq(_field.atril.size(), 0, "as letras se perdem")
	assert_eq(_player.machine.current.name, &"Stunned")
	assert_true(_manager.is_aggro_active())
	await wait_seconds(0.6)
	assert_ne(_player.machine.current.name, &"Stunned", "o stun dura 0.5s")


func test_heresy_on_incomplete_prefix() -> void:
	_write("LU")
	assert_false(_caster.cast())
	assert_eq(_heresies, 1, "prefixo incompleto também é heresia")


func test_purge_empties_the_atril_and_the_letters_are_lost() -> void:
	_write("LU")
	var purged: Array[int] = []
	var cb := func(letters: PackedStringArray, _p: Vector2) -> void: purged.append(letters.size())
	EventBus.atril_purged.connect(cb)
	assert_true(_caster.purge())
	EventBus.atril_purged.disconnect(cb)
	assert_eq(_field.atril.size(), 0)
	assert_eq(purged.size(), 1, "atril_purged emitido")
	assert_eq(_heresies, 0, "purge não é heresia")
	await wait_seconds(0.5)
	assert_eq(_field.atril.size(), 0, "as letras se perdem: nada volta ao chão nem ao atril")


func test_purge_with_empty_atril_does_nothing() -> void:
	assert_false(_caster.purge())
	assert_eq(_field.atril.size(), 0)
