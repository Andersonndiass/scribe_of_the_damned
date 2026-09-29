extends CutsceneFx
## C1-04 — A página se purifica: um círculo de pergaminho limpo cresce a partir do chefe (origem do nó)
## até cobrir a tela inteira; no fim, as pautas da página voltam. Blocos lisos, sem xadrez.

func _draw() -> void:
	if progress <= 0.0:
		return
	var r: int = roundi(progress * 420.0)
	UiStyle.disc(self, Vector2.ZERO, r, Palette.PARCHMENT)
	if progress >= 1.0:
		for y: int in range(40, 290, 14):
			rect(24 - position.x, y - position.y, 592, 1, Palette.PARCHMENT_OLD)
