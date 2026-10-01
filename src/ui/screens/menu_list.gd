class_name MenuList
extends RefCounted
## Navegação de menu por teclado (007 FR-713): ↑/↓ (ações move_up/move_down, que já incluem W/S e
## as setas e seguem o remap) movem o foco, dando a volta e pulando itens desabilitados;
## Espaço (cast) ou Enter (shop_next) confirmam; Esc (pause) volta. Mouse (pedido do autor, D-084):
## passar por cima foca, clique esquerdo confirma, clique direito volta — a tela registra a área de
## cada item ao desenhar (`set_rect`) e manda o evento já nas coordenadas dela (`make_input_local`).
## Lógica pura; quem desenha é a tela, com `focus` e `items`.

signal chosen(id: StringName)
signal back()
signal focus_changed(index: int)

## Cada item: {"id": StringName, "label": String (chave de tradução), "enabled": bool}.
var items: Array[Dictionary] = []
var focus: int = -1
## Área clicável de cada item, nas coordenadas da tela (vazia = sem mouse nesse item).
var rects: Array[Rect2] = []


func add(id: StringName, label: String, enabled: bool = true) -> void:
	items.append({"id": id, "label": label, "enabled": enabled})
	if focus < 0 and enabled:
		focus = items.size() - 1


func focused_id() -> StringName:
	return items[focus]["id"] if focus >= 0 else &""


func set_rect(i: int, r: Rect2) -> void:
	if rects.size() < items.size():
		rects.resize(items.size())
	if i >= 0 and i < rects.size():
		rects[i] = r


## Item habilitado sob o ponto (coordenadas da tela), ou -1.
func item_at(p: Vector2) -> int:
	for i: int in mini(rects.size(), items.size()):
		if rects[i].has_area() and rects[i].has_point(p) and items[i]["enabled"]:
			return i
	return -1


## Retorna true se a entrada era do menu.
func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouse:
		return _handle_mouse(event as InputEventMouse)
	if not event.is_pressed() or event.is_echo():
		return false
	if event.is_action(&"move_down"):
		_move(1)
	elif event.is_action(&"move_up"):
		_move(-1)
	elif event.is_action(&"cast") or event.is_action(&"shop_next") or event.is_action(&"ui_accept"):
		if focus >= 0:
			EventBus.ui_confirmed.emit()
			chosen.emit(focused_id())
	elif event.is_action(&"pause") or event.is_action(&"ui_cancel"):
		EventBus.ui_backed.emit()
		back.emit()
	else:
		return false
	return true


func _handle_mouse(event: InputEventMouse) -> bool:
	var i: int = item_at(event.position)
	var button := event as InputEventMouseButton
	if button == null:
		if i >= 0 and i != focus:
			focus = i
			focus_changed.emit(focus)
			EventBus.ui_focus_changed.emit()
		return false  # passar por cima não consome o movimento
	if not button.pressed:
		return false
	if button.button_index == MOUSE_BUTTON_RIGHT:
		EventBus.ui_backed.emit()
		back.emit()
		return true
	if button.button_index == MOUSE_BUTTON_LEFT and i >= 0:
		if i != focus:
			focus = i
			focus_changed.emit(focus)
		EventBus.ui_confirmed.emit()
		chosen.emit(focused_id())
		return true
	return false


func _move(step: int) -> void:
	if items.is_empty():
		return
	var i: int = focus
	for n: int in items.size():
		i = (i + step + items.size()) % items.size()
		if items[i]["enabled"]:
			focus = i
			focus_changed.emit(focus)
			EventBus.ui_focus_changed.emit()
			return
