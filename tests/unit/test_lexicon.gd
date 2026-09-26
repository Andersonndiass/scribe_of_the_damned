extends GutTest
## T040 [TEST-FIRST] Lexicon: validação no load (3 a 8 letras, alfabeto, duplicatas) e consultas (FR-014).

const ALPHABET := "A C D E F G I L M N O P Q R S T U V X B"


func _word(latin: String) -> WordData:
	var w := WordData.new()
	w.id = StringName(latin.to_lower())
	w.latin = latin
	return w


func _data(words: Array[String]) -> LexiconData:
	var d := LexiconData.new()
	d.alphabet = PackedStringArray(ALPHABET.split(" "))
	d.min_length = 3
	d.max_length = 8
	for latin: String in words:
		d.words.append(_word(latin))
	return d


func _base() -> Lexicon:
	var lex := Lexicon.new()
	assert_true(lex.load_data(_data(["LUX", "PAX", "CRUX", "VITA", "AQUA", "IGNIS", "MORTIS"])))
	return lex


# --- validação -------------------------------------------------------------------------------

func test_loads_valid_dictionary() -> void:
	var lex := Lexicon.new()
	assert_true(lex.load_data(_data(["LUX", "SPIRITUS"])))
	assert_eq(lex.error, "")


func test_rejects_word_shorter_than_3() -> void:
	var lex := Lexicon.new()
	assert_false(lex.load_data(_data(["LUX", "AB"])))
	assert_string_contains(lex.error, "AB")
	assert_push_error("'AB' tem 2 letras")


func test_rejects_word_longer_than_8() -> void:
	var lex := Lexicon.new()
	assert_false(lex.load_data(_data(["ABCDEFGIL"])))
	assert_push_error("9 letras")


func test_rejects_letter_outside_alphabet() -> void:
	var lex := Lexicon.new()
	assert_false(lex.load_data(_data(["HAX"])), "H não está no alfabeto")
	assert_push_error("fora do alfabeto")


func test_rejects_duplicate() -> void:
	var lex := Lexicon.new()
	assert_false(lex.load_data(_data(["LUX", "LUX"])))
	assert_push_error("duplicada")


func test_rejects_lowercase_or_empty() -> void:
	assert_false(Lexicon.new().load_data(_data(["lux"])))
	assert_false(Lexicon.new().load_data(_data([""])))
	assert_push_error_count(2)


func test_real_base_lexicon_loads() -> void:
	var lex := Lexicon.new()
	assert_true(lex.load_data(load("res://data/lexicon/base.tres")), lex.error)
	assert_eq(lex.word_count(), 18, "7 base + 5 apócrifos + 6 orações (002)")


# --- consultas -------------------------------------------------------------------------------

func test_is_word() -> void:
	var lex := _base()
	assert_true(lex.is_word("LUX"))
	assert_false(lex.is_word("LU"))
	assert_false(lex.is_word("XUL"))
	assert_eq(lex.word_for("CRUX").latin, "CRUX")
	assert_null(lex.word_for("NADA"))


func test_is_prefix_respects_capacity() -> void:
	var lex := _base()
	assert_true(lex.is_prefix("L", 5))
	assert_true(lex.is_prefix("LUX", 5), "a palavra inteira também é prefixo")
	assert_true(lex.is_prefix("MORT", 6))
	assert_false(lex.is_prefix("MORT", 5), "MORTIS não cabe num atril de 5")
	assert_false(lex.is_prefix("LQ", 8))
	assert_false(lex.is_prefix("", 5), "vazio não é prefixo")


func test_words_with_prefix_sorted_and_limited() -> void:
	var lex := _base()
	var all: Array[WordData] = lex.words_with_prefix("", 5, 10)
	assert_eq(all.size(), 6, "MORTIS fica de fora com capacidade 5")
	assert_eq(all[0].latin.length(), 3, "mais curtas primeiro")
	var few: Array[WordData] = lex.words_with_prefix("", 8, 3)
	assert_eq(few.size(), 3)
	var a: Array[WordData] = lex.words_with_prefix("A", 5, 3)
	assert_eq(a.size(), 1)
	assert_eq(a[0].latin, "AQUA")


func test_next_letters() -> void:
	var lex := _base()
	assert_eq(lex.next_letters("L", 5), PackedStringArray(["U"]))
	assert_eq(lex.next_letters("LUX", 5), PackedStringArray())
	var first: PackedStringArray = lex.next_letters("", 5)
	for ch: String in ["L", "P", "C", "V", "A", "I"]:
		assert_has(first, ch)
	assert_does_not_have(first, "M", "M só começa MORTIS, que não cabe")
	assert_has(lex.next_letters("", 6), "M")
