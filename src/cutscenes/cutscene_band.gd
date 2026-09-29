class_name CutsceneBand
extends Node2D
## Faixa de diálogo, legenda e placa de pular das cutscenes (008 FR-804, FR-805; ficha T810 do
## design-agent, tempos do animation-agent). Estados da fala: HIDDEN → TYPING (letra a letra) →
## COMPLETE → HIDDEN. Anselmo fala da esquerda; os outros, da direita; o narrador, sem close.

enum LineState { HIDDEN, TYPING, COMPLETE }

# Faixa e close.
const BAND := Rect2(0, 292, 640, 68)
## Close de 192 (D-074) em moldura de 196, saindo por cima da faixa.
const CLOSE_FRAME := 196
const CLOSE_LEFT := Vector2(6, 158)
const CLOSE_RIGHT := Vector2(438, 158)
const TEXT_LEFT := Rect2(212, 0, 412, 0)
const TEXT_RIGHT := Rect2(16, 0, 412, 0)
const NAME_Y := 298
## Linhas a 16 px (a ficha pedia 14; com o glifo de 12 px as linhas colavam).
const LINE_Y: Array[int] = [310, 326]
const NARRATOR_Y: Array[int] = [312, 328]
const TEXT_SCALE := 2
## Caracteres por linha na faixa (2 linhas no máximo; o roteiro é validado com estes números).
const LINE_CHARS := 34
const NARRATOR_CHARS := 48
const NARRATOR := "narrator"
const LEFT_SPEAKERS: PackedStringArray = ["anselmo"]
const CHEVRON_Y := 344
const CHEVRON_BOB := 0.4
# Legenda.
const CAPTION_ORIGIN := Vector2(16, 16)
const CAPTION_CHARS := 32
const CAPTION_LINE_STEP := 16
# Placa de pular.
const SKIP_RIGHT := 632
const SKIP_TOP := 8
const SKIP_H := 28
const INK_W := 12
const INK_H := 20
const INK_FILL_ROWS := 14
const SKIP_FLASH := 0.06

var cutscene: CutscenePlayer
var line: Dictionary = {}
var caption: Dictionary = {}
var line_state: LineState = LineState.HIDDEN
## Letras já visíveis da fala atual.
var shown: float = 0.0
## Enchimento visível do tinteiro (0–1): sobe com o Esc seguro; ao soltar, escorre (skip_drain).
var skip_fill: float = 0.0

var _text: String = ""
var _lines := PackedStringArray()
var _caption_lines := PackedStringArray()
var _age: float = 0.0
var _drain_rate: float = 0.0


static func chars_for(speaker: String) -> int:
	return NARRATOR_CHARS if speaker == NARRATOR else LINE_CHARS


func has_line() -> bool:
	return line_state != LineState.HIDDEN


func typing() -> bool:
	return line_state == LineState.TYPING


func show_line(p: Dictionary) -> void:
	line = p
	_text = PixelFont.normalize(tr(str(p["key"])))
	_lines = UiStyle.wrap_words(_text, chars_for(str(p.get("speaker", ""))))
	shown = 0.0
	line_state = LineState.TYPING
	queue_redraw()


func complete() -> void:
	if line_state == LineState.TYPING:
		shown = _text.length()
		line_state = LineState.COMPLETE
		queue_redraw()


func hide_line() -> void:
	line = {}
	_text = ""
	_lines.clear()
	line_state = LineState.HIDDEN
	queue_redraw()


func show_caption(p: Dictionary) -> void:
	caption = p
	_caption_lines = caption_lines(PixelFont.normalize(tr(str(p["key"]))))
	queue_redraw()


func hide_caption() -> void:
	caption = {}
	_caption_lines.clear()
	queue_redraw()


