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
## Pena (a mesma da mira): bico e haste INK; barbas PARCHMENT_OLD lisas (D-076); contorno CHALK.
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


## Painel padrão (D-076, 9-slice desenhado): borda de 1 px INK (2 no alto contraste) com o pixel do
## canto recortado, miolo `fill`, assento de 1 px INK_SOFT embaixo.
static func draw_panel(ci: CanvasItem, r: Rect2, fill: Color = Palette.PARCHMENT) -> void:
	var w: float = outline_w()
	var outer: Rect2 = r.grow(w)
	ci.draw_rect(Rect2(outer.position.x + 1, outer.position.y, outer.size.x - 2, outer.size.y), Palette.INK)
	ci.draw_rect(Rect2(outer.position.x, outer.position.y + 1, outer.size.x, outer.size.y - 2), Palette.INK)
	ci.draw_rect(r, fill)
	ci.draw_rect(Rect2(outer.position.x + 1, outer.end.y, outer.size.x - 2, 1), Palette.INK_SOFT)


## Etiqueta de destaque: texto INK sobre GOLD_LIGHT com borda INK (GOLD em texto não lê no pergaminho).
static func draw_tag(ci: CanvasItem, text: String, center_x: float, y: float) -> void:
	var w: float = PixelFont.width(text)
	var r := Rect2(roundf(center_x - w / 2.0 - 4), y - 3, w + 8, 12)
	ci.draw_rect(r.grow(1), Palette.INK)
	ci.draw_rect(r, Palette.GOLD_LIGHT)
	PixelFont.draw_centered(ci, text, center_x, y, Palette.INK)


## Disco cheio pixel a pixel (linhas pelo ponto médio: borda limpa, sem antialiasing).
static func disc(ci: CanvasItem, center: Vector2, r: int, c: Color) -> void:
	var cx: int = roundi(center.x)
	var cy: int = roundi(center.y)
	for dy: int in range(-r, r + 1):
		var half: int = floori(sqrt(float(r * r - dy * dy) + float(r) * 0.8))
		half = mini(half, r)
		ci.draw_rect(Rect2(cx - half, cy + dy, half * 2 + 1, 1), c)


## Anel de `t` px (a diferença de dois discos, sem buracos).
static func ring(ci: CanvasItem, center: Vector2, r: int, c: Color, t: int = 1) -> void:
	var cx: int = roundi(center.x)
	var cy: int = roundi(center.y)
	var inner: int = r - t
	for dy: int in range(-r, r + 1):
		var half: int = mini(floori(sqrt(float(r * r - dy * dy) + float(r) * 0.8)), r)
		var ih: int = -1
		if absi(dy) <= inner:
			ih = mini(floori(sqrt(float(inner * inner - dy * dy) + float(inner) * 0.8)), inner)
		if ih < 0:
			ci.draw_rect(Rect2(cx - half, cy + dy, half * 2 + 1, 1), c)
		else:
			ci.draw_rect(Rect2(cx - half, cy + dy, half - ih, 1), c)
			ci.draw_rect(Rect2(cx + ih + 1, cy + dy, half - ih, 1), c)


## Moldura de 1 px feita de retângulos cheios (a linha do draw_rect vazado cai no meio pixel).
static func frame(ci: CanvasItem, r: Rect2, c: Color, t: float = 1.0) -> void:
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, t)), c)
	ci.draw_rect(Rect2(r.position.x, r.end.y - t, r.size.x, t), c)
	ci.draw_rect(Rect2(r.position, Vector2(t, r.size.y)), c)
	ci.draw_rect(Rect2(r.end.x - t, r.position.y, t, r.size.y), c)


## Escurece a tela inteira (o único xadrez de UI permitido pela D-076, com o dos fantasmas).
static func dim_screen(ci: CanvasItem, level: float) -> void:
	dither(ci, Rect2(0, 0, 640, 360), Palette.INK, level)


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
		edge_w = 2.0
		if high():
			ci.draw_rect(whole.grow(edge_w + 1.0), Palette.CHALK)
	ci.draw_rect(whole.grow(edge_w), edge)
	ci.draw_rect(whole, fill)
	# Rabos de andorinha: recorte em V nas pontas.
	for notch_x: float in [whole.position.x - edge_w, whole.end.x - 3 + edge_w]:
		ci.draw_rect(Rect2(notch_x, pos.y + 5, 3, 6), Palette.INK)
	ci.draw_rect(Rect2(pos.x, pos.y, 1, RIBBON_H), Palette.PARCHMENT_OLD)
	ci.draw_rect(Rect2(body.end.x - 1, pos.y, 1, RIBBON_H), Palette.PARCHMENT_OLD)
	var color: Color = Palette.INK
	if disabled and not high():
		color = Palette.INK_SOFT
	PixelFont.draw_centered(ci, text, pos.x + w / 2.0, pos.y + 5, color)
	if disabled:
		var tw: float = PixelFont.width(text)
		ci.draw_rect(Rect2(pos.x + w / 2.0 - tw / 2.0, pos.y + 8, tw, 1), Palette.INK if high() else Palette.INK_SOFT)
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
		ci.draw_rect(Rect2(o + Vector2i(p.x * sx, p.y), Vector2.ONE), Palette.PARCHMENT_OLD)
	for p: Vector2i in pts:
		ci.draw_rect(Rect2(o + Vector2i(p.x * sx, p.y), Vector2.ONE), Palette.INK)


## Xadrez de `color` sobre `r` — o "desbotado" sem alpha: 25% (`level` < 0.4), 50% ou 75%
## (`level` > 0.6). Desenha uma textura 4×4 em mosaico (pixels só ligados ou desligados), feita uma
## vez por cor e nível.
static func dither(ci: CanvasItem, r: Rect2, color: Color, level: float = 0.5) -> void:
	var step: int = 1 if level < 0.4 else (3 if level > 0.6 else 2)
	ci.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ci.draw_texture_rect(_dither_tex(color, step), r, true)


## Quebra por palavra em linhas de até `width` caracteres (Grimório, cutscenes, balões).
static func wrap_words(text: String, width: int) -> PackedStringArray:
	var lines := PackedStringArray()
	var line: String = ""
	for word: String in text.split(" ", false):
		if line == "":
			line = word
		elif line.length() + 1 + word.length() <= width:
			line += " " + word
		else:
			lines.append(line)
			line = word
	if line != "":
		lines.append(line)
	return lines


## Nível do dither em quartos (1 = 25%, 2 = 50%, 3 = 75%) para quem desenha em degraus.
static func dither_quarters(progress: float) -> int:
	return clampi(floori(progress * 4.0), 0, 4)


static var _dither_cache: Dictionary = {}


static func _dither_tex(color: Color, quarters: int) -> ImageTexture:
	var key: String = "%s/%d" % [color.to_html(), quarters]
	if not _dither_cache.has(key):
		var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for y: int in 4:
			for x: int in 4:
				var on: bool
				match quarters:
					1:
						on = (x + 2 * y) % 4 == 0
					2:
						on = (x + y) % 2 == 0
					_:
						on = (x + y) % 2 == 0 or y % 2 == 0
				if on:
					img.set_pixel(x, y, color)
		_dither_cache[key] = ImageTexture.create_from_image(img)
	return _dither_cache[key]
