extends GutTest
## T210 ComboBook (002 FR-202, FR-204; D-099): par em qualquer ordem, GLORIA/PURGO fora, parceiras.

var _book: ComboBook
var _lux: WordData
var _ignis: WordData
var _pax: WordData
var _crux: WordData
var _gloria: WordData
var _flamma: ComboData


func _word(id: StringName, eligible: bool = true) -> WordData:
	var w := WordData.new()
	w.id = id
	w.latin = String(id).to_upper()
	w.combo_eligible = eligible
	return w


func before_each() -> void:
	_lux = _word(&"lux")
	_ignis = _word(&"ignis")
	_pax = _word(&"pax")
	_crux = _word(&"crux")
	_gloria = _word(&"gloria", false)
	_flamma = ComboData.new()
	_flamma.id = &"flamma"
	_flamma.word_a = _lux
	_flamma.word_b = _ignis
	var caecitas := ComboData.new()
	caecitas.id = &"caecitas"
	caecitas.word_a = _lux
	caecitas.word_b = _pax
	var combos: Array[ComboData] = [_flamma, caecitas]
	_book = ComboBook.new(combos)


func test_find_pair_in_any_order() -> void:
	assert_eq(_book.find(_lux, _ignis), _flamma)
	assert_eq(_book.find(_ignis, _lux), _flamma)
	assert_null(_book.find(_ignis, _pax), "par sem combo")
	assert_null(_book.find(_lux, _lux), "a mesma palavra não fecha combo")


func test_ineligible_words_never_combo() -> void:
	var bad := ComboData.new()
	bad.id = &"bad"
	bad.word_a = _gloria
	bad.word_b = _lux
	var combos: Array[ComboData] = [bad]
	var book := ComboBook.new(combos)
	assert_null(book.find(_gloria, _lux), "GLORIA fica fora (FR-204)")


func test_partners_of_lists_the_other_word_of_each_pair() -> void:
	assert_eq(_book.partners_of(_lux), PackedStringArray(["IGNIS", "PAX"]))
	assert_eq(_book.partners_of(_crux), PackedStringArray(), "sem par")
