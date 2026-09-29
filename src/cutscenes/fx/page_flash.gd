extends CutsceneFx
## C1-01 — Luz branca e a página que vira e engole a cena (palco 320×180, ×2). A virada termina em
## pergaminho liso — o mesmo primeiro quadro da C1-02 (corte invisível).
## `progress` 0–0.4 círculo CHALK crescendo da arca; 0.4–0.5 tela branca; 0.5–1 a página vira
## da direita para a esquerda e revela o pergaminho.

const W := 320
const H := 180
const ORIGIN := Vector2(160, 104)


func _draw() -> void:
	if progress <= 0.0:
		return
	if progress < 0.4:
		disc(ORIGIN, roundi(progress / 0.4 * 190.0), Palette.CHALK)
		return
	if progress < 0.5:
		rect(0, 0, W, H, Palette.CHALK)
		return
	var u: float = (progress - 0.5) / 0.5
	var fold: float = roundf(W * (1.0 - u))
	rect(0, 0, fold, H, Palette.CHALK)
	rect(fold, 0, W - fold, H, Palette.PARCHMENT)
	if u < 1.0:
		rect(fold - 12, 0, 12, H, Palette.PARCHMENT_OLD)
		rect(fold - 13, 0, 1, H, Palette.INK)
		rect(fold, 0, 2, H, Palette.INK_SOFT)