## Legenda em até 2 linhas de 32, quebrando de preferência depois de ". ".
static func caption_lines(text: String) -> PackedStringArray:
	var dot: int = text.find(". ")
	if dot > 0 and dot + 1 <= CAPTION_CHARS and text.length() - dot - 2 <= CAPTION_CHARS:
		return PackedStringArray([text.left(dot + 1), text.substr(dot + 2)])
	return UiStyle.wrap_words(text, CAPTION_CHARS)


func visible_text() -> String:
	return _text.left(int(shown))


func tick(dt: float, chars_per_second: float) -> void:
	_age += dt
	if line_state == LineState.TYPING:
		shown += dt * chars_per_second
		if shown >= _text.length():
			complete()
	queue_redraw()


## Placa de pular: aparece depois de `show_after` segurando; soltar escorre o visual em `drain` s.
func update_skip(dt: float, holding: bool, ratio: float, show_after: float, hold: float, drain: float) -> void:
	if holding:
		skip_fill = ratio if ratio * hold >= show_after else 0.0
		_drain_rate = 0.0
	elif skip_fill > 0.0:
		if _drain_rate == 0.0:
			_drain_rate = skip_fill / drain
		skip_fill = maxf(0.0, skip_fill - _drain_rate * dt)
	queue_redraw()


func _draw() -> void:
	if line_state != LineState.HIDDEN:
		_draw_band()
	if not _caption_lines.is_empty():
		_draw_caption()
	if skip_fill > 0.0:
		_draw_skip()


func _draw_band() -> void:
	var who: String = str(line.get("speaker", ""))
	draw_rect(BAND, Palette.INK)
	draw_rect(Rect2(0, BAND.position.y, 640, UiStyle.outline_w()), Palette.CHALK if UiStyle.high() else Palette.PARCHMENT_OLD)
	if not UiStyle.high():
		draw_rect(Rect2(0, BAND.position.y + 1, 640, 1), Palette.INK_SOFT)
	var typed: int = int(shown)
	if who == NARRATOR:
		var color: Color = Palette.CHALK if UiStyle.high() else Palette.PARCHMENT_OLD
		_draw_typed(_lines, typed, 320.0, NARRATOR_Y, color, true)
		if line_state == LineState.COMPLETE:
			_draw_chevron(Vector2(616, CHEVRON_Y))
		return
	var left: bool = LEFT_SPEAKERS.has(who)
	var frame_pos: Vector2 = CLOSE_LEFT if left else CLOSE_RIGHT
	draw_rect(Rect2(frame_pos, Vector2(CLOSE_FRAME, CLOSE_FRAME)), Palette.CHALK if UiStyle.high() else Palette.INK)
	draw_rect(Rect2(frame_pos + Vector2.ONE, Vector2(CLOSE_FRAME - 2, CLOSE_FRAME - 2)), Palette.PARCHMENT_OLD)
	CutsceneCloses.draw(self, frame_pos + Vector2(2, 2), who, str(line.get("expr", "")))
	var area: Rect2 = TEXT_LEFT if left else TEXT_RIGHT
	var name_key: String = _speaker_name_key(who)
	if name_key != "":
		var name_color: Color = Palette.CHALK if UiStyle.high() else Palette.GOLD_LIGHT
		PixelFont.draw(self, tr(name_key), Vector2(area.position.x, NAME_Y), name_color)
		if UiStyle.high():
			draw_rect(Rect2(area.position.x, NAME_Y + 7, PixelFont.width(tr(name_key)), 1), Palette.GOLD)
	_draw_typed(_lines, typed, area.position.x, LINE_Y, Palette.CHALK, false)
	if line_state == LineState.COMPLETE:
		_draw_chevron(Vector2(area.end.x - 7, CHEVRON_Y))


