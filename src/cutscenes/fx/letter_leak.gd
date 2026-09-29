extends CutsceneFx
## C1-01 — Letras escapando pela fresta da arca e subindo em onda (palco ×2). As letras são glifos da
## fonte do jogo, em INK sobre um losango PARCHMENT (a mesma leitura das letras da partida).
## `progress`: cada letra nasce escalonada, sobe 84 px e some no topo.

const LETTERS := "LUXPAXCRUX"
const COUNT := 6


func _draw() -> void:
	for i: int in COUNT:
		var t0: float = float(i) / COUNT * 0.6
		var u: float = clampf((progress - t0) / 0.4, 0.0, 1.0)
		if u <= 0.0 or u >= 1.0:
			continue
		var x: float = 4.0 + i * 8.0 + roundf(4.0 * sin(u * TAU * 2.0))
		var y: float = -roundf(84.0 * u)
		rect(x - 1, y - 1, 9, 9, Palette.INK)
		rect(x, y, 7, 7, Palette.PARCHMENT)
		PixelFont.draw(self, LETTERS[i], Vector2(x + 1, y + 1), Palette.INK)
