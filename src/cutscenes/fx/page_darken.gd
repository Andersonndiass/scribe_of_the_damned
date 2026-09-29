extends CutsceneFx
## C1-03 — A página escurece por cima do jogo parado (0,0–640,300; o atril embaixo continua à vista).
## Degraus: 25% INK_SOFT, 50% INK_SOFT, 50% INK (escurecimento de área grande, permitido pela D-076).

func _draw() -> void:
	if progress <= 0.0:
		return
	var r := Rect2(0, 0, 640, 300)
	if progress < 0.34:
		UiStyle.dither(self, r, Palette.INK_SOFT, 0.25)
	elif progress < 0.67:
		UiStyle.dither(self, r, Palette.INK_SOFT, 0.5)
	else:
		UiStyle.dither(self, r, Palette.INK, 0.5)
