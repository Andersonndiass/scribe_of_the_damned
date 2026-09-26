class_name HudInk
extends Node2D
## Tinta dourada no canto superior direito (005 T523). Fora da área central do HUD.

const TOP_RIGHT := Vector2(632, 8)
const ICON := preload("res://assets/placeholders/itm_gota_dourada.tres")

var shown: int = -1


func hud_rect() -> Rect2:
	return Rect2(TOP_RIGHT.x - 60, TOP_RIGHT.y, 60, 12)


func _process(_delta: float) -> void:
	if shown != GameState.gold_ink:
		shown = GameState.gold_ink
		queue_redraw()


func _draw() -> void:
	var text: String = str(maxi(shown, 0))
	var x: float = TOP_RIGHT.x - PixelFont.width(text)
	PixelFont.draw(self, text, Vector2(x, TOP_RIGHT.y + 2), Palette.GOLD)
	draw_texture(ICON, Vector2(x - 9, TOP_RIGHT.y))
