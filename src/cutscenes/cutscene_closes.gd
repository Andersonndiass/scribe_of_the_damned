class_name CutsceneCloses
extends RefCounted
## Closes 128×128 das cutscenes, desenhados ao vivo (placeholder, D-024; ficha T810 do design-agent)
## até a arte chegar. O crânio é o mesmo em todas as expressões; só olhos, sobrancelhas e boca mudam.
## Coordenadas locais do close, a partir de `o` (canto de cima à esquerda).

const SIZE := 128
const ASMODEUS_TEX := preload("res://assets/placeholders/bss_asmodeus_idle.png")


static func draw(ci: CanvasItem, o: Vector2, speaker: String, expr: String) -> void:
	match speaker:
		"anselmo":
			_anselmo(ci, o, expr)
		"abbot_ghost":
			_abbot_ghost(ci, o, expr)
		"asmodeus":
			ci.draw_rect(Rect2(o, Vector2(SIZE, SIZE)), Palette.INK_SOFT)
			ci.draw_texture_rect(ASMODEUS_TEX, Rect2(o, Vector2(SIZE, SIZE)), false)


static func _r(ci: CanvasItem, o: Vector2, x: float, y: float, w: float, h: float, c: Color) -> void:
	ci.draw_rect(Rect2(o + Vector2(x, y), Vector2(w, h)), c)


