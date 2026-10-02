class_name ComboBook
extends RefCounted
## Resolve combos (002 FR-202; D-099): o par (palavra guardada + palavra pronta no atril, em
## qualquer ordem) vira o combo. A janela de 2,5 s saiu (resposta do autor "3a"). Lógica pura.

var combos: Array[ComboData] = []


func _init(p_combos: Array[ComboData]) -> void:
	combos = p_combos


## O combo do par (qualquer ordem), ou null. Palavras fora de combo (GLORIA, PURGO) nunca fecham.
func find(a: WordData, b: WordData) -> ComboData:
	if a == null or b == null or a == b or not a.combo_eligible or not b.combo_eligible:
		return null
	for c: ComboData in combos:
		if (c.word_a.id == a.id and c.word_b.id == b.id) or (c.word_a.id == b.id and c.word_b.id == a.id):
			return c
	return null


## Latim das palavras que fecham combo com `word` (dicas do HUD).
func partners_of(word: WordData) -> PackedStringArray:
	var out := PackedStringArray()
	if word == null:
		return out
	for c: ComboData in combos:
		if c.word_a.id == word.id:
			out.append(c.word_b.latin)
		elif c.word_b.id == word.id:
			out.append(c.word_a.latin)
	return out
