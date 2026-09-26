class_name Lexicon
extends RefCounted
## Dicionário em memória (FR-014, Princípio VIII). load_data() valida e FALHA com mensagem
## clara se alguma palavra violar as regras: 3 a 8 letras, só letras do alfabeto, maiúsculas,
## sem duplicatas. Consultas de prefixo usam um índice construído no load.

var data: LexiconData
## Mensagem do último erro de validação ("" se carregou bem).
var error: String = ""

var _words: Dictionary[String, WordData] = {}
## Filtro de palavras conhecidas (002 FR-201). Vazio = todas conhecidas.
var _known: Callable = Callable()
## prefixo -> palavras que começam com ele (inclui a própria palavra).
var _by_prefix: Dictionary[String, Array] = {}


func load_data(lexicon: LexiconData) -> bool:
	data = lexicon
	error = ""
	_words.clear()
	_by_prefix.clear()
	if lexicon == null:
		return _fail("LexiconData nulo")
	var alphabet: Dictionary[String, bool] = {}
	for ch: String in lexicon.alphabet:
		alphabet[ch] = true
	for w: WordData in lexicon.words:
		if w == null:
			return _fail("palavra nula no LexiconData")
		var latin: String = w.latin
		if latin.is_empty() or latin != latin.to_upper():
			return _fail("'%s' precisa estar em maiúsculas e não pode ser vazia" % latin)
		if latin.length() < lexicon.min_length or latin.length() > lexicon.max_length:
			return _fail("'%s' tem %d letras; o permitido é de %d a %d" % [
				latin, latin.length(), lexicon.min_length, lexicon.max_length])
		for ch: String in latin:
			if not alphabet.has(ch):
				return _fail("'%s' usa a letra '%s', fora do alfabeto" % [latin, ch])
		if _words.has(latin):
			return _fail("'%s' está duplicada" % latin)
		_words[latin] = w
		for n: int in range(1, latin.length() + 1):
			var prefix: String = latin.substr(0, n)
			if not _by_prefix.has(prefix):
				_by_prefix[prefix] = []
			_by_prefix[prefix].append(w)
	return true


## Define quais palavras valem para o jogador (as outras continuam validadas, mas invisíveis).
func set_known_filter(filter: Callable) -> void:
	_known = filter


func is_known(w: WordData) -> bool:
	return not _known.is_valid() or _known.call(w)


func word_count() -> int:
	return _words.size()


func is_word(text: String) -> bool:
	return _words.has(text) and is_known(_words[text])


func word_for(text: String) -> WordData:
	var w: WordData = _words.get(text, null)
	return w if w != null and is_known(w) else null


## `text` começa alguma palavra (ou é a palavra) de até `max_len` letras.
func is_prefix(text: String, max_len: int) -> bool:
	if text.is_empty() or not _by_prefix.has(text):
		return false
	for w: WordData in _by_prefix[text]:
		if w.latin.length() <= max_len and is_known(w):
			return true
	return false


## Palavras que começam com `prefix` e cabem em `max_len`, das mais curtas para as mais longas.
## Prefixo vazio = todas as que cabem.
func words_with_prefix(prefix: String, max_len: int, limit: int) -> Array[WordData]:
	var source: Array = _words.values() if prefix.is_empty() else _by_prefix.get(prefix, [])
	var out: Array[WordData] = []
	for w: WordData in source:
		if w.latin.length() <= max_len and is_known(w):
			out.append(w)
	out.sort_custom(func(a: WordData, b: WordData) -> bool:
		if a.latin.length() != b.latin.length():
			return a.latin.length() < b.latin.length()
		return a.latin < b.latin)
	return out.slice(0, limit)


## Letras que continuam `prefix` rumo a alguma palavra de até `max_len` letras (sem repetição).
func next_letters(prefix: String, max_len: int) -> PackedStringArray:
	var out := PackedStringArray()
	var n: int = prefix.length()
	var source: Array = _words.values() if prefix.is_empty() else _by_prefix.get(prefix, [])
	for w: WordData in source:
		if w.latin.length() <= max_len and w.latin.length() > n and is_known(w):
			var ch: String = w.latin[n]
			if not out.has(ch):
				out.append(ch)
	return out


func _fail(message: String) -> bool:
	error = "Lexicon: " + message
	push_error(error)
	_words.clear()
	_by_prefix.clear()
	return false