## Desenha as linhas mostrando só as primeiras `typed` letras (os espaços da quebra contam 1).
func _draw_typed(lines: PackedStringArray, typed: int, x: float, ys: Array[int], color: Color, centered: bool) -> void:
	var left: int = typed
	for i: int in mini(lines.size(), ys.size()):
		var part: String = lines[i].left(maxi(0, left))
		left -= lines[i].length() + 1
		if part == "":
			break
		if centered:
			# Centra pela linha inteira, para o texto não "andar" enquanto aparece.
			var full_w: float = PixelFont.width(lines[i], TEXT_SCALE)
			PixelFont.draw(self, part, Vector2(roundf(x - full_w / 2.0), ys[i]), color, TEXT_SCALE)
		else:
			PixelFont.draw(self, part, Vector2(x, ys[i]), color, TEXT_SCALE)


## "Pode adiantar": chevron 7×4 que balança 1 px.
func _draw_chevron(pos: Vector2) -> void:
	var bob: float = 1.0 if int(_age / CHEVRON_BOB) % 2 == 0 else 0.0
	var c: Color = Palette.CHALK if UiStyle.high() else Palette.GOLD_LIGHT
	for row: int in 4:
		draw_rect(Rect2(pos.x + row, pos.y + row + bob, 7 - row * 2, 1), c)


func _draw_caption() -> void:
	var w: float = 0.0
	for l: String in _caption_lines:
		w = maxf(w, PixelFont.width(l, TEXT_SCALE))
	var plate := Rect2(CAPTION_ORIGIN, Vector2(w + 24, _caption_lines.size() * CAPTION_LINE_STEP - 2 + 12))
	draw_rect(plate.grow(UiStyle.outline_w()), Palette.INK)
	draw_rect(plate, Palette.PARCHMENT)
	for side: float in [plate.position.x, plate.end.x - 4]:
		draw_rect(Rect2(side, plate.position.y, 4, plate.size.y), Palette.PARCHMENT_OLD)
		draw_rect(Rect2(side + 2, plate.position.y, 1, plate.size.y), Palette.INK)
	for i: int in _caption_lines.size():
		PixelFont.draw(self, _caption_lines[i], plate.position + Vector2(12, 6 + i * CAPTION_LINE_STEP), Palette.INK, TEXT_SCALE)


## Placa de pular com o tinteiro de vidro: a tinta sobe de baixo para cima.
func _draw_skip() -> void:
	var text: String = tr(&"CS_SKIP_HOLD").format({"pause": Settings.key_label(&"pause")})
	var w: float = 6 + INK_W + 6 + PixelFont.width(text) + 6
	var plate := Rect2(SKIP_RIGHT - w, SKIP_TOP, w, SKIP_H)
	draw_rect(plate.grow(UiStyle.outline_w()), Palette.INK)
	draw_rect(plate, Palette.PARCHMENT)
	PixelFont.draw(self, text, Vector2(plate.position.x + 6 + INK_W + 6, 19), Palette.INK)
	var ink := Vector2(plate.position.x + 6, 12)
	# Gargalo 6×4 e corpo 12×16 com contorno INK.
	draw_rect(Rect2(ink + Vector2(3, 0), Vector2(6, 4)), Palette.INK)
	draw_rect(Rect2(ink + Vector2(0, 4), Vector2(INK_W, 16)), Palette.INK)
	var inside := Rect2(ink + Vector2(1, 5), Vector2(10, INK_FILL_ROWS))
	draw_rect(inside, Palette.PARCHMENT)
	if not UiStyle.high():
		UiStyle.dither(self, inside, Palette.PARCHMENT_OLD)
	var full: bool = skip_fill >= 1.0
	var rows: int = floori(skip_fill * INK_FILL_ROWS)
	if full:
		draw_rect(inside, Palette.CHALK)
	elif rows > 0:
		draw_rect(Rect2(inside.position.x, inside.end.y - rows, inside.size.x, rows), Palette.INK)
		draw_rect(Rect2(inside.position.x, inside.end.y - rows, inside.size.x, 1), Palette.CHALK if UiStyle.high() else Palette.GOLD_LIGHT)


func _speaker_name_key(who: String) -> String:
	if cutscene == null or cutscene.build == null:
		return ""
	return str((cutscene.build.source.speakers.get(who, {}) as Dictionary).get("name_key", ""))
