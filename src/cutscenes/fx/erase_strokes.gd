extends CutsceneFx
## C1-03 — Riscos de rasura cruzando a página: 5 traços INK de 2 px em zigue-zague (segmentos de 6 px
## alternando ±2 px), cada um desenhado até onde o `progress` chegou, escalonados.

const PATHS: Array = [
	[Vector2(40, 80), Vector2(600, 140)],
	[Vector2(620, 60), Vector2(20, 220)],
	[Vector2(60, 260), Vector2(580, 200)],
	[Vector2(300, 20), Vector2(340, 280)],
	[Vector2(100, 40), Vector2(540, 270)],
]


func _draw() -> void:
	for i: int in PATHS.size():
		var u: float = clampf((progress - 0.15 * i) / 0.25, 0.0, 1.0)
		if u <= 0.0:
			continue
		var a: Vector2 = PATHS[i][0]
		var b: Vector2 = a.lerp(PATHS[i][1], u)
		var steps: int = maxi(1, int(a.distance_to(b) / 6.0))
		var normal: Vector2 = (PATHS[i][1] - a).orthogonal().normalized()
		var prev: Vector2 = a
		for s: int in range(1, steps + 1):
			var p: Vector2 = a.lerp(b, float(s) / steps) + normal * (2.0 if s % 2 == 0 else -2.0)
			_segment(prev, p)
			prev = p


func _segment(a: Vector2, b: Vector2) -> void:
	var n: int = maxi(1, int(maxf(absf(b.x - a.x), absf(b.y - a.y))))
	for k: int in n + 1:
		var p: Vector2 = a.lerp(b, float(k) / n).round()
		rect(p.x, p.y, 2, 2, Palette.INK)
