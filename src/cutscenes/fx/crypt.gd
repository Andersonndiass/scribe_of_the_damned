extends CutsceneFx
## C1-01 — Subsolo do mosteiro (palco 320×180, escala 2): parede de blocos, chão, a grade lá em cima com
## o "fogo que apaga" (sem BLOOD nem GOLD: é o vazio) e o facho de luz. `progress` = as paredes perdendo
## o desenho (células 4×4 viram papel liso, de cima para baixo).

const W := 320
const H := 180
const FLOOR_Y := 120
const GRATE := Rect2(144, 8, 32, 12)


func animated() -> bool:
	return true


func _draw() -> void:
	rect(0, 0, W, FLOOR_Y, Palette.INK)
	for row: int in FLOOR_Y / 8:
		var y: int = row * 8
		rect(0, y, W, 1, Palette.INK_SOFT)
		var off: int = 8 if row % 2 == 1 else 0
		for k: int in range(0, W / 16 + 1):
			rect(k * 16 + off, y, 1, 8, Palette.INK_SOFT)
	rect(0, FLOOR_Y, W, H - FLOOR_Y, Palette.INK_SOFT)
	rect(0, FLOOR_Y, W, 1, Palette.PARCHMENT_OLD)
	for k: int in range(0, W, 24):
		rect(k, FLOOR_Y + 8 + (k / 24 % 2) * 12, 16, 1, Palette.INK)
	# Paredes perdendo o desenho: a célula vira papel liso quando o progresso passa do limiar dela.
	if progress > 0.0:
		for cy: int in FLOOR_Y / 4:
			for cx: int in W / 4:
				var i: int = cy * 80 + cx
				var threshold: float = 0.7 * (cy * 4.0 / FLOOR_Y) + 0.3 * hash01(i)
				if progress >= threshold:
					rect(cx * 4, cy * 4, 4, 4, Palette.PARCHMENT)
	# Facho de luz da grade até o chão (transparência de luz em área grande).
	for y: int in range(20, FLOOR_Y):
		var half: float = lerpf(24.0, 48.0, float(y - 20) / (FLOOR_Y - 20))
		for x: int in range(int(160 - half), int(160 + half)):
			if (x + y) % 2 == 0:
				rect(x, y, 1, 1, Palette.PARCHMENT_OLD)
	# Grade com o fogo branco (línguas CHALK/PARCHMENT subindo em colunas).
	rect(GRATE.position.x - 1, GRATE.position.y - 1, GRATE.size.x + 2, GRATE.size.y + 2, Palette.INK_SOFT)
	rect(GRATE.position.x, GRATE.position.y, GRATE.size.x, GRATE.size.y, Palette.INK_SOFT)
	var frame: int = int(t / 0.1)
	for col: int in int(GRATE.size.x):
		var h: int = 2 + int(hash01(col + frame * 31) * 7.0)
		var c: Color = Palette.CHALK if col % 3 != 0 else Palette.PARCHMENT
		rect(GRATE.position.x + col, GRATE.end.y - h, 1, h, c)
	for bx: int in range(int(GRATE.position.x) + 4, int(GRATE.end.x), 4):
		rect(bx, GRATE.position.y, 1, GRATE.size.y, Palette.INK)
	rect(GRATE.position.x, GRATE.position.y + 5, GRATE.size.x, 1, Palette.INK)
