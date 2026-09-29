extends CutsceneFx
## C1-03 — Asmodeus sobe de uma poça de tinta (64×64, origem no centro do sprite). Fica na posição do
## chefe de verdade (Boss.HOME), para a troca no fim da cena ser invisível. `progress` 0–0.3 a poça
## cresce; 0.3–1 o sprite sobe, recortado acima da linha da poça.

const SPRITE := preload("res://assets/placeholders/bss_asmodeus_idle.png")
const SIZE := 64


func _draw() -> void:
	var base_y: float = SIZE / 2.0
	var pool: float = clampf(progress / 0.3, 0.0, 1.0)
	if pool > 0.0 and progress < 1.0:
		var w: int = roundi(24.0 * pool)
		for dy: int in range(-4, 4):
			var half: int = roundi(w * sqrt(maxf(0.0, 1.0 - pow((dy + 0.5) / 4.0, 2))))
			rect(-half, base_y + dy, half * 2, 1, Palette.INK)
	var rise: float = clampf((progress - 0.3) / 0.7, 0.0, 1.0)
	if rise <= 0.0:
		return
	var shown: int = roundi(SIZE * rise)
	draw_texture_rect_region(SPRITE, Rect2(-SIZE / 2.0, base_y - shown, SIZE, shown), Rect2(0, 0, SIZE, shown))
