extends CutsceneFx
## C1-04 — Raios de redenção (GOLD_LIGHT com borda GOLD, art bible §2) saindo do lugar do chefe (origem
## do nó) em 8 direções (k·45° + 22,5°); `progress` estende o comprimento; pulsa em 2 quadros.

func animated() -> bool:
	return true


func _draw() -> void:
	if progress <= 0.0:
		return
	var length: float = progress * 420.0
	var wide: bool = int(t / 0.4) % 2 == 0
	for k: int in 8:
		var dir: Vector2 = Vector2.from_angle(deg_to_rad(k * 45.0 + 22.5))
		var normal: Vector2 = dir.orthogonal()
		var steps: int = int(length / 2.0)
		for s: int in range(4, steps):
			var p: Vector2 = (dir * s * 2.0).round()
			for w: int in range(-2, 3):
				var q: Vector2 = (p + normal * w).round()
				var c: Color = Palette.GOLD_LIGHT if absi(w) <= (1 if wide else 0) else Palette.GOLD
				rect(q.x, q.y, 2, 2, c)
