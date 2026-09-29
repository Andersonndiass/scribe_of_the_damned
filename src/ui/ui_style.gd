class_name UiStyle
extends RefCounted
## Desenho comum das telas (007; design-agent): fita, pena-cursor, dithering e as regras do alto
## contraste (GameState.high_contrast) — nenhuma cor nova, só troca entre os 9 tokens.

const RIBBON_H := 16
const RIBBON_TAIL := 6
const RIBBON_MIN_W := 128
const RIBBON_PAD := 24
const RIBBON_FOCUS_SHIFT := 4
const QUILL_GAP := 4
## Pena (a mesma da mira): bico e haste INK; barbas INK_SOFT/PARCHMENT_OLD em xadrez; contorno CHALK.
const QUILL_NIB: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, -1), Vector2i(2, -2)]
const QUILL_SHAFT_FROM := 3
const QUILL_SHAFT_TO := 10


static func high() -> bool:
	return GameState.high_contrast


## Texto sobre fundo escuro / claro (no alto contraste, nunca INK_SOFT nem PARCHMENT_OLD).
static func text_on_dark(soft: bool = false) -> Color:
	return Palette.CHALK if high() or not soft else Palette.PARCHMENT_OLD


static func text_on_light(soft: bool = false) -> Color:
	return Palette.INK if high() or not soft else Palette.INK_SOFT


static func outline_w() -> float:
	return 2.0 if high() else 1.0


## Escurecimento do jogo por trás de pausa/Game Over (fração de pixels cobertos).
static func dim_level() -> float:
	return 0.75 if high() else 0.5


## Largura de uma fita para `text` (escala 1); `min_w` encolhe a fita onde o espaço é curto.
static func ribbon_width(text: String, min_w: float = RIBBON_MIN_W) -> float:
	return maxf(min_w, PixelFont.width(text) + RIBBON_PAD)


## Fita (item de menu). `state`: &"idle", &"focus", &"disabled". `center` = centro da fita.
## Contorno em toda a forma (corpo e rabos): INK_SOFT em repouso, GOLD no foco (+CHALK no alto
## contraste); a pena-cursor aponta para a fita pela esquerda.
static func draw_ribbon(ci: CanvasItem, center: Vector2, text: String, state: StringName, min_w: float = RIBBON_MIN_W) -> void:
	var w: float = ribbon_width(text, min_w)
	var pos := Vector2(roundf(center.x - w / 2.0), roundf(center.y - RIBBON_H / 2.0))
	var focused: bool = state == &"focus"
	var disabled: bool = state == &"disabled"
	if focused:
		pos.x += RIBBON_FOCUS_SHIFT
	var body := Rect2(pos, Vector2(w, RIBBON_H))
	var whole := Rect2(pos.x - RIBBON_TAIL, pos.y, w + RIBBON_TAIL * 2, RIBBON_H)
	var fill: Color = Palette.PARCHMENT_OLD if disabled else Palette.PARCHMENT
	var edge: Color = Palette.GOLD if focused else Palette.INK_SOFT
	var edge_w: float = outline_w()
	if focused:
		edge_w += 1.0
		if high():
			ci.draw_rect(whole.grow(edge_w + 1.0), Palette.CHALK)
	ci.draw_rect(whole.grow(edge_w), edge)
	ci.draw_rect(whole, fill)
	# Rabos de andorinha: recorte em V nas pontas.
	for notch_x: float in [whole.position.x - edge_w, whole.end.x - 3 + edge_w]:
		ci.draw_rect(Rect2(notch_x, pos.y + 5, 3, 6), Palette.INK)
	if disabled and not high():
		dither(ci, Rect2(whole.position.x, pos.y, RIBBON_TAIL, RIBBON_H), Palette.INK_SOFT)
		dither(ci, Rect2(body.end.x, pos.y, RIBBON_TAIL, RIBBON_H), Palette.INK_SOFT)
	ci.draw_rect(Rect2(pos.x, pos.y, 1, RIBBON_H), Palette.PARCHMENT_OLD)
	ci.draw_rect(Rect2(body.end.x - 1, pos.y, 1, RIBBON_H), Palette.PARCHMENT_OLD)
	var color: Color = Palette.INK
	if disabled and not high():
		color = Palette.INK_SOFT
	PixelFont.draw_centered(ci, text, pos.x + w / 2.0, pos.y + 5, color)
	if disabled and high():
		var tw: float = PixelFont.width(text)
		ci.draw_rect(Rect2(pos.x + w / 2.0 - tw / 2.0, pos.y + 8, tw, 1), Palette.INK)
	if focused:
		var bob: float = -1.0 if int(Time.get_ticks_msec() / 400) % 2 == 0 else 0.0
		draw_quill(ci, Vector2(whole.position.x - edge_w - QUILL_GAP, pos.y + RIBBON_H / 2.0 + bob), true)


## Pena-cursor com a ponta em `tip` (a mesma da mira do mouse). `mirrored` = ponta à direita
## (o cursor dos menus aponta para a fita).
static func draw_quill(ci: CanvasItem, tip: Vector2, mirrored: bool = false) -> void:
	var o := Vector2i(tip.round())
	var sx: int = -1 if mirrored else 1
	var pts: Array[Vector2i] = []
	pts.append_array(QUILL_NIB)
	for i: int in range(QUILL_SHAFT_FROM, QUILL_SHAFT_TO + 1):
		pts.append(Vector2i(i, -i))
	var barbs: Array[Vector2i] = []
	for i: int in range(QUILL_SHAFT_FROM, QUILL_SHAFT_TO - 1):
		for w: int in [1, 2]:
			barbs.append(Vector2i(i, -i - w - 1))
	var filled := {}
	for p: Vector2i in pts + barbs:
		filled[p] = true
	for p: Vector2i in filled:
		for dy: int in [-1, 0, 1]:
			for dx: int in [-1, 0, 1]:
				var q := Vector2i(p.x + dx, p.y + dy)
				if not filled.has(q):
					ci.draw_rect(Rect2(o + Vector2i(q.x * sx, q.y), Vector2.ONE), Palette.CHALK)
	for p: Vector2i in barbs:
		ci.draw_rect(Rect2(o + Vector2i(p.x * sx, p.y), Vector2.ONE), Palette.INK_SOFT if (p.x + p.y) % 2 == 0 else Palette.PARCHMENT_OLD)
	for p: Vector2i in pts:
		ci.draw_rect(Rect2(o + Vector2i(p.x * sx, p.y), Vector2.ONE), Palette.INK)


## Xadrez 50% (ou 75% com `level` > 0.6) de `color` sobre `r` — o "desbotado" sem alpha. Desenha uma
## textura 2×2 em mosaico (pixels só ligados ou desligados), feita uma vez por cor e nível.
static func dither(ci: CanvasItem, r: Rect2, color: Color, level: float = 0.5) -> void:
	ci.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ci.draw_texture_rect(_dither_tex(color, level > 0.6), r, true)


static var _dither_cache: Dictionary = {}


static func _dither_tex(color: Color, dense: bool) -> ImageTexture:
	var key: String = "%s/%s" % [color.to_html(), dense]
	if not _dither_cache.has(key):
		var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		img.set_pixel(0, 0, color)
		img.set_pixel(1, 1, color)
		if dense:
			img.set_pixel(1, 0, color)
		_dither_cache[key] = ImageTexture.create_from_image(img)
	return _dither_cache[key]
