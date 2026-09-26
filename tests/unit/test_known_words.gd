extends GutTest
## 002 T201 [TEST-FIRST] Vocabulário conhecido (FR-201, SC-203): palavra que exige desbloqueio é
## invisível ao atril, às dicas e ao drop até ser desbloqueada.

var _lex: Lexicon
var _unlocked: Array[StringName] = []


func _word(latin: String, needs_unlock: bool) -> WordData:
	var w := WordData.new()
	w.id = StringName(latin.to_lower())
	w.latin = latin
	w.requires_unlock = needs_unlock
	return w


func before_each() -> void:
	_unlocked.clear()
	var d := LexiconData.new()
	d.alphabet = PackedStringArray("A C D E F G I L M N O P Q R S T U V X B".split(" "))
	d.words.append(_word("LUX", false))
	d.words.append(_word("LUMEN", true))
	d.words.append(_word("FIDES", true))
	_lex = Lexicon.new()
	assert_true(_lex.load_data(d))
	_lex.set_known_filter(func(w: WordData) -> bool: return not w.requires_unlock or _unlocked.has(w.id))


func test_locked_word_is_not_a_word_nor_a_prefix() -> void:
	assert_true(_lex.is_word("LUX"))
	assert_false(_lex.is_word("LUMEN"), "apócrifo bloqueado não vale")
	assert_null(_lex.word_for("LUMEN"))
	assert_true(_lex.is_prefix("LU", 5), "LU continua prefixo por causa de LUX")
	assert_false(_lex.is_prefix("LUM", 5))
	assert_false(_lex.is_prefix("F", 5))


func test_locked_word_is_hidden_from_hints_and_next_letters() -> void:
	var hints: Array = _lex.words_with_prefix("", 8, 10).map(func(w: WordData) -> String: return w.latin)
	assert_eq(hints, ["LUX"])
	assert_eq(_lex.next_letters("LU", 5), PackedStringArray(["X"]))
	assert_does_not_have(_lex.next_letters("", 5), "F")


func test_unlocking_makes_the_word_known() -> void:
	_unlocked.append(&"lumen")
	assert_true(_lex.is_word("LUMEN"))
	assert_true(_lex.is_prefix("LUM", 5))
	assert_has(_lex.next_letters("LU", 5), "M")
	assert_false(_lex.is_word("FIDES"), "só a desbloqueada")


func test_locked_words_are_still_validated_on_load() -> void:
	var d := LexiconData.new()
	d.alphabet = PackedStringArray(["L", "U", "X"])
	d.words.append(_word("LUX", false))
	d.words.append(_word("HAX", true))
	assert_false(Lexicon.new().load_data(d), "bloqueada ou não, latim inválido falha no load")
	assert_push_error("fora do alfabeto")


func test_game_state_unlock_and_filter() -> void:
	GameState.unlocked_words.clear()
	var lumen := _word("LUMEN", true)
	assert_false(GameState.is_word_known(lumen))
	watch_signals(EventBus)
	GameState.unlock_word(lumen)
	assert_true(GameState.is_word_known(lumen))
	assert_signal_emitted(EventBus, "word_unlocked")
	GameState.unlocked_words.clear()


func test_real_lexicon_has_18_words_and_apocrypha_start_locked() -> void:
	var data: LexiconData = load("res://data/lexicon/base.tres")
	assert_eq(data.words.size(), 18)
	var locked: Array = data.words.filter(func(w: WordData) -> bool: return w.requires_unlock).map(func(w: WordData) -> String: return w.latin)
	locked.sort()
	assert_eq(locked, ["FIDES", "GLORIA", "LUMEN", "PURGO", "VERBUM"])
