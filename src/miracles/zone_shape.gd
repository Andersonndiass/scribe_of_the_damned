class_name ZoneShape
extends RefCounted
## Geometria comum das zonas (017 T1710; mechanics-agent T1700): a zona letal das palavras
## (KillZone) e as zonas de arma (WeaponZone) testam "um círculo toca a forma?" do mesmo jeito.

## POINTS: vários círculos de raio `radius` que se movem juntos (as penas do ANGELUS).
enum Shape { LINE, CIRCLE, CROSS, SCREEN, POINTS }

var shape: Shape = Shape.CIRCLE
var origin: Vector2 = Vector2.ZERO
## LINE: direção (unitária). CROSS: ângulo dos braços.
var dir: Vector2 = Vector2.RIGHT
var angle: float = 0.0
## LINE: comprimento; CROSS: comprimento de cada braço a partir do centro.
var length: float = 0.0
var width: float = 0.0
## CIRCLE: raio; SCREEN: raio do anel que cresce (0 = a tela toda).
var radius: float = 0.0
## POINTS: centros dos círculos (quem é dono da zona atualiza a cada tick).
var points := PackedVector2Array()


## Um círculo de centro `p` e raio `r` toca a zona?
func contains(p: Vector2, r: float) -> bool:
	var rel: Vector2 = p - origin
	match shape:
		Shape.LINE:
			var along: float = rel.dot(dir)
			return along >= -r and along <= length + r and absf(rel.cross(dir)) <= width / 2.0 + r
		Shape.CIRCLE:
			return rel.length() <= radius + r
		Shape.POINTS:
			for c: Vector2 in points:
				if c.distance_to(p) <= radius + r:
					return true
			return false
		Shape.CROSS:
			var q: Vector2 = rel.rotated(-angle)
			var half: float = width / 2.0 + r
			return (absf(q.x) <= length + r and absf(q.y) <= half) or (absf(q.y) <= length + r and absf(q.x) <= half)
		_:
			return radius <= 0.0 or rel.length() <= radius + r


## LINE: distância ao longo da linha (para ordenar do mais perto ao mais longe).
func along(p: Vector2) -> float:
	return (p - origin).dot(dir)


## Retângulo que cobre a zona (para a consulta na grade), já com a folga `pad`.
func bounds(pad: float) -> Rect2:
	match shape:
		Shape.LINE:
			var end: Vector2 = origin + dir * length
			return Rect2(origin, Vector2.ZERO).expand(end).grow(width / 2.0 + pad)
		Shape.CIRCLE:
			return Rect2(origin - Vector2(radius, radius), Vector2(radius, radius) * 2.0).grow(pad)
		Shape.POINTS:
			if points.is_empty():
				return Rect2()
			var box := Rect2(points[0], Vector2.ZERO)
			for c: Vector2 in points:
				box = box.expand(c)
			return box.grow(radius + pad)
		Shape.CROSS:
			var reach: float = (length + width) * 1.5
			return Rect2(origin - Vector2(reach, reach), Vector2(reach, reach) * 2.0).grow(pad)
		_:
			return Rect2(Vector2(-10000, -10000), Vector2(20000, 20000))
