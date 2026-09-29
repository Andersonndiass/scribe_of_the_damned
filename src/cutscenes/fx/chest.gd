extends CutsceneFx
## C1-01 — Arca de ferro 48×28 (palco ×2) com o medalhão da pena sobre a cruz (narrativa §3.2).
## `progress`: 0 fechada; > 0 abre a fresta (CHALK) e a tampa sobe até 3 px; 1 aberta com luz.
## A origem do nó é o canto de cima à esquerda da arca.

func _draw() -> void:
	var lift: int = roundi(progress * 3.0)
	# Corpo.
	rect(-1, 7, 50, 22, Palette.INK)
	rect(0, 8, 48, 20, Palette.INK_SOFT)
	rect(0, 8, 12, 20, Palette.INK)
	rect(46, 8, 2, 20, Palette.PARCHMENT_OLD)
	for bx: int in [7, 40]:
		rect(bx, 8, 1, 20, Palette.PARCHMENT_OLD)
	# Fresta e luz de dentro.
	if progress > 0.0:
		rect(2, 7 - lift, 44, lift + 1, Palette.CHALK)
	# Tampa.
	rect(-1, -1 - lift, 50, 9, Palette.INK)
	rect(0, 0 - lift, 48, 7, Palette.INK_SOFT)
	rect(0, 0 - lift, 12, 7, Palette.INK)
	rect(46, 0 - lift, 2, 7, Palette.PARCHMENT_OLD)
	# Medalhão 9×9: pena CHALK sobre a cruz INK.
	var m := Vector2(19, 1 - lift)
	rect(m.x - 1, m.y - 1, 11, 11, Palette.INK)
	rect(m.x, m.y, 9, 9, Palette.PARCHMENT_OLD)
	rect(m.x + 4, m.y + 1, 1, 7, Palette.INK)
	rect(m.x + 2, m.y + 3, 5, 1, Palette.INK)
	for k: int in 6:
		rect(m.x + 1 + k, m.y + 7 - k, 1, 1, Palette.CHALK)
