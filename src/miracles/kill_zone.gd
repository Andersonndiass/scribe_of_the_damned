class_name KillZone
extends RefCounted
## Zona letal de uma palavra de ataque (D-084; mechanics-agent): enquanto dura, todo inimigo comum
## dentro morre; o campeão leva um golpe forte uma vez por conjuração; o chefe nunca é tocado aqui.
## O milagre descreve a forma (e a move); o EnemyManager aplica 1× por tick de física.
## FSM: IDLE → ACTIVE → (DRAINING, só as de tela) → CLOSED; o milagre só termina em CLOSED.

## POINTS: vários círculos de raio `radius` que se movem juntos (as penas do ANGELUS).
enum Shape { LINE, CIRCLE, CROSS, SCREEN, POINTS }
enum Phase { IDLE, ACTIVE, DRAINING, CLOSED }

var shape: Shape = Shape.CIRCLE
var phase: Phase = Phase.IDLE
var origin: Vector2 = Vector2.ZERO
## LINE: direção (unitária). CROSS: ângulo dos braços.
var dir: Vector2 = Vector2.RIGHT
var angle: float = 0.0
## LINE: comprimento; CROSS: comprimento de cada braço a partir do centro.
var length: float = 0.0
var width: float = 0.0
## CIRCLE: raio; SCREEN: raio do anel que cresce (0 = a tela toda).
var radius: float = 0.0
## POINTS: centros dos círculos (o milagre atualiza a cada tick).
var points := PackedVector2Array()
var life_left: float = 0.0
## Zonas de tela: ao acabar o tempo, continuam até não achar mais ninguém dentro.
var drain: bool = false
var cast_id: int = 0
var tag: StringName = &""
## Golpe no campeão: fixo (PURGO) ou fração da vida × multiplicador (power × GLORIA × Tinta).
var champion_flat: int = 0
var champion_frac: float = 0.0
var champion_mul: float = 1.0
## Campeões (uid) que já levaram o golpe desta zona.
var champions_hit := PackedInt32Array()
## REQUIEM: quantas mortes ainda soltam letra garantida.
var drops_left: int = 0
var kills: int = 0


func open(p_shape: Shape, p_life: float, p_drain: bool = false) -> void:
	shape = p_shape
	life_left = p_life
	drain = p_drain
	champions_hit.clear()
	kills = 0
	drops_left = 0
	phase = Phase.ACTIVE


func close() -> void:
	phase = Phase.CLOSED


func is_live() -> bool:
	return phase == Phase.ACTIVE or phase == Phase.DRAINING


## Avança o tempo; `found_common` = a última passada achou algum comum dentro (drenagem).
func tick(dt: float, found_common: bool) -> void:
	if phase == Phase.ACTIVE:
		life_left -= dt
		if life_left <= 0.0:
			phase = Phase.DRAINING if drain else Phase.CLOSED
	elif phase == Phase.DRAINING and not found_common:
		phase = Phase.CLOSED


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


## Dano do golpe no campeão de vida máxima `max_hp` (nunca menos que 1).
func champion_damage(max_hp: int) -> int:
	if champion_flat > 0:
		return champion_flat
	return maxi(1, ceili(champion_frac * max_hp * champion_mul))
