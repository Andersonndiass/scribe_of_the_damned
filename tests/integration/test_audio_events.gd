extends GutTest
## T904 Áudio na cena real (009 SC-901, SC-902, SC-903): eventos passam pelo AudioManager,
## MORTIS em massa respeita max_voices, e nada é instanciado durante a onda.

const MAIN_SCENE := preload("res://src/main/main.tscn")

var _main: Node2D
var _field: LetterField
var _caster: Caster
var _manager: EnemyManager
var _player: Player
var _played: Array[StringName] = []


func before_each() -> void:
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
	await wait_seconds(0.3)  # vozes silenciosas do início liberadas
	_played.clear()
	AudioManager.sound_played.connect(_on_played)


func after_each() -> void:
	AudioManager.sound_played.disconnect(_on_played)
	Engine.time_scale = 1.0


func _on_played(id: StringName) -> void:
	_played.append(id)


func test_cast_plays_collect_valid_and_word_sounds() -> void:
	for ch: String in "LUX":
		_field.collect(ch, false)
	assert_has(_played, &"letter_collected")
	assert_has(_played, &"atril_valid", "o atril ficou VALID")
	_caster.cast()
	assert_has(_played, &"word_cast_lux", "LUX usa o próprio som, não o genérico")
	assert_does_not_have(_played, &"word_cast")


func test_sound_with_stream_plays_without_new_code() -> void:
	# SC-901: pôr um stream no .tres basta.
	var s: SoundData = AudioManager.event_map.resolve(&"letter_rejected")
	var original: AudioStream = s.stream
	var wav := AudioStreamWAV.new()
	wav.data = PackedByteArray([0, 0, 0, 0])
	s.stream = wav
	_field.atril.set_capacity(1)
	_field.collect("L", false)
	_field.collect("U", false)  # recusada: atril cheio
	s.stream = original  # o Resource é compartilhado: devolve o som provisório
	assert_has(_played, &"letter_rejected")


func test_mass_kill_respects_max_voices() -> void:
	var before: int = PoolManager.instantiate_count
	var imp: EnemyData = load("res://data/enemies/imp.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i: int in 300:
		_manager.spawn(imp, Vector2(rng.randf_range(30, 610), rng.randf_range(30, 330)))
	for ch: String in "MORTIS":
		_field.collect(ch, false)
	assert_true(_caster.cast())
	var cap: int = AudioManager.event_map.resolve(&"enemy_killed", &"imp").max_voices
	for f: int in 12:
		await wait_physics_frames(1)
		assert_true(AudioManager.sfx_active_count(&"enemy_killed_imp") <= cap, "no máximo %d vozes" % cap)
		assert_true(AudioManager.sfx_busy_count() <= AudioManager.VOICES_SFX)
	assert_eq(_manager.count, 0)
	assert_eq(PoolManager.instantiate_count, before, "zero instantiate com o áudio ligado (SC-903)")
