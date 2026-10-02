class_name WordGuard
extends RefCounted
## A palavra guardada (D-099; respostas do autor "1b2a3a"; mechanics-agent): quando o atril fica
## com palavra válida e a guarda está vazia, a palavra sai do atril para cá (1 espaço). Espaço
## conjura a guardada, ou o combo dela com a palavra pronta do atril. Heresia, Traça, Rasura e fim
## de onda não mexem nela. Lógica pura; vive no LetterField.

var word: WordData = null
var rare_count: int = 0
## Bit i = a letra i é rara (o HUD sublinha).
var rare_mask: int = 0
var letters := PackedStringArray()


func is_held() -> bool:
	return word != null


## Guarda o que saiu do atril (`Atril.take_all()`).
func store(taken: Dictionary, p_word: WordData) -> void:
	word = p_word
	rare_count = int(taken.get("rare_count", 0))
	rare_mask = 0
	var rare: Array = taken.get("rare", [])
	for i: int in rare.size():
		if rare[i]:
			rare_mask |= 1 << i
	letters = taken.get("letters", PackedStringArray())


## Tira a guardada: {"word", "rare_count", "letters"} (vazio se não há).
func take() -> Dictionary:
	if not is_held():
		return {}
	var out: Dictionary = {"word": word, "rare_count": rare_count, "letters": letters}
	clear()
	return out


func clear() -> void:
	word = null
	rare_count = 0
	rare_mask = 0
	letters = PackedStringArray()
