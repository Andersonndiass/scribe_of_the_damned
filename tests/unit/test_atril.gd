extends GutTest
## T042 [TEST-FIRST] Atril: fila ordenada, recusa quando cheio, estados (FR-015, FR-016, D-008, D-009).

var _lex: Lexicon


func before_all() -> void:
	_lex = Lexicon.new()
	var d := LexiconData.new()
	d.alphabet = PackedStringArray("A C D E F G I L M N O P Q R S T U V X B".split(" "))
	for latin: String in ["LUX", "PAX", "CRUX", "VITA", "AQUA", "IGNIS", "MORTIS"]:
		var w := WordData.new()
		w.id = StringName(latin.to_lower())
		w.latin = latin
		d.words.append(w)
	_lex.load_data(d)


func _atril(cap: int, letters: String) -> Atril:
	var a := Atril.new(cap)
	for ch: String in letters:
		a.push(ch, false)
	return a


func test_keeps_collection_order() -> void:
	var a := _atril(5, "XUL")
	assert_eq(a.text(), "XUL", "não reordena")


func test_rejects_when_full() -> void:
	var a := _atril(3, "LUX")
	assert_false(a.push("P", false))
	assert_eq(a.text(), "LUX")
	assert_eq(a.size(), 3)


func test_states() -> void:
	assert_eq(_atril(5, "").state(_lex), Atril.Status.EMPTY)
	assert_eq(_atril(5, "L").state(_lex), Atril.Status.PARTIAL)
	assert_eq(_atril(5, "LU").state(_lex), Atril.Status.PARTIAL)
	assert_eq(_atril(5, "LUX").state(_lex), Atril.Status.VALID)
	assert_eq(_atril(5, "LQ").state(_lex), Atril.Status.FILL)
	assert_eq(_atril(3, "QQQ").state(_lex), Atril.Status.FULL_REJECT)


func test_prefix_of_word_that_does_not_fit_is_fill() -> void:
	assert_eq(_atril(5, "MORT").state(_lex), Atril.Status.FILL, "MORTIS não cabe em 5")
	assert_eq(_atril(6, "MORT").state(_lex), Atril.Status.PARTIAL)


func test_full_with_valid_word_is_valid() -> void:
	assert_eq(_atril(4, "CRUX").state(_lex), Atril.Status.VALID)


func test_take_all_returns_and_clears() -> void:
	var a := Atril.new(5)
	a.push("L", false)
	a.push("U", true)
	a.push("X", false)
	assert_eq(a.rare_count(), 1)
	var taken: Dictionary = a.take_all()
	assert_eq(taken["text"], "LUX")
	assert_eq(taken["rare_count"], 1)
	assert_eq(a.size(), 0)
	assert_eq(a.state(_lex), Atril.Status.EMPTY)


func test_capacity_can_grow_up_to_8() -> void:
	var a := Atril.new(5)
	a.set_capacity(8)
	assert_eq(a.capacity, 8)
	a.set_capacity(12)
	assert_eq(a.capacity, 8, "teto de 8 (D-007)")
