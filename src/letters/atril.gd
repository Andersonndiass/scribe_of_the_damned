class_name Atril
extends RefCounted
## O atril: fila ordenada de letras coletadas (FR-015, FR-016). Sem reordenação (D-009).
## Lógica pura; a visualização fica no HUD (T072).

enum Status { EMPTY, FILL, PARTIAL, VALID, FULL_REJECT }

const MAX_CAPACITY := 8

var capacity: int = 5
var _letters := PackedStringArray()
var _rare: Array[bool] = []


func _init(initial_capacity: int = 5) -> void:
	set_capacity(initial_capacity)


func set_capacity(value: int) -> void:
	capacity = clampi(value, 1, MAX_CAPACITY)


func size() -> int:
	return _letters.size()


func is_full() -> bool:
	return _letters.size() >= capacity


func text() -> String:
	return "".join(_letters)


func letters() -> PackedStringArray:
	return _letters.duplicate()


## Bit i ligado = a letra i é rara.
func rare_mask() -> int:
	var mask: int = 0
	for i: int in _rare.size():
		if _rare[i]:
			mask |= 1 << i
	return mask


func rare_count() -> int:
	return _rare.count(true)


## Tenta colocar a letra no fim da fila. false = atril cheio, letra recusada (D-008).
func push(letter: String, rare: bool) -> bool:
	if is_full():
		return false
	_letters.append(letter)
	_rare.append(rare)
	return true


func state(lexicon: Lexicon) -> Status:
	if _letters.is_empty():
		return Status.EMPTY
	var t: String = text()
	if lexicon.is_word(t):
		return Status.VALID
	if lexicon.is_prefix(t, capacity):
		return Status.PARTIAL
	if is_full():
		return Status.FULL_REJECT
	return Status.FILL


## Esvazia e devolve o conteúdo: {"text", "letters", "rare", "rare_count"}.
func take_all() -> Dictionary:
	var out: Dictionary = {
		"text": text(),
		"letters": _letters.duplicate(),
		"rare": _rare.duplicate(),
		"rare_count": rare_count(),
	}
	clear()
	return out


func clear() -> void:
	_letters.clear()
	_rare.clear()
