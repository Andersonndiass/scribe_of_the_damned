extends GutTest
## T210 ComboBook (002 FR-202, FR-204, D-044): par em qualquer ordem, janela de 8 s que só conta
## 2,5 s depois da 1ª letra, GLORIA/PURGO fora, combo não encadeia.

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
	var tuning := ComboTuning.new()
	tuning.window = 2.5
	tuning.max_open = 8.0
	var combos: Array[ComboData] = [_flamma, caecitas]
	_book = ComboBook.new(combos, tuning)


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
	var book := ComboBook.new(combos, _book.tuning)
	assert_null(book.find(_gloria, _lux), "GLORIA fica fora (FR-204)")


func test_combo_inside_window_after_first_letter() -> void:
	assert_null(_book.on_cast(_lux), "a 1ª palavra só abre a janela")
	assert_true(_book.is_open())
	assert_false(_book.is_window_running(), "os 2,5 s ainda não começaram")
	_book.tick(5.0)
	assert_true(_book.is_open(), "sem letra, fica aberta até 8 s")
	_book.on_letter_collected()
	assert_true(_book.is_window_running())
	_book.tick(2.0)
	assert_eq(_book.on_cast(_ignis), _flamma)


func test_window_expires_after_letter() -> void:
	_book.on_cast(_lux)
	_book.on_letter_collected()
	_book.tick(2.6)
	assert_false(_book.is_open(), "2,5 s depois da 1ª letra")
	assert_null(_book.on_cast(_ignis))


func test_max_open_without_letters() -> void:
	_book.on_cast(_lux)
	_book.tick(8.1)
	assert_false(_book.is_open(), "8 s sem coletar letra fecham a janela")


func test_only_first_letter_starts_the_clock() -> void:
	_book.on_cast(_lux)
	_book.on_letter_collected()
	_book.tick(2.0)
	_book.on_letter_collected()  # não reinicia
	_book.tick(0.6)
	assert_false(_book.is_open())


func test_combo_does_not_chain() -> void:
	_book.on_cast(_lux)
	_book.on_letter_collected()
	assert_eq(_book.on_cast(_ignis), _flamma)
	assert_false(_book.is_open(), "depois do combo a janela recomeça do zero")
	_book.on_letter_collected()
	assert_null(_book.on_cast(_lux), "IGNIS do combo não abre LUX+IGNIS de novo")
	assert_true(_book.is_open(), "LUX abre uma janela nova")


func test_ineligible_cast_closes_window() -> void:
	_book.on_cast(_lux)
	_book.on_letter_collected()
	assert_null(_book.on_cast(_gloria))
	assert_false(_book.is_open())


func test_non_combo_second_word_opens_new_window() -> void:
	_book.on_cast(_crux)
	_book.on_letter_collected()
	assert_null(_book.on_cast(_ignis), "CRUX+IGNIS não é combo")
	_book.on_letter_collected()
	assert_eq(_book.on_cast(_lux), _flamma, "IGNIS abriu a janela para LUX")


func test_partners_and_ready() -> void:
	_book.on_cast(_lux)
	var ids: Array[StringName] = _book.partner_ids()
	assert_eq(ids.size(), 2)
	assert_has(ids, &"ignis")
	assert_has(ids, &"pax")
	assert_true(_book.is_combo_ready(_pax))
	assert_false(_book.is_combo_ready(_crux))


func test_window_fraction_shrinks() -> void:
	_book.on_cast(_lux)
	assert_eq(_book.window_fraction(), 1.0, "cheia até a 1ª letra")
	_book.on_letter_collected()
	_book.tick(1.25)
	assert_almost_eq(_book.window_fraction(), 0.5, 0.001)
