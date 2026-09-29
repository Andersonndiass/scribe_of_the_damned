extends CutsceneFx
## C1-02 — A página em branco do Cap. 1 (640×360): pergaminho com a margem de 24 px e pautas leves
## a cada 14 px. É o fundo onde Anselmo cai e o fantasma do Abade aparece.

func _draw() -> void:
	rect(0, 0, 640, 360, Palette.PARCHMENT)
	for y: int in range(40, 290, 14):
		rect(24, y, 592, 1, Palette.PARCHMENT_OLD)
	rect(24, 24, 592, 1, Palette.PARCHMENT_OLD)
	rect(24, 335, 592, 1, Palette.PARCHMENT_OLD)
	rect(24, 24, 1, 312, Palette.PARCHMENT_OLD)
	rect(615, 24, 1, 312, Palette.PARCHMENT_OLD)