## Elipse cheia, linha a linha (sem antialiasing).
static func _ellipse(ci: CanvasItem, o: Vector2, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for dy: int in range(-int(ry), int(ry) + 1):
		var half: float = floorf(rx * sqrt(maxf(0.0, 1.0 - float(dy * dy) / (ry * ry))))
		_r(ci, o, cx - half, cy + dy, half * 2.0 + 1.0, 1.0, c)


## Trapézio de lados retos, linha a linha, de `y0` (largura x0a–x0b) a `y1` (x1a–x1b).
static func _trapezoid(ci: CanvasItem, o: Vector2, y0: float, x0a: float, x0b: float, y1: float, x1a: float, x1b: float, c: Color) -> void:
	for y: int in range(int(y0), int(y1) + 1):
		var t: float = (y - y0) / maxf(1.0, y1 - y0)
		var a: float = roundf(lerpf(x0a, x1a, t))
		var b: float = roundf(lerpf(x0b, x1b, t))
		_r(ci, o, a, y, b - a + 1.0, 1.0, c)


## Sobrancelha de 2 px com a ponta de dentro deslocada `tilt` px (negativo = sobe), em degraus.
static func _brow(ci: CanvasItem, o: Vector2, x: float, y: float, w: int, h: int, tilt: int, inner_right: bool) -> void:
	for i: int in w:
		var k: float = float(i) / maxf(1.0, w - 1)
		var from_inner: float = k if inner_right else 1.0 - k
		var dy: float = roundf(tilt * from_inner / 2.0) * 2.0
		_r(ci, o, x + i, y + dy, 1, h, Palette.INK)


static func _anselmo(ci: CanvasItem, o: Vector2, expr: String) -> void:
	_r(ci, o, 0, 0, SIZE, SIZE, Palette.PARCHMENT_OLD)
	# Hábito, capuz dobrado atrás do pescoço, pescoço.
	_trapezoid(ci, o, 100, 28, 100, 127, 20, 108, Palette.INK)
	_trapezoid(ci, o, 102, 30, 98, 127, 22, 106, Palette.INK_SOFT)
	_r(ci, o, 34, 92, 60, 12, Palette.INK_SOFT)
	_r(ci, o, 40, 98, 48, 2, Palette.INK)
	_r(ci, o, 56, 84, 16, 12, Palette.PARCHMENT)
	# Cabeça com contorno de 2 px, orelhas.
	_ellipse(ci, o, 64, 56, 24, 30, Palette.INK)
	_r(ci, o, 36, 50, 8, 16, Palette.INK)
	_r(ci, o, 84, 50, 8, 16, Palette.INK)
	_r(ci, o, 38, 52, 5, 12, Palette.PARCHMENT)
	_r(ci, o, 85, 52, 5, 12, Palette.PARCHMENT)
	_ellipse(ci, o, 64, 56, 22, 28, Palette.PARCHMENT)
	# Tonsura: anel de cabelo com franja em dentes e a coroa careca.
	for y: int in range(30, 45):
		var half: float = floorf(22.0 * sqrt(maxf(0.0, 1.0 - pow((y - 56) / 28.0, 2))))
		_r(ci, o, 64 - half, y, half * 2 + 1, 1, Palette.INK_SOFT)
	for x: int in range(44, 84, 6):
		_r(ci, o, x, 45, 2, 2, Palette.INK_SOFT)
	_ellipse(ci, o, 64, 32, 12, 5, Palette.PARCHMENT)
	# Nariz.
	_r(ci, o, 63, 60, 2, 6, Palette.INK)
	_r(ci, o, 61, 66, 4, 2, Palette.INK)
	match expr:
		"scared":
			for ex: int in [50, 70]:
				_r(ci, o, ex, 52, 8, 8, Palette.CHALK)
				_r(ci, o, ex + 3, 55, 2, 2, Palette.INK)
			_brow(ci, o, 50, 46, 8, 2, -3, true)
			_brow(ci, o, 70, 46, 8, 2, -3, false)
			_r(ci, o, 62, 71, 4, 1, Palette.INK)
			_r(ci, o, 61, 72, 1, 4, Palette.INK)
			_r(ci, o, 66, 72, 1, 4, Palette.INK)
			_r(ci, o, 62, 76, 4, 1, Palette.INK)
		"relieved":
			for ex: int in [50, 70]:
				_r(ci, o, ex, 55, 8, 3, Palette.CHALK)
				_r(ci, o, ex, 53, 8, 2, Palette.INK)
				_r(ci, o, ex + 3, 55, 2, 2, Palette.INK)
			_r(ci, o, 50, 48, 8, 2, Palette.INK)
			_r(ci, o, 70, 48, 8, 2, Palette.INK)
			_r(ci, o, 50, 49, 1, 1, Palette.INK)
			_r(ci, o, 77, 49, 1, 1, Palette.INK)
			_r(ci, o, 61, 75, 6, 2, Palette.INK)
			_r(ci, o, 59, 73, 2, 2, Palette.INK)
			_r(ci, o, 67, 73, 2, 2, Palette.INK)
		_:  # determined
			for ex: int in [50, 70]:
				_r(ci, o, ex, 54, 8, 5, Palette.CHALK)
				_r(ci, o, ex + 3, 55, 3, 3, Palette.INK)
			_brow(ci, o, 48, 46, 10, 3, 4, true)
			_brow(ci, o, 70, 46, 10, 3, 4, false)
			_r(ci, o, 59, 75, 10, 2, Palette.INK)
			_r(ci, o, 58, 76, 1, 1, Palette.INK)
			_r(ci, o, 69, 76, 1, 1, Palette.INK)


## O Abade vivo com o "filtro fantasma": tinta clara (xadrez CHALK sobre INK_SOFT), contorno CHALK.
static func _abbot_ghost(ci: CanvasItem, o: Vector2, expr: String) -> void:
	_r(ci, o, 0, 0, SIZE, SIZE, Palette.INK_SOFT)
	# Capa, capuz pontudo (contorno CHALK de 2 px e interior em xadrez 50%).
	_r(ci, o, 8, 90, 112, 38, Palette.CHALK)
	UiStyle.dither(ci, Rect2(o + Vector2(10, 92), Vector2(108, 36)), Palette.INK_SOFT, 0.5)
	_trapezoid(ci, o, 6, 62, 66, 98, 24, 104, Palette.CHALK)
	for y: int in range(10, 96):
		var t: float = (y - 6) / 92.0
		var a: float = roundf(lerpf(64, 26, t))
		var b: float = roundf(lerpf(64, 102, t))
		if b - a > 4:
			UiStyle.dither(ci, Rect2(o + Vector2(a + 2, y), Vector2(b - a - 4, 1)), Palette.INK_SOFT, 0.5)
	# Abertura do rosto: contorno CHALK, fundo INK_SOFT e o rosto em 75% CHALK só dentro da elipse.
	_ellipse(ci, o, 64, 58, 20, 26, Palette.CHALK)
	_ellipse(ci, o, 64, 58, 18, 24, Palette.INK_SOFT)
	for dy: int in range(-23, 24):
		var half: float = floorf(17.0 * sqrt(maxf(0.0, 1.0 - float(dy * dy) / (23.0 * 23.0))))
		if half > 0.0:
			UiStyle.dither(ci, Rect2(o + Vector2(64 - half, 58 + dy), Vector2(half * 2.0 + 1.0, 1)), Palette.CHALK, 0.75)
	var beard_lift: int = 1 if expr == "smiling" else 0
	for x: int in range(48, 81, 4):
		var len: float = 46.0 - absf(x - 64) * 1.3
		_r(ci, o, x, 72 - beard_lift, 1, len, Palette.CHALK)
	# Sobrancelhas grossas; olhos e boca vazios (INK_SOFT).
	_r(ci, o, 50, 50, 10, 3, Palette.CHALK)
	_r(ci, o, 68, 50, 10, 3, Palette.CHALK)
	if expr == "smiling":
		for ex: int in [52, 68]:
			_r(ci, o, ex, 58, 2, 2, Palette.INK_SOFT)
			_r(ci, o, ex + 2, 56, 4, 2, Palette.INK_SOFT)
			_r(ci, o, ex + 6, 58, 2, 2, Palette.INK_SOFT)
		_r(ci, o, 59, 74, 2, 2, Palette.INK_SOFT)
		_r(ci, o, 61, 76, 6, 2, Palette.INK_SOFT)
		_r(ci, o, 67, 74, 2, 2, Palette.INK_SOFT)
	else:
		_r(ci, o, 52, 57, 8, 2, Palette.INK_SOFT)
		_r(ci, o, 68, 57, 8, 2, Palette.INK_SOFT)
		_r(ci, o, 60, 74, 8, 2, Palette.INK_SOFT)
