extends CutsceneFx
## C1-04 — Asmodeus se desfaz em traços de tinta (64×64, origem no centro): cada faixa de 2 px do sprite
## vira um traço INK que sobe e encolhe; as de baixo vão primeiro; o olho BLOOD some por último.

const SPRITE := preload("res://assets/placeholders/bss_asmodeus_idle.png")
const SIZE := 64
const BAND := 2


func _draw() -> void:
	if progress >= 1.0:
		return
	var top := Vector2(-SIZE / 2.0, -SIZE / 2.0)
	for b: int in SIZE / BAND:
		# As faixas de baixo vão primeiro (b grande = embaixo).
		var threshold: float = (1.0 - float(b) / (SIZE / BAND - 1)) * 0.5 + 0.2 * hash01(b)
		var y: float = b * BAND
		if progress < threshold:
			draw_texture_rect_region(SPRITE, Rect2(top + Vector2(0, y), Vector2(SIZE, BAND)), Rect2(0, y, SIZE, BAND))
			continue
		var u: float = clampf((progress - threshold) / 0.3, 0.0, 1.0)
		if u >= 1.0:
			continue
		var w: float = roundf(SIZE * 0.6 * (1.0 - u))
		rect(-w / 2.0, top.y + y - roundf(24.0 * u), w, 1, Palette.INK)
