extends GutTest
## T1606/T1607 As bênçãos (016 FR-1611, FR-1612) aplicadas pelo RunUpgrade na cena real:
## os mesmos efeitos que tinham na loja, com os tetos novos (rules-agent D-083).

const MAIN_SCENE := preload("res://src/main/main.tscn")

var _main: Node2D
var _player: Player
var _field: LetterField


func before_each() -> void:
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_field = _main.get_node("World/LetterField")


func _bless(id: StringName) -> void:
	RunUpgrade.apply(load("res://data/blessings/%s.tres" % id), _player, _field)


func test_blessed_candle_raises_max_and_lights_one_up_to_8() -> void:
	var start_max: int = _player.vitals.max_candles
	_player.vitals.candles = 1
	_bless(&"blessed_candle")
	assert_eq(_player.vitals.max_candles, start_max + 1)
	assert_eq(_player.vitals.candles, 2, "acende 1")
	for i: int in 10:
		_bless(&"blessed_candle")
	assert_eq(_player.vitals.max_candles, 8, "teto 8")


func test_lodestone_sandals_lenses() -> void:
	_bless(&"lodestone")
	assert_almost_eq(GameState.run_stats.value(&"magnet_radius"), _player.data.magnet_radius * 1.3, 0.01)
	_bless(&"sandals")
	assert_almost_eq(GameState.run_stats.value(&"move_speed"), _player.data.move_speed * 1.1, 0.01)
	_bless(&"copyist_lenses")
	assert_eq(GameState.run_stats.value(&"target_bonus_add"), 6.0)


func test_rosary_halves_the_heresy_stun_once() -> void:
	_bless(&"rosary")
	_bless(&"rosary")
	assert_eq(GameState.run_stats.value(&"heresy_stun_mul"), 0.5)


func test_alms_purse_caps_at_40_percent() -> void:
	for i: int in 5:
		_bless(&"alms_purse")
	assert_almost_eq(GameState.run_stats.value(&"gold_mul"), 1.4, 0.001, "teto novo (D-083)")
	GameState.gold_ink = 0
	GameState.gold_fraction = 0.0
	for i: int in 5:
		GameState.add_gold(1)
	assert_eq(GameState.gold_ink, 7, "5 × 1,4 = 7")


func test_fine_quill_stops_at_056() -> void:
	for i: int in 6:
		_bless(&"fine_quill")
	assert_almost_eq(GameState.run_stats.value(&"attack_interval"), 0.56, 0.001, "a cadência não passa das palavras")


func test_grace_full_lights_a_candle() -> void:
	_player.vitals.candles = 1
	_bless(&"grace_full")
	assert_eq(_player.vitals.candles, 2)


func _active_miracle(word_id: StringName) -> Miracle:
	for layer: String in ["MiracleLayer", "FxLayer"]:
		for n: Node in _main.get_node(layer).get_children():
			var m := n as Miracle
			if m != null and m.word != null and m.word.id == word_id and m.is_processing():
				return m
	return null


func test_consecrated_ink_raises_word_damage_but_not_healing() -> void:
	# T1620 (016 FR-1611; rules-agent R1): a Tinta entra só no dano; a VITA cura igual.
	for i: int in 4:
		_bless(&"consecrated_ink")
	var caster: Caster = _main.get_node("Caster")
	caster._start_miracle(load("res://data/words/lux.tres"), 1.0, _player.global_position, Vector2.RIGHT)
	var lux: Miracle = _active_miracle(&"lux")
	assert_not_null(lux)
	assert_almost_eq(lux.damage_mul, 1.6, 0.001, "dano ×1,6")
	assert_almost_eq(lux.heal_mul, 1.0, 0.001)
	_player.vitals.candles = 1
	var vita: WordData = load("res://data/words/vita.tres")
	caster._start_miracle(vita, 1.0, _player.global_position, Vector2.RIGHT)
	assert_eq(_player.vitals.candles, 1 + vita.heal_candles, "a VITA cura o mesmo com a Tinta")
