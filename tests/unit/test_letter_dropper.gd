extends GutTest
## T044 [TEST-FIRST] Drop ponderado (FR-013, SC-005). Estatístico com seed fixa.

const ROLLS := 10000

var _lex: Lexicon
var _tuning: DropTuning
var _rng := RandomNumberGenerator.new()
var _dropper := LetterDropper.new()


func before_each() -> void:
	_rng.seed = 1348
	_lex = Lexicon.new()
	var d := LexiconData.new()
	d.alphabet = PackedStringArray("A C D E F G I L M N O P Q R S T U V X B".split(" "))
	d.gated_letters = {"B": &"verbum"}
	for latin: String in ["LUX", "PAX", "CRUX", "VITA", "AQUA", "IGNIS", "MORTIS", "VERBUM"]:
		var w := WordData.new()
		w.id = StringName(latin.to_lower())
		w.latin = latin
		d.words.append(w)
	_lex.load_data(d)
	_tuning = load("res://data/tuning/drop_tuning.tres")


func _atril(cap: int, letters: String) -> Atril:
	var a := Atril.new(cap)
	for ch: String in letters:
		a.push(ch, false)
	return a


func _roll_many(atril: Atril, unlocked: Array[StringName]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i: int in ROLLS:
		out.append(_dropper.roll(atril, _lex, _tuning, _rng, unlocked))
	return out


func test_targets_are_at_least_40_percent_with_partial_prefix() -> void:
	var rolls := _roll_many(_atril(5, "L"), [])
	var u: int = 0
	for r: Dictionary in rolls:
		if r["letter"] == "U":
			u += 1
			assert_true(r["target"], "U continua L→LUX: é letra-alvo")
	assert_gte(float(u) / ROLLS, 0.40, "SC-005")


func test_empty_atril_favors_first_letters_that_fit() -> void:
	var rolls := _roll_many(_atril(5, ""), [])
	var targets: int = 0
	for r: Dictionary in rolls:
		if r["target"]:
			targets += 1
		if r["letter"] == "M":
			assert_false(r["target"], "MORTIS não cabe em 5: M não é alvo")
	assert_gte(float(targets) / ROLLS, 0.40)


func test_dead_end_prefix_falls_back_to_first_letters() -> void:
	var rolls := _roll_many(_atril(5, "LQ"), [])
	var targets: int = 0
	for r: Dictionary in rolls:
		if r["target"]:
			targets += 1
	assert_gt(targets, 0, "sem continuação, mira o começo de uma nova palavra")


func test_gated_b_never_drops_without_verbum() -> void:
	for r: Dictionary in _roll_many(_atril(8, ""), []):
		assert_ne(r["letter"], "B")


func test_gated_b_drops_after_verbum_unlocked() -> void:
	var bs: int = 0
	for r: Dictionary in _roll_many(_atril(8, "VER"), [&"verbum"]):
		if r["letter"] == "B":
			bs += 1
	assert_gt(bs, 0)


func test_rare_only_on_vowels_and_near_rare_chance() -> void:
	var vowels: int = 0
	var rares: int = 0
	for r: Dictionary in _roll_many(_atril(5, ""), []):
		var is_vowel: bool = "AEIOU".contains(r["letter"])
		if r["rare"]:
			assert_true(is_vowel, "só vogais são raras")
			rares += 1
		if is_vowel:
			vowels += 1
	assert_almost_eq(float(rares) / vowels, _tuning.rare_chance, 0.02)


func test_deterministic_with_same_seed() -> void:
	_rng.seed = 42
	var a: Dictionary = _dropper.roll(_atril(5, "P"), _lex, _tuning, _rng, [])
	_rng.seed = 42
	var b: Dictionary = _dropper.roll(_atril(5, "P"), _lex, _tuning, _rng, [])
	assert_eq(a, b)
