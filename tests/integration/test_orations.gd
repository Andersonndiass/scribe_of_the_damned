extends GutTest
## T232 As 6 Grandes Orações na cena real, com o atril em 7–8 (002 FR-212, SC-206; D-056).

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
	_field.atril.set_capacity(8)
	_caster = _main.get_node("Caster")
	_manager = _main.get_node("World/EnemyManager")
	_manager.dissolve_all()
	_imp = load("res://data/enemies/imp.tres")
	EventBus.heresy_committed.connect(_on_heresy)
	EventBus.heresy_forgiven.connect(_on_forgiven)


func after_each() -> void:
	EventBus.heresy_committed.disconnect(_on_heresy)
	EventBus.heresy_forgiven.disconnect(_on_forgiven)
	Engine.time_scale = 1.0


func _on_heresy(_p: Vector2) -> void:
	_events.append(&"heresy")


func _on_forgiven(_p: Vector2) -> void:
	_events.append(&"forgiven")


func _cast(word: String) -> bool:
	for ch: String in word:
		assert_true(_field.collect(ch, false), "coletou %s" % ch)
	return _caster.cast()


func _word(id: StringName) -> WordData:
	for w: WordData in _field.lexicon_data.words:
		if w.id == id:
			return w
	return null


func _tough(pos: Vector2) -> int:
	var i: int = _manager.spawn(_imp, pos)
	_manager.hp[i] = 10_000
	return i


func test_orations_only_fit_a_big_atril() -> void:
	_field.atril.set_capacity(6)
	for ch: String in "SANCTUS":
		_field.collect(ch, false)
	assert_ne(_field.atril.state(_field.lexicon), Atril.Status.VALID, "7 letras não cabem no atril de 6")


func test_sanctus_damages_and_slows_inside() -> void:
	# D-084: comum dentro do solo morre (zona letal); o campeão é ferido e fica lento.
	var center: Vector2 = _player.global_position + Caster.PEN_OFFSET
	_tough(center + Vector2(40, 0))
	_tough(Vector2(600, 40))
	var champ: int = _manager.spawn(_imp, center + Vector2(-40, 0), true)
	_manager.hp[champ] = 10_000
	_manager.max_hp_of[champ] = 100
	assert_true(_cast("SANCTUS"))
	await wait_physics_frames(20)
	assert_eq(_manager.count, 2, "o comum dentro morreu; o de fora e o campeão ficam")
	var c: int = -1
	var o: int = -1
	for i: int in _manager.count:
		if _manager.champion[i] == 1:
			c = i
		else:
			o = i
	assert_lt(_manager.hp[c], 10_000, "campeão ferido dentro do solo")
	assert_lt(_manager.slow_factor[c], 1.0, "lento dentro do solo")
	assert_eq(_manager.hp[o], 10_000, "fora do raio, intacto")


func test_dominus_stuns_and_damages_the_whole_screen() -> void:
	var a: int = _tough(Vector2(40, 40))
	var b: int = _tough(Vector2(600, 320))
	assert_true(_cast("DOMINUS"))
	await wait_physics_frames(3)
	var w: WordData = _word(&"dominus")
	for i: int in [a, b]:
		assert_eq(_manager.hp[i], 10_000 - roundi(w.damage * w.power_budget), "power só no dano")
		assert_gt(_manager.stun_left[i], 0.0, "atordoado")


func test_angelus_feathers_orbit_and_hit() -> void:
	assert_true(_cast("ANGELUS"))
	await wait_physics_frames(2)
	var angelus: Node2D = null
	for n: Node in _main.get_node("FxLayer").get_children():
		if n.visible and n.has_method(&"feather_position"):
			angelus = n
	assert_not_null(angelus, "ANGELUS ativo abaixo das letras (FxLayer)")
	var target: int = _tough(angelus.call(&"feather_position", 0))
	await wait_physics_frames(20)
	assert_lt(_manager.hp[target], 10_000, "a pena feriu")


func test_spiritus_ignores_bodies_but_not_projectiles() -> void:
	var candles: int = _player.vitals.candles
	assert_true(_cast("SPIRITUS"))
	assert_true(_player.buffs.is_intangible())
	_player.take_hit(2, &"contact")
	assert_eq(_player.vitals.candles, candles, "atravessa corpos")
	_player.take_hit(1, &"projectile")
	assert_eq(_player.vitals.candles, candles - 1, "projétil ainda dói (D-046)")


func test_spiritus_hurts_what_it_touches() -> void:
	var i: int = _tough(_manager.player_body())
	assert_true(_cast("SPIRITUS"))
	await wait_physics_frames(3)
	assert_lt(_manager.hp[i], 10_000)


func test_salvator_heals_and_clears_projectiles_without_invulnerability() -> void:
	_player.vitals.candles = 1
	var shots: EnemyProjectileManager = _manager.get_projectiles()
	var shot: EnemyProjectileData = load("res://data/projectiles/prj_page.tres")
	for k: int in 5:
		shots.fire(shot, Vector2(100 + k * 20, 100), Vector2.RIGHT)
	assert_true(_cast("SALVATOR"))
	assert_eq(_player.vitals.candles, mini(4, _player.vitals.max_candles), "3 velas")
	assert_eq(shots.count, 0, "projéteis apagados")
	assert_false(_player.vitals.is_invulnerable(), "sem invulnerabilidade (SC-206)")


func test_miserere_damages_absolves_and_forgives_once() -> void:
	# Uma heresia antes: poça ativa.
	_field.collect("X", false)
	_caster.cast()
	assert_true(_caster.heresy_pool.is_active())
	_player.stun(0.0)
	_tough(Vector2(600, 320))
	assert_true(_cast("MISERERE"))
	await wait_seconds(0.5)  # varredura + dissolução da poça (0.2 s) + hit-stop
	assert_eq(_manager.count, 0, "a varredura matou o comum resistente (D-084: MISERERE é ataque)")
	assert_false(_caster.heresy_pool.is_active(), "poça de heresia apagada")
	assert_false(_manager.is_aggro_active(), "e o aggro dela")
	# A próxima heresia é perdoada: sem stun e as letras ficam.
	_events.clear()
	_field.collect("Q", false)
	_field.collect("Q", false)
	assert_false(_caster.cast())
	assert_has(_events, &"forgiven")
	assert_does_not_have(_events, &"heresy")
	assert_eq(_field.atril.size(), 2, "as letras ficam")
	# A seguinte já não é.
	_events.clear()
	_caster.cast()
	assert_has(_events, &"heresy")


func test_orations_do_not_instantiate() -> void:
	var before: int = PoolManager.instantiate_count
	for word: String in ["SANCTUS", "DOMINUS", "ANGELUS", "SPIRITUS", "SALVATOR", "MISERERE"]:
		assert_true(_cast(word), word)
		await wait_physics_frames(2)
	assert_eq(PoolManager.instantiate_count, before, "zero instantiate (FR-214)")
