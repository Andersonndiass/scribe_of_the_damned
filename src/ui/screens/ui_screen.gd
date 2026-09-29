class_name UiScreen
extends Node2D
## Base das telas de menu (007 FR-712, FR-713): um MenuList navegado pelo teclado; pedir outra tela
## é um sinal (`EventBus.screen_requested`) que o ScreenRouter atende com a transição.
## O roteador trava a entrada durante a transição (`accepting`).

var menu := MenuList.new()
var accepting: bool = true
var age: float = 0.0


func _ready() -> void:
	menu.chosen.connect(_on_chosen)
	menu.back.connect(_on_back)
	menu.focus_changed.connect(func(_i: int) -> void: queue_redraw())


func _process(delta: float) -> void:
	age += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not accepting:
		return
	if handle_input(event):
		get_viewport().set_input_as_handled()


## Entrada da tela (as telas podem sobrescrever). Retorna true se consumiu.
func handle_input(event: InputEvent) -> bool:
	return menu.handle_input(event)


func request(screen: StringName) -> void:
	EventBus.screen_requested.emit(screen)


## Desenha as fitas do menu numa coluna a partir de `top`, centradas em `center_x`.
func draw_menu(center_x: float, top: float, step: float = 22.0, min_w: float = UiStyle.RIBBON_MIN_W) -> void:
	for i: int in menu.items.size():
		var it: Dictionary = menu.items[i]
		var state: StringName = &"focus" if i == menu.focus else (&"idle" if it["enabled"] else &"disabled")
		UiStyle.draw_ribbon(self, Vector2(center_x, top + i * step), tr(it["label"]), state, min_w)


func _on_chosen(_id: StringName) -> void:
	pass


func _on_back() -> void:
	pass


## Lê um JSON de dados das telas (`data/ui/`).
static func read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## ←/→ (move_left/move_right) numa fileira de `count` itens; devolve o novo índice (ou -1 se não era).
static func row_step(event: InputEvent, index: int, count: int) -> int:
	if not event.is_pressed() or event.is_echo():
		return -1
	if event.is_action(&"move_right"):
		return (index + 1) % count
	if event.is_action(&"move_left"):
		return (index - 1 + count) % count
	return -1


static func is_confirm(event: InputEvent) -> bool:
	return event.is_pressed() and not event.is_echo() and (event.is_action(&"cast") or event.is_action(&"shop_next") or event.is_action(&"ui_accept"))


static func is_back(event: InputEvent) -> bool:
	return event.is_pressed() and not event.is_echo() and (event.is_action(&"pause") or event.is_action(&"ui_cancel"))


## Cadeado placeholder 7×8 com o topo em `pos`.
func draw_padlock(pos: Vector2, color: Color) -> void:
	var p := pos.round()
	draw_rect(Rect2(p.x + 1, p.y, 5, 1), color)
	draw_rect(Rect2(p.x + 1, p.y, 1, 4), color)
	draw_rect(Rect2(p.x + 5, p.y, 1, 4), color)
	draw_rect(Rect2(p.x, p.y + 3, 7, 5), color)
	draw_rect(Rect2(p.x + 3, p.y + 5, 1, 2), Palette.INK)
