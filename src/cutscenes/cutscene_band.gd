class_name CutsceneBand
extends Node2D
## Faixa de diálogo, legenda e medidor de pular das cutscenes (008 FR-804, FR-805). Estados da fala:
## HIDDEN → TYPING (o texto aparece letra a letra) → COMPLETE → HIDDEN.

enum LineState { HIDDEN, TYPING, COMPLETE }

var cutscene: CutscenePlayer
var line: Dictionary = {}
var caption: Dictionary = {}
var line_state: LineState = LineState.HIDDEN
## Letras já visíveis da fala atual.
var shown: float = 0.0

var _text: String = ""


func has_line() -> bool:
	return line_state != LineState.HIDDEN


func typing() -> bool:
	return line_state == LineState.TYPING


func show_line(p: Dictionary) -> void:
	line = p
	_text = PixelFont.normalize(tr(str(p["key"])))
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
	line_state = LineState.HIDDEN
	queue_redraw()


func show_caption(p: Dictionary) -> void:
	caption = p
	queue_redraw()


func hide_caption() -> void:
	caption = {}
	queue_redraw()


func visible_text() -> String:
	return _text.left(int(shown))


func tick(dt: float, chars_per_second: float) -> void:
	if line_state == LineState.TYPING:
		shown += dt * chars_per_second
		if shown >= _text.length():
			complete()
	queue_redraw()


func _draw() -> void:
	# Desenho provisório até a ficha do design-agent (T810).
	if line_state != LineState.HIDDEN:
		draw_rect(Rect2(0, 292, 640, 68), Palette.INK)
		PixelFont.draw(self, visible_text(), Vector2(24, 312), Palette.CHALK)
	if not caption.is_empty():
		PixelFont.draw_centered(self, tr(str(caption["key"])), 320, 24, Palette.CHALK)
	if cutscene != null and cutscene.skip_progress > 0.0:
		var h: float = 20.0 * cutscene.skip_progress / cutscene.tuning.skip_hold
		draw_rect(Rect2(610, 20, 8, 20), Palette.INK_SOFT)
		draw_rect(Rect2(610, 40 - h, 8, h), Palette.GOLD)
