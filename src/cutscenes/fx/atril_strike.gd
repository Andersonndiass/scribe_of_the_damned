extends CutsceneFx
## C1-03 — A Rasura mostrada só na cena: um risco atravessa um atril de mentira (3 slots com letras,
## por cima do HUD) e apaga a última letra — a mesma marca da Rasura na partida, para ensinar.
## `progress` 0–0.6 risco; 0.6–0.7 diagonal BLOOD no último slot; 0.7–1 a letra apaga.
## Origem = canto de cima à esquerda do primeiro slot.

const SLOT := Vector2(12, 14)
const GAP := 2
const LETTERS := "LUX"


func _draw() -> void:
	if progress <= 0.0:
		return
	for i: int in LETTERS.length():
		var p := Vector2(i * (SLOT.x + GAP), 0)
		rect(p.x - 1, p.y - 1, SLOT.x + 2, SLOT.y + 2, Palette.INK)
		rect(p.x, p.y, SLOT.x, SLOT.y, Palette.PARCHMENT_OLD)
		var last: bool = i == LETTERS.length() - 1
		if not (last and progress >= 0.85):
			PixelFont.draw(self, LETTERS[i], p + Vector2(4, 4), Palette.INK_SOFT if (last and progress >= 0.7) else Palette.INK)
	var total: float = LETTERS.length() * (SLOT.x + GAP) + 24.0
	var u: float = clampf(progress / 0.6, 0.0, 1.0)
	var x: float = -12.0
	var k: int = 0
	while x < -12.0 + total * u:
		rect(x, 6 + (2 if k % 2 == 0 else -2), 6, 2, Palette.INK)
		x += 6.0
		k += 1
	if progress >= 0.6:
		var lp := Vector2((LETTERS.length() - 1) * (SLOT.x + GAP), 0)
		for s: int in int(SLOT.x) - 2:
			rect(lp.x + 1 + s, lp.y + SLOT.y - 2 - s, 2, 1, Palette.BLOOD)
