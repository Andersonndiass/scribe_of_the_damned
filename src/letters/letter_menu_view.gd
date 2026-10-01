class_name LetterMenuView
extends Node2D
## Desenho do menu da letra (017 T1720; design-agent T1700 e T1800; animation-agent T1700).
## Painel acima do escriba (abaixo quando falta espaço em cima), 3 cartas 28×28 com o losango da
## letra do atlas ampliado 2× (a rara usa a linha GOLD do atlas), foco = carta 2 px acima com
## borda INK de 2 px, barra do tempo em 25 degraus (INK_SOFT; INK no fim, alternando nos últimos
## 0,7 s), "+k" com menus na fila e moldura INK de 2 px na borda da tela durante a câmera lenta.
## Sem marca nas letras úteis (D-087 item 4). Clique numa carta escolhe; passar o mouse foca.

const ATLAS := preload("res://assets/placeholders/ltr_atlas.tres")
const ATLAS_ORDER := "ACDEFGILMNOPQRSTUVXB"
const CELL := 10
const SIZE := Vector2(100, 46)
## Painel relativo aos pés do escriba; limites da tela (T1800: My ≥ 44, margem 6 px).
const ABOVE := Vector2(-50, -67)
const BELOW_Y := 14.0
const MIN_POS := Vector2(7, 44)
const MAX_POS := Vector2(533, 252)
const CARD := 28.0
const CARD_STEP := 32.0
const CARD_PAD := 4.0
const CLICK_GROW := 2.0
const LIFT := 2.0
const BAR := Rect2(4, 37, 92, 5)
const BAR_STEPS := 25
const INK_LAST := 0.5
const SCREEN := Vector2(640, 360)
## Tinta Iluminada (design-agent T1801): cantoneiras INK nas 3 cartas (não marca a útil).
const CORNER := preload("res://assets/placeholders/vfx_illum_corner_tl.png")
const FRAME_W := 2.0

var menu: LetterMenu
var _origin := Vector2.ZERO


func _ready() -> void:
	top_level = true
	z_index = 60


func panel_origin() -> Vector2:
	if menu == null or menu.player == null:
		return MIN_POS
	var feet: Vector2 = menu.player.global_position.round()
	var p: Vector2 = feet + ABOVE
	if p.y < MIN_POS.y:
		p.y = feet.y + BELOW_Y
	return p.clamp(MIN_POS, MAX_POS)


func card_rect(i: int) -> Rect2:
	return Rect2(_origin + Vector2(CARD_PAD + CARD_STEP * i, CARD_PAD), Vector2(CARD, CARD))


func _process(_delta: float) -> void:
	visible = menu != null and menu.is_open()
	if visible:
		_origin = panel_origin()
		queue_redraw()


func _input(event: InputEvent) -> void:
	if menu == null or not menu.is_open():
		return
	var mouse := get_global_mouse_position()
	for i: int in menu.options.size():
		if not card_rect(i).grow(CLICK_GROW).has_point(mouse):
			continue
		if event is InputEventMouseMotion:
			menu.focus = i
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			menu.pick(i)
			get_viewport().set_input_as_handled()
		return


func _draw() -> void:
	if menu == null or not menu.is_open():
		return
	_draw_screen_frame()
	UiStyle.draw_plate(self, Rect2(_origin, SIZE))
	for i: int in menu.options.size():
		_draw_card(i, menu.options[i], i == menu.focus)
		if menu.illuminated:
			_draw_corners(card_rect(i).grow(1))
	_draw_timer()
	if menu.queued() > 0:
		var tag := "+%d" % menu.queued()
		var w: float = PixelFont.width(tag) + 4
		var r := Rect2(_origin + Vector2(SIZE.x - w, -9), Vector2(w, 9))
		draw_rect(r, Palette.INK)
		PixelFont.draw(self, tag, r.position + Vector2(2, 2), Palette.CHALK)


func _draw_card(i: int, o: Dictionary, focused: bool) -> void:
	var r: Rect2 = card_rect(i)
	if focused:
		r.position.y -= LIFT
		draw_rect(r, Palette.INK)
		draw_rect(r.grow(-2), Palette.PARCHMENT)
	else:
		draw_rect(r, Palette.INK_SOFT)
		draw_rect(r.grow(-1), Palette.PARCHMENT_OLD)
	var index: int = maxi(0, ATLAS_ORDER.find(o["letter"]))
	var src := Rect2(index * CELL, (1 if o["rare"] else 0) * CELL, CELL, CELL)
	var dst := Rect2(r.position + (r.size - Vector2(CELL, CELL) * 2.0) / 2.0, Vector2(CELL, CELL) * 2.0)
	draw_texture_rect_region(ATLAS, dst, src)


func _draw_corners(r: Rect2) -> void:
	var s: Vector2 = CORNER.get_size()
	draw_texture_rect(CORNER, Rect2(r.position, s), false)
	draw_texture_rect(CORNER, Rect2(Vector2(r.end.x, r.position.y), Vector2(-s.x, s.y)), false)
	draw_texture_rect(CORNER, Rect2(Vector2(r.position.x, r.end.y), Vector2(s.x, -s.y)), false)
	draw_texture_rect(CORNER, Rect2(r.end, -s), false)


## Barra em 25 degraus que esvazia pela direita; INK no último meio segundo; nos últimos 0,7 s
## alterna INK/INK_SOFT (a 100 ms; a 50 ms nos últimos 0,2 s) — pisca sem alpha.
func _draw_timer() -> void:
	var t: LetterMenuTuning = menu.tuning
	var frac: float = clampf(menu.left / maxf(menu.total, 0.001), 0.0, 1.0)
	frac = ceilf(frac * BAR_STEPS) / BAR_STEPS
	var fill: Color = Palette.INK if menu.left <= INK_LAST else Palette.INK_SOFT
	if menu.left <= t.blink_window:
		var period: float = 0.05 if menu.left <= t.blink_fast_window else 0.1
		if int(menu.left / period) % 2 == 1:
			fill = Palette.INK_SOFT if fill == Palette.INK else Palette.INK
	UiStyle.draw_bar(self, Rect2(_origin + BAR.position, BAR.size), frac, Palette.PARCHMENT_OLD, fill)


## Câmera lenta: moldura INK de 2 px na borda da tela (sem véu; o xadrez esconderia o escriba).
func _draw_screen_frame() -> void:
	var inv: Transform2D = get_viewport().get_canvas_transform().affine_inverse()
	var tl: Vector2 = inv * Vector2.ZERO
	draw_rect(Rect2(tl, Vector2(SCREEN.x, FRAME_W)), Palette.INK)
	draw_rect(Rect2(tl + Vector2(0, SCREEN.y - FRAME_W), Vector2(SCREEN.x, FRAME_W)), Palette.INK)
	draw_rect(Rect2(tl, Vector2(FRAME_W, SCREEN.y)), Palette.INK)
	draw_rect(Rect2(tl + Vector2(SCREEN.x - FRAME_W, 0), Vector2(FRAME_W, SCREEN.y)), Palette.INK)
