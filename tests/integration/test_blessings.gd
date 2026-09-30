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
