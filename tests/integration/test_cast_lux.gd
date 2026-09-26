extends GutTest
## T051 M2: coletar L, U, X e conjurar LUX (FR-012, FR-015, FR-017, FR-021).

const MAIN_SCENE := preload("res://src/main/main.tscn")

var _main: Node2D
var _player: Player
var _field: LetterField
var _caster: Caster
var _manager: EnemyManager
var _imp: EnemyData
var _casts: Array[WordData] = []


func before_each() -> void:
	_casts.clear()
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_field = _main.get_node("World/LetterField")
	_caster = _main.get_node("Caster")
	_manager = _main.get_node("World/EnemyManager")
	_manager.dissolve_all()
	_imp = load("res://data/enemies/imp.tres")
	EventBus.word_cast.connect(_on_cast)


func after_each() -> void:
	EventBus.word_cast.disconnect(_on_cast)
	Engine.time_scale = 1.0


func _on_cast(word: WordData, _power: float, _origin: Vector2, _dir: Vector2) -> void:
	_casts.append(word)


func test_letters_on_the_ground_are_collected_in_order() -> void:
	var p: Vector2 = _player.global_position
	_field.spawn_letter("L", false, true, p + Vector2(10, -6))
	await wait_physics_frames(20)
	_field.spawn_letter("U", false, true, p + Vector2(-10, -6))
	await wait_physics_frames(20)
	_field.spawn_letter("X", false, true, p + Vector2(0, 10))
	await wait_physics_frames(20)
	assert_eq(_field.atril.text(), "LUX")
	assert_eq(_field.atril.state(_field.lexicon), Atril.Status.VALID)
	assert_eq(_field.active_count(), 0, "letras coletadas voltaram ao pool")


func test_far_letter_is_not_collected_and_expires() -> void:
	_field.spawn_letter("P", false, false, _player.global_position + Vector2(200, 0))
	await wait_physics_frames(10)
	assert_eq(_field.atril.size(), 0, "fora do ímã não é puxada")
	assert_eq(_field.active_count(), 1)


func test_full_atril_rejects_letter_and_it_stays_on_ground() -> void:
	for ch: String in "QQQQQ":
		_field.collect(ch, false)
	_field.spawn_letter("A", false, false, _player.global_position + Vector2(0, -6))
	await wait_physics_frames(5)
	assert_eq(_field.atril.size(), 5)
	assert_eq(_field.active_count(), 1, "a letra recusada continua no chão (D-008)")


func test_casting_lux_kills_enemies_in_line_only() -> void:
	_player.facing = Vector2.RIGHT
	var p: Vector2 = _player.global_position + Caster.PEN_OFFSET
	_manager.spawn(_imp, p + Vector2(60, 0))
	_manager.spawn(_imp, p + Vector2(120, 2))
	_manager.spawn(_imp, p + Vector2(60, 80))
	for ch: String in "LUX":
		_field.collect(ch, false)
	assert_true(_caster.cast())
	assert_eq(_casts.size(), 1)
	assert_eq(_casts[0].latin, "LUX")
	assert_eq(_manager.count, 1, "os dois na linha morreram; o de fora sobreviveu")
	assert_eq(_field.atril.size(), 0, "a conjuração consumiu as letras")


func test_cast_with_empty_atril_does_nothing() -> void:
	assert_false(_caster.cast())
	assert_eq(_casts.size(), 0)
	assert_eq(_player.machine.current.name, &"Idle", "atril vazio não é heresia (D-030)")


func test_casting_while_idle_keeps_regen_counting() -> void:
	_player.vitals.idle_time = 6.0
	for ch: String in "LUX":
		_field.collect(ch, false)
	assert_true(_caster.cast())
	assert_almost_eq(_player.vitals.idle_time, 6.0, 0.001, "conjurar parado não zera a recuperação (D-011, 1c)")


func test_rare_vowel_boosts_power() -> void:
	var powers: Array[float] = []
	var cb := func(_w: WordData, pw: float, _o: Vector2, _d: Vector2) -> void: powers.append(pw)
	EventBus.word_cast.connect(cb)
	_field.collect("L", false)
	_field.collect("U", true)
	_field.collect("X", false)
	_caster.cast()
	EventBus.word_cast.disconnect(cb)
	assert_almost_eq(powers[0], 1.5, 0.001, "1 vogal rara = ×1.5")
