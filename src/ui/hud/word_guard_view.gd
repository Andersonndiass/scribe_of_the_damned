class_name HudWordGuard
extends Node2D
## A palavra guardada (D-100; design-agent, ficha UI_WORD_GUARD). Placa fixa à direita do atril, na
## mesma linha; caixa da altura de um espaço do atril com o latim em INK sobre GOLD_LIGHT (texto
## nunca em GOLD), raras sublinhadas e a cauda de marcador de página (a silhueta da guarda). Vazia:
## caixa INK_SOFT/PARCHMENT_OLD. Combo pronto: moldura dupla (INK por fora, GOLD por dentro), como
## o COMBO_READY do atril. Entrada: a caixa voa do atril em 4 degraus de 50 ms; consumo: miolo
## CHALK por 50 ms.

const PLATE := Rect2(393, 308, 64, 32)
const BOX := Rect2(396, 313, 58, 16)
const TEXT_X := 425.0
const TEXT_Y := 318.0
const RARE_Y := 325.0
const GLYPH_STEP := 6
const TAIL_POS := Vector2(423, 329)
## Cauda 5×5: # = borda, o = miolo, . = vazio.
const TAIL: Array[String] = ["#ooo#", "#ooo#", "#o#o#", "##.##", "#...#"]
const FLY_X: Array[float] = [291.0, 326.0, 361.0, 396.0]
const STEP := 0.05
const CONSUME_TIME := 0.05

var word: WordData = null
var rare_mask: int = 0
var combo_ready: bool = false
## Degrau do voo (−1 = parado) e o resto do consumo.
var _fly: int = -1
var _fly_t: float = 0.0
var _consume_left: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.word_stored.connect(func(w: WordData, _r: int, _p: PackedStringArray, mask: int) -> void:
		word = w
		rare_mask = mask
		_fly = 0
		_fly_t = 0.0
		queue_redraw())
	EventBus.stored_word_released.connect(func(_w: WordData, _c: StringName) -> void:
		word = null
		combo_ready = false
		_fly = -1
		_consume_left = CONSUME_TIME
		queue_redraw())
	EventBus.player_died.connect(func() -> void:
		word = null
		queue_redraw())


func _process(delta: float) -> void:
	if _fly >= 0:
		_fly_t += delta
		if _fly_t >= STEP:
			_fly_t = 0.0
			_fly += 1
			if _fly >= FLY_X.size():
				_fly = -1
		queue_redraw()
	if _consume_left > 0.0:
		_consume_left -= delta
		queue_redraw()
	var atril := get_parent().get_node_or_null(^"Atril") as HudAtril  # irmão no mesmo HUD
	var ready_now: bool = word != null and atril != null and atril.is_combo_ready()
	if ready_now != combo_ready:
		combo_ready = ready_now
		queue_redraw()


func hud_rect() -> Rect2:
	return Rect2(390, 305, 70, 40)


func _draw() -> void:
	UiStyle.draw_plate(self, PLATE)
	var held: bool = word != null and _fly < 0
	if held and combo_ready:
		_frame(Rect2(394, 311, 62, 20), Palette.INK)
		_frame(Rect2(395, 312, 60, 18), Palette.GOLD)
	var edge: Color = Palette.INK if held else Palette.INK_SOFT
	var fill: Color = Palette.GOLD_LIGHT if held else Palette.PARCHMENT_OLD
	if _consume_left > 0.0:
		edge = Palette.INK
		fill = Palette.CHALK
	_box(BOX, edge, fill)
	if held:
		_word(word.latin, TEXT_X)
	_tail(edge, fill)
	if word != null and _fly >= 0:
		var r := Rect2(FLY_X[_fly], BOX.position.y, BOX.size.x, BOX.size.y)
		if _fly == FLY_X.size() - 1:
			r = Rect2(r.position.x - 1, r.position.y + 2, r.size.x + 2, r.size.y - 2)  # squash, base presa
		_box(r, Palette.INK, Palette.GOLD_LIGHT)
		_word(word.latin, r.get_center().x)


func _box(r: Rect2, edge: Color, fill: Color) -> void:
	draw_rect(r, edge)
	draw_rect(r.grow(-1), fill)


func _frame(r: Rect2, c: Color) -> void:
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), c)
	draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), c)
	draw_rect(Rect2(r.position, Vector2(1, r.size.y)), c)
	draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), c)


func _word(latin: String, cx: float) -> void:
	PixelFont.draw_centered(self, latin, cx, TEXT_Y, Palette.INK)
	var tx: float = roundf(cx - PixelFont.width(latin) / 2.0)
	for i: int in latin.length():
		if rare_mask & (1 << i):
			draw_rect(Rect2(tx + GLYPH_STEP * i, RARE_Y, 5, 1), Palette.INK)


func _tail(edge: Color, fill: Color) -> void:
	for y: int in TAIL.size():
		for x: int in TAIL[y].length():
			var ch: String = TAIL[y][x]
			if ch == "#":
				draw_rect(Rect2(TAIL_POS + Vector2(x, y), Vector2.ONE), edge)
			elif ch == "o":
				draw_rect(Rect2(TAIL_POS + Vector2(x, y), Vector2.ONE), fill)
