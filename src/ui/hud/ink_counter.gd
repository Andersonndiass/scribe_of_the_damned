class_name HudInk
extends Node2D
## Tinta dourada no canto superior direito (005 T523). Fora da área central do HUD.
## T1800: painel C; cresce para a esquerda se o número passar do espaço.

## Miolo mínimo do painel; o número termina em x631 e a gota fica 3 px depois da borda esquerda.
const PLATE := Rect2(595, 7, 38, 12)
const TEXT_END_X := 631.0
const TEXT_Y := 10.0
const ICON_POS := Vector2(598, 9)
const ICON_GAP := 3.0
const ICON := preload("res://assets/placeholders/itm_gota_dourada.tres")

var shown: int = -1


func hud_rect() -> Rect2:
	return UiStyle.plate_area(PLATE)


func _process(_delta: float) -> void:
	if shown != GameState.gold_ink:
		shown = GameState.gold_ink
		queue_redraw()


func _draw() -> void:
	var text: String = str(maxi(shown, 0))
	var x: float = TEXT_END_X - PixelFont.width(text)
	# Número grande empurra o painel para a esquerda (a gota vai junto).
	var icon_x: float = minf(ICON_POS.x, x - ICON_GAP - ICON.get_width())
	var left: float = icon_x - ICON_GAP
	UiStyle.draw_plate(self, Rect2(left, PLATE.position.y, PLATE.end.x - left, PLATE.size.y))
	# Número em INK (GOLD em texto não lê no pergaminho); o ouro fica na gota com contorno.
	PixelFont.draw(self, text, Vector2(x, TEXT_Y), Palette.INK)
	draw_texture(ICON, Vector2(icon_x, ICON_POS.y))
