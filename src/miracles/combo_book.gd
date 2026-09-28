class_name ComboBook
extends RefCounted
## Resolve combos e controla a janela (002 FR-202, FR-204, D-044). Lógica pura: o Caster chama
## on_cast / on_letter_collected / tick e decide o que disparar.
##   Depois de uma conjuração elegível, a janela fica aberta até max_open s; os `window` s só
##   começam a correr na 1ª letra coletada. Um combo fecha a janela (não encadeia).

var tuning: ComboTuning
var combos: Array[ComboData] = []
var last_word: WordData = null

var _open_left: float = 0.0
## < 0 enquanto a 1ª letra não foi coletada.
var _window_left: float = -1.0


func _init(p_combos: Array[ComboData], p_tuning: ComboTuning) -> void:
	combos = p_combos
	tuning = p_tuning


## O combo do par (qualquer ordem), ou null. Palavras fora de combo (GLORIA, PURGO) nunca fecham.
func find(a: WordData, b: WordData) -> ComboData:
	if a == null or b == null or a == b or not a.combo_eligible or not b.combo_eligible:
		return null
	for c: ComboData in combos:
		if (c.word_a.id == a.id and c.word_b.id == b.id) or (c.word_a.id == b.id and c.word_b.id == a.id):
			return c
	return null


## Registra a conjuração de `word`. Retorna o combo a disparar no lugar dela, ou null.
func on_cast(word: WordData) -> ComboData:
	var combo: ComboData = null
	if is_window_running():
		combo = find(last_word, word)
	if combo != null or not word.combo_eligible:
		close()
		return combo
	last_word = word
	_open_left = tuning.max_open
	_window_left = -1.0
	return null


func on_letter_collected() -> void:
	if is_open() and _window_left < 0.0:
		_window_left = tuning.window


func tick(delta: float) -> void:
	if not is_open():
		return
	if _window_left < 0.0:
		_open_left -= delta
		if _open_left <= 0.0:
			close()
	else:
		_window_left -= delta
		if _window_left <= 0.0:
			close()


func close() -> void:
	last_word = null
	_open_left = 0.0
	_window_left = -1.0


func is_open() -> bool:
	return last_word != null


func is_window_running() -> bool:
	return is_open() and _window_left > 0.0


## 1.0 até a 1ª letra; depois encolhe até 0 nos `window` s. 0 com a janela fechada.
func window_fraction() -> float:
	if not is_open():
		return 0.0
	if _window_left < 0.0:
		return 1.0
	return clampf(_window_left / tuning.window, 0.0, 1.0)


## Ids das palavras que fecham combo com a última conjurada (dicas do HUD).
func partner_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	if not is_open():
		return out
	for c: ComboData in combos:
		if c.word_a.id == last_word.id:
			out.append(c.word_b.id)
		elif c.word_b.id == last_word.id:
			out.append(c.word_a.id)
	return out


## A janela está aberta e `word` fecha combo com a última (estado COMBO_READY do atril).
func is_combo_ready(word: WordData) -> bool:
	return is_open() and find(last_word, word) != null
