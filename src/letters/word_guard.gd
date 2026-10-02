class_name WordGuard
extends RefCounted
## A palavra guardada (D-100; 010 D-101: a Hildegarda tem 2 espaços). Quando o atril fica com
## palavra válida e há espaço, a palavra sai do atril para cá (a mais nova no fim da lista). Espaço
## conjura a guardada (com 2 sem par, a MAIS NOVA — resposta "3a"), o combo das 2 guardadas
## parceiras (resposta "2a") ou o combo de uma delas com a palavra pronta do atril. Heresia, Traça,
## Rasura e fim de onda não mexem nela. Lógica pura; vive no LetterField.

var capacity: int = 1
## Cada uma: {"word": WordData, "rare_count": int, "rare_mask": int, "letters": PackedStringArray}.
var entries: Array[Dictionary] = []
## Compatibilidade (1 espaço): a mais nova.
var word: WordData:
	get:
		return entries[-1]["word"] if not entries.is_empty() else null
var rare_count: int:
	get:
		return entries[-1]["rare_count"] if not entries.is_empty() else 0
var rare_mask: int:
	get:
		return entries[-1]["rare_mask"] if not entries.is_empty() else 0


func _init(p_capacity: int = 1) -> void:
	capacity = maxi(1, p_capacity)


func is_held() -> bool:
	return not entries.is_empty()


func has_room() -> bool:
	return entries.size() < capacity


func size() -> int:
	return entries.size()


## Guarda o que saiu do atril (`Atril.take_all()`).
func store(taken: Dictionary, p_word: WordData) -> void:
	var mask: int = 0
	var rare: Array = taken.get("rare", [])
	for i: int in rare.size():
		if rare[i]:
			mask |= 1 << i
	entries.append({"word": p_word, "rare_count": int(taken.get("rare_count", 0)), "rare_mask": mask,
		"letters": taken.get("letters", PackedStringArray())})


## Tira a mais nova (vazio se não há).
func take() -> Dictionary:
	return take_at(entries.size() - 1)


func take_at(i: int) -> Dictionary:
	if i < 0 or i >= entries.size():
		return {}
	var out: Dictionary = entries[i]
	entries.remove_at(i)
	return out


## A guardada (da mais antiga para a mais nova) que forma combo com `w`; −1 se nenhuma.
func find_partner(w: WordData, book: ComboBook) -> int:
	for i: int in entries.size():
		if book.find(entries[i]["word"], w) != null:
			return i
	return -1


## O combo das 2 guardadas entre si (Hildegarda), ou null.
func pair_combo(book: ComboBook) -> ComboData:
	if entries.size() < 2:
		return null
	return book.find(entries[0]["word"], entries[1]["word"])


func words() -> Array[WordData]:
	var out: Array[WordData] = []
	for e: Dictionary in entries:
		out.append(e["word"])
	return out


func clear() -> void:
	entries.clear()
