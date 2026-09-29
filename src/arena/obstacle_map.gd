class_name ObstacleMap
extends RefCounted
## Consulta dos obstáculos da página (004 FR-410, FR-411; mechanics-agent). Retângulos com a máscara
## do que bloqueiam e uma grade de 16 px pré-calculada que marca as células perto de algum
## obstáculo: fora delas a consulta custa 1 byte (inimigos sem física, constituição).

const CELL := 16
const COLS := 40
const ROWS := 23
## Distância em que uma célula conta como "perto" (maior raio de inimigo campeão + folga).
const NEAR_PAD := 16.0
const PAGE := Rect2(0, 0, 640, 360)

var rects: Array[Rect2] = []
var masks: PackedInt32Array = PackedInt32Array()
var dash_stops: PackedByteArray = PackedByteArray()
## Célula → 1 se algum obstáculo está perto.
var near := PackedByteArray()


static func from_arena(arena: ArenaData, boss_layout: bool) -> ObstacleMap:
	var m := ObstacleMap.new()
	if arena != null:
		for o: ObstacleData in arena.active(boss_layout):
			m.rects.append(o.rect())
			m.masks.append(o.type.blocks)
			m.dash_stops.append(1 if o.type.stops_dash else 0)
	m._build_grid()
	return m


func _build_grid() -> void:
	near.resize(COLS * ROWS)
	near.fill(0)
	for r: Rect2 in rects:
		var g: Rect2 = r.grow(NEAR_PAD)
		for cy: int in range(maxi(0, int(g.position.y / CELL)), mini(ROWS, int(g.end.y / CELL) + 1)):
			for cx: int in range(maxi(0, int(g.position.x / CELL)), mini(COLS, int(g.end.x / CELL) + 1)):
				near[cy * COLS + cx] = 1


func is_near(p: Vector2) -> bool:
	var cx: int = int(p.x / CELL)
	var cy: int = int(p.y / CELL)
	if cx < 0 or cy < 0 or cx >= COLS or cy >= ROWS:
		return false
	return near[cy * COLS + cx] == 1


## O ponto está dentro de um obstáculo que bloqueia `mask`?
func blocks(p: Vector2, mask: int) -> bool:
	if not is_near(p):
		return false
	for i: int in rects.size():
		if masks[i] & mask and rects[i].has_point(p):
			return true
	return false


## Um círculo de raio `r` em `p` está livre dos obstáculos que bloqueiam `mask`?
func is_free(p: Vector2, r: float, mask: int = ObstacleTypeData.Block.WALK) -> bool:
	if not is_near(p):
		return true
	for i: int in rects.size():
		if masks[i] & mask and _circle_hits(p, r, rects[i]):
			return false
	return true


## Empurra o círculo para fora dos obstáculos pelo eixo de menor penetração (deslize natural).
func constrain(p: Vector2, r: float, mask: int = ObstacleTypeData.Block.WALK) -> Vector2:
	if not is_near(p):
		return p
	var q: Vector2 = p
	for i: int in rects.size():
		if not masks[i] & mask:
			continue
		var g: Rect2 = rects[i].grow(r)
		if not g.has_point(q):
			continue
		var left: float = q.x - g.position.x
		var right: float = g.end.x - q.x
		var up: float = q.y - g.position.y
		var down: float = g.end.y - q.y
		var m: float = minf(minf(left, right), minf(up, down))
		if m == left:
			q.x = g.position.x - 0.01
		elif m == right:
			q.x = g.end.x + 0.01
		elif m == up:
			q.y = g.position.y - 0.01
		else:
			q.y = g.end.y + 0.01
	return q


## O ponto livre mais próximo (para letras, tinta e nascimentos): empurra e, se ainda não servir,
## procura em anéis de 4 px dentro da área jogável.
func nearest_free(p: Vector2, r: float, bounds: Rect2 = ArenaData.PLAYABLE) -> Vector2:
	var inner: Rect2 = bounds.grow(-r)
	var q: Vector2 = constrain(p, r)
	q = q.clamp(inner.position, inner.end)
	if is_free(q, r):
		return q
	for ring: int in range(1, 32):
		for k: int in 16:
			var c: Vector2 = (p + Vector2.from_angle(TAU * k / 16.0) * ring * 4.0).clamp(inner.position, inner.end)
			if is_free(c, r):
				return c
	return p


## Até onde um segmento de `from` na direção `dir` anda antes de bater (para o dash e a telegrafia).
func clip_segment(from: Vector2, dir: Vector2, length: float, r: float, mask: int) -> float:
	var d: Vector2 = dir.normalized()
	var s: float = 0.0
	while s < length:
		if not is_free(from + d * s, r, mask):
			return maxf(0.0, s - 2.0)
		s += 2.0
	return length


## O dash para em `p`? (obstáculo com `stops_dash`).
func stops_dash_at(p: Vector2, r: float) -> bool:
	if not is_near(p):
		return false
	for i: int in rects.size():
		if dash_stops[i] == 1 and _circle_hits(p, r, rects[i]):
			return true
	return false


static func _circle_hits(p: Vector2, r: float, rect: Rect2) -> bool:
	var c := Vector2(clampf(p.x, rect.position.x, rect.end.x), clampf(p.y, rect.position.y, rect.end.y))
	return c.distance_squared_to(p) < r * r
