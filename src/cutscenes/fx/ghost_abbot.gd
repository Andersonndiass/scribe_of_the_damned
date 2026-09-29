extends CutsceneFx
## C1-02 e C1-04 — O fantasma do Abade, 20×32 (pivô na base, (10, 31)), flutuando. Silhueta própria:
## capuz pontudo, rosto, barba, capa com a cauda em fios. Tinta clara: capa em xadrez INK_SOFT (a
## transparência dos fantasmas, art bible §3), rosto e barba lisos, contorno INK_SOFT, brilho CHALK.
## `progress`: forma-se em degraus (25%, 50%, inteiro) e some ao voltar a 0.
## # = capa (xadrez) · K = contorno INK_SOFT · P = rosto · C = barba/brilho · E = olho INK_SOFT.

const MAP: Array[String] = [
	".........KK.........",
	"........KCCK........",
	".......K####K.......",
	"......K######K......",
	".....K########K.....",
	".....K##PPPP##K.....",
	"....K##PPPPPP##K....",
	"....K##PEPPEP##K....",
	"....K##PPPPPP##K....",
	"....K##PPPPPP##K....",
	"...K###CCCCCC###K...",
	"...K###CCCCCC###K...",
	"...K####CCCC####K...",
	"..K#####CCCC#####K..",
	"..K######CC######K..",
	"..K######CC######K..",
	".K################K.",
	".K################K.",
	".K################K.",
	".K################K.",
	"K##################K",
	"K##################K",
	"K##################K",
	"K##################K",
	"K##################K",
	"K##################K",
	".K################K.",
	"..K.K.K..K..K.K.K...",
	"...K...K....K..K....",
	"....K........K......",
	"....................",
	"....................",
]


func animated() -> bool:
	return true


func _draw() -> void:
	if progress <= 0.0:
		return
	var quarters: int = 1 if progress < 0.34 else (2 if progress < 0.67 else 4)
	var bob: float = -roundf(3.0 + 3.0 * sin(t * TAU / 2.4))
	for y: int in MAP.size():
		for x: int in MAP[y].length():
			var ch: String = MAP[y][x]
			if ch == ".":
				continue
			if quarters < 4 and not CloseRaster.on_pattern(x, y, quarters):
				continue
			var c: Color = Palette.INK_SOFT
			match ch:
				"#":
					if (x + y) % 2 == 1:
						continue
				"P":
					c = Palette.PARCHMENT
				"C":
					c = Palette.CHALK
			rect(x - 10, y - 31 + bob, 1, 1, c)
