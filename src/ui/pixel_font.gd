class_name PixelFont
extends RefCounted
## Fonte pixel 5×6 (7px de linha) desenhada à mão, para HUD e telas (ficha 26: "fonte pixel 7px").
## O atlas é branco e serve só de máscara: a cor final vem da paleta via modulate.
## Acentos são normalizados (Á→A, Ç→C…) até a localização da feature 007.

const ATLAS := preload("res://assets/placeholders/ui_font_atlas.tres")
const CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZÆ0123456789:!?-./, "
const GLYPH := Vector2i(5, 6)
const ADVANCE := 6
const LINE_HEIGHT := 7

const _ACCENTS: Dictionary[String, String] = {
	"Á": "A", "À": "A", "Â": "A", "Ã": "A", "É": "E", "Ê": "E", "Í": "I",
	"Ó": "O", "Ô": "O", "Õ": "O", "Ú": "U", "Ç": "C",
}


static func normalize(text: String) -> String:
	var up: String = text.to_upper()
	var out: String = ""
	for ch: String in up:
		out += _ACCENTS.get(ch, ch)
	return out


## Largura em px do texto numa escala inteira.
static func width(text: String, scale: int = 1) -> int:
	var n: int = normalize(text).length()
	return 0 if n == 0 else (n * ADVANCE - 1) * scale


static func height(scale: int = 1) -> int:
	return GLYPH.y * scale


## Desenha `text` no CanvasItem com o canto superior esquerdo em `pos`.
static func draw(ci: CanvasItem, text: String, pos: Vector2, color: Color, scale: int = 1) -> void:
	var x: float = pos.x
	for ch: String in normalize(text):
		var idx: int = CHARS.find(ch)
		if idx < 0:
			idx = CHARS.find("?")
		if ch != " ":
			ci.draw_texture_rect_region(ATLAS,
				Rect2(x, pos.y, GLYPH.x * scale, GLYPH.y * scale),
				Rect2(idx * ADVANCE, 0, GLYPH.x, GLYPH.y), color)
		x += ADVANCE * scale


## Desenha centralizado horizontalmente em `center_x`.
static func draw_centered(ci: CanvasItem, text: String, center_x: float, y: float, color: Color, scale: int = 1) -> void:
	draw(ci, text, Vector2(roundf(center_x - width(text, scale) / 2.0), y), color, scale)
