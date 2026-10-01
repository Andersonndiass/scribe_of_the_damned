class_name UiScreen
extends Node2D
## Base das telas de menu (007 FR-712, FR-713): um MenuList navegado pelo teclado; pedir outra tela
## é um sinal (`EventBus.screen_requested`) que o ScreenRouter atende com a transição.
## O roteador trava a entrada durante a transição (`accepting`).

## Aberta por cima da Pausa (dentro da partida): voltar fecha a tela em vez de pedir o Menu.
signal closed()

var menu := MenuList.new()
## O último `pointer_at` foi um clique (e não só o mouse passando por cima).
var clicked: bool = false
var embedded: bool = false
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
		ui_sound(event)


## Som de interface de uma entrada que uma tela consumiu (feedback do autor: botões sem som).
## Clique esquerdo ou confirmar → ui_confirmed; voltar ou clique direito → ui_backed; setas → foco.
## Repetições no mesmo instante (o MenuList também emite) caem na recarga do som.
static func ui_sound(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null:
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			EventBus.ui_confirmed.emit()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			EventBus.ui_backed.emit()
		return
	if event is InputEventMouseMotion or not event.is_pressed() or event.is_echo():
		return
	if is_confirm(event):
		EventBus.ui_confirmed.emit()
	elif is_back(event):
		EventBus.ui_backed.emit()
	elif event.is_action(&"move_left") or event.is_action(&"move_right") \
			or event.is_action(&"move_up") or event.is_action(&"move_down"):
		EventBus.ui_focus_changed.emit()


## Entrada da tela (as telas podem sobrescrever). Retorna true se consumiu. O mouse chega nas
## coordenadas da tela (as áreas dos itens são as do desenho).
func handle_input(event: InputEvent) -> bool:
	return menu.handle_input(local(event))


## O evento do mouse nas coordenadas desta tela (os outros passam como estão).
func local(event: InputEvent) -> InputEvent:
	return make_input_local(event) if event is InputEventMouse else event


func request(screen: StringName) -> void:
	EventBus.screen_requested.emit(screen)


## Sair da tela: volta à Pausa quando embutida; senão, ao Menu.
func leave() -> void:
	if embedded:
		closed.emit()
	else:
		request(&"menu")


## Desenha as fitas do menu numa coluna a partir de `top`, centradas em `center_x`.
func draw_menu(center_x: float, top: float, step: float = 22.0, min_w: float = UiStyle.RIBBON_MIN_W) -> void:
	for i: int in menu.items.size():
		var it: Dictionary = menu.items[i]
		var state: StringName = &"focus" if i == menu.focus else (&"idle" if it["enabled"] else &"disabled")
		var center := Vector2(center_x, top + i * step)
		UiStyle.draw_ribbon(self, center, tr(it["label"]), state, min_w)
		menu.set_rect(i, UiStyle.ribbon_rect(center, tr(it["label"]), min_w))


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
	var mb := event as InputEventMouseButton
	if mb != null:
		return mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT  # clique direito volta
	return event.is_pressed() and not event.is_echo() and (event.is_action(&"pause") or event.is_action(&"ui_cancel"))


## Mouse sobre uma fileira de áreas (coordenadas da tela): o índice sob o ponteiro ao passar por cima
## ou no clique esquerdo (aí `clicked` fica true); -1 se não há mouse ou área.
func pointer_at(event: InputEvent, rects: Array[Rect2]) -> int:
	clicked = false
	var m := local(event) as InputEventMouse
	if m == null:
		return -1
	var b := m as InputEventMouseButton
	if b != null and not (b.pressed and b.button_index == MOUSE_BUTTON_LEFT):
		return -1
	for i: int in rects.size():
		if rects[i].has_point(m.position):
			clicked = b != null
			return i
	return -1


## Cadeado 8×10 com o topo em `pos` (D-076; mapa do design-agent): alça INK de 2 px, corpo `body`
## com o claro `light` no canto de cima à direita, buraco da chave INK.
const PADLOCK: Array[String] = ["..KKKK..", ".KK..KK.", ".KK..KK.", ".KK..KK.", "KKKKKKKK",
	"KXXXXxxK", "KXXKKXxK", "KXXKKXXK", "KXXXXXXK", "KKKKKKKK"]


func draw_padlock(pos: Vector2, body: Color, light: Color = Palette.GOLD_LIGHT) -> void:
	var p := pos.round()
	for y: int in PADLOCK.size():
		for x: int in PADLOCK[y].length():
			var ch: String = PADLOCK[y][x]
			if ch == ".":
				continue
			var c: Color = Palette.INK if ch == "K" else (body if ch == "X" else light)
			draw_rect(Rect2(p.x + x, p.y + y, 1, 1), c)
