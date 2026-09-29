class_name MenuList
extends RefCounted
## Navegação de menu por teclado (007 FR-713): ↑/↓ (ações move_up/move_down, que já incluem W/S e
## as setas e seguem o remap) movem o foco, dando a volta e pulando itens desabilitados;
## Espaço (cast) ou Enter (shop_next) confirmam; Esc (pause) volta. Lógica pura; quem desenha é
## a tela, com `focus` e `items`.

signal chosen(id: StringName)
signal back()
signal focus_changed(index: int)

## Cada item: {"id": StringName, "label": String (chave de tradução), "enabled": bool}.
var items: Array[Dictionary] = []
var focus: int = -1


func add(id: StringName, label: String, enabled: bool = true) -> void:
	items.append({"id": id, "label": label, "enabled": enabled})
	if focus < 0 and enabled:
		focus = items.size() - 1


func focused_id() -> StringName:
	return items[focus]["id"] if focus >= 0 else &""


## Retorna true se a entrada era do menu.
func handle_input(event: InputEvent) -> bool:
	if not event.is_pressed() or event.is_echo():
		return false
	if event.is_action(&"move_down"):
		_move(1)
	elif event.is_action(&"move_up"):
		_move(-1)
	elif event.is_action(&"cast") or event.is_action(&"shop_next") or event.is_action(&"ui_accept"):
		if focus >= 0:
			chosen.emit(focused_id())
	elif event.is_action(&"pause") or event.is_action(&"ui_cancel"):
		back.emit()
	else:
		return false
	return true


func _move(step: int) -> void:
	if items.is_empty():
		return
	var i: int = focus
	for n: int in items.size():
		i = (i + step + items.size()) % items.size()
		if items[i]["enabled"]:
			focus = i
			focus_changed.emit(focus)
			return
