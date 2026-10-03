class_name EatenEdgeView
extends Node2D
## A parte da página que a Mãe comeu (012 FR-1212): fora da `PlayArea` e dentro da área jogável,
## miolo INK_SOFT com borda roída INK (entalhes 3×2 a cada 8 px). Redesenha só quando a área muda.

const NOTCH_STEP := 8
const NOTCH := Vector2(3, 2)


func _ready() -> void:
	z_index = 1


func _draw() -> void:
	var page: Rect2 = Arena.PLAYABLE
	var r: Rect2 = PlayArea.rect
	if r == page:
		return
	var parts: Array[Rect2] = [
		Rect2(page.position.x, page.position.y, r.position.x - page.position.x, page.size.y),
		Rect2(r.end.x, page.position.y, page.end.x - r.end.x, page.size.y),
		Rect2(r.position.x, r.end.y, r.size.x, page.end.y - r.end.y),
	]
	for p: Rect2 in parts:
		if p.has_area():
			draw_rect(p, Palette.INK_SOFT)
	# Borda roída: linha INK com entalhes para dentro do buraco.
	if r.position.x > page.position.x:
		draw_rect(Rect2(r.position.x - 1, r.position.y, 1, r.size.y), Palette.INK)
		for y: int in range(int(r.position.y), int(r.end.y), NOTCH_STEP):
			draw_rect(Rect2(Vector2(r.position.x - 1 - NOTCH.x, y), NOTCH), Palette.INK)
	if r.end.x < page.end.x:
		draw_rect(Rect2(r.end.x, r.position.y, 1, r.size.y), Palette.INK)
		for y: int in range(int(r.position.y) + 4, int(r.end.y), NOTCH_STEP):
			draw_rect(Rect2(Vector2(r.end.x + 1, y), NOTCH), Palette.INK)
	if r.end.y < page.end.y:
		draw_rect(Rect2(r.position.x, r.end.y, r.size.x, 1), Palette.INK)
		for x: int in range(int(r.position.x), int(r.end.x), NOTCH_STEP):
			draw_rect(Rect2(Vector2(x, r.end.y + 1), Vector2(NOTCH.y, NOTCH.x)), Palette.INK)
