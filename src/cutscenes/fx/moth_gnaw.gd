extends CutsceneFx
## C1-04 — A traça roendo a borda da aba (teaser do Cap. 2): cabeça de perfil INK 12×8 com antenas
## curvas, mandíbulas e 2 olhos CHALK; `progress` faz as mordidas (até 5 entalhes 3×3 na borda) e a
## cabeça recua 1 px a cada mordida. Aparece quando `progress` > 0.

const HEAD: Array[String] = [
	"K....K......",
	".K..K.......",
	"..KK........",
	".KKKKKK.....",
	"KKCKKCKKK...",
	"KKKKKKKKKKK.",
	".KKKKKKKK.KK",
	"..KKKKKK..K.",
]


func animated() -> bool:
	return true


func _draw() -> void:
	if progress <= 0.0:
		return
	var bites: int = floori(progress * 5.0)
	for b: int in bites:
		rect(-6 - b * 4, -3, 3, 3, Palette.INK)
	var chew: int = 1 if int(t / 0.1) % 2 == 0 else 0
	var ox: float = -8.0 - bites * 4.0 + chew
	for y: int in HEAD.size():
		for x: int in HEAD[y].length():
			var ch: String = HEAD[y][x]
			if ch == ".":
				continue
			rect(ox + x, -8 + y, 1, 1, Palette.CHALK if ch == "C" else Palette.INK)
