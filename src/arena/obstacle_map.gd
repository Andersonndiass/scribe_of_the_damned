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
## Distância à frente em que o inimigo "vê" a face da peça para deslizar.
const SLIDE_LOOKAHEAD := 3.0
## Abaixo desta fração da velocidade ao longo da face, o inimigo escolhe uma ponta para contornar.
const SLIDE_MIN_TANGENT := 0.3

var rects: Array[Rect2] = []
var masks: PackedInt32Array = PackedInt32Array()
var dash_stops: PackedByteArray = PackedByteArray()
## Célula → 1 se algum obstáculo está perto.
var near := PackedByteArray()
## Margens do ArenaData (rules-agent): queda de letra/tinta e nascimento de inimigo.
var drop_margin: float = 0.0
var drop_clearance: float = 0.0
var spawn_clearance: float = 0.0


static func from_arena(arena: ArenaData, boss_layout: bool, bounds: Rect2 = ArenaData.PLAYABLE) -> ObstacleMap:
	var m := ObstacleMap.new()
	if arena != null:
		m.drop_margin = arena.drop_margin
		m.drop_clearance = arena.drop_clearance
		m.spawn_clearance = arena.spawn_clearance
		for o: ObstacleData in arena.active(boss_layout, bounds):
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
		# Lados que dão para fora da página (peça encostada na parede) não contam: sairia na margem.
		var inner: Rect2 = PlayArea.rect.grow(-r)
		var left: float = q.x - g.position.x if g.position.x >= inner.position.x else INF
		var right: float = g.end.x - q.x if g.end.x <= inner.end.x else INF
		var up: float = q.y - g.position.y if g.position.y >= inner.position.y else INF
		var down: float = g.end.y - q.y if g.end.y <= inner.end.y else INF
		var m: float = minf(minf(left, right), minf(up, down))
		if m == INF:
			continue
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
func nearest_free(p: Vector2, r: float, bounds: Rect2 = Rect2()) -> Vector2:
	var inner: Rect2 = (bounds if bounds.has_area() else PlayArea.rect).grow(-r)
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


## Velocidade que contorna o obstáculo à frente: tira a parte que entra na face e, se quase não
## sobra nada (alvo bem atrás da peça), segue pela face até a ponta mais perto que dá para a área livre.
func slide(p: Vector2, v: Vector2, r: float, mask: int = ObstacleTypeData.Block.WALK) -> Vector2:
	var speed: float = v.length()
	if speed < 0.001 or not is_near(p):
		return v
	var probe: Vector2 = p + v / speed * SLIDE_LOOKAHEAD
	for i: int in rects.size():
		if not masks[i] & mask:
			continue
		var g: Rect2 = rects[i].grow(r)
		if not g.has_point(probe):
			continue
		var n: Vector2 = _face_normal(p, g)
		var into: float = v.dot(n)
		if into >= 0.0:
			continue
		var t := Vector2(-n.y, n.x)
		var along: float = v.dot(t)
		if absf(along) >= speed * SLIDE_MIN_TANGENT:
			var s: float = signf(along)
			# Ponta que encosta na parede é beco: a multidão prensava o inimigo ali (sonda T413).
			if _dead_end(p, g, t * s, r):
				s = -s
			return t * s * speed
		return t * _corner_side(p, g, t, r) * speed
	return v


## Seguir a face na direção `dir` termina na margem da página (peça encostada na parede)?
func _dead_end(p: Vector2, g: Rect2, dir: Vector2, r: float) -> bool:
	var inner: Rect2 = PlayArea.rect.grow(-r)
	return not inner.has_point(_face_end(p, g, dir) + dir)


## Ponta da face de `g` alcançada andando de `p` na direção `dir` (eixo x ou y).
static func _face_end(p: Vector2, g: Rect2, dir: Vector2) -> Vector2:
	if absf(dir.x) > 0.5:
		return Vector2(g.end.x if dir.x > 0.0 else g.position.x, p.y)
	return Vector2(p.x, g.end.y if dir.y > 0.0 else g.position.y)


## Lado (+1/−1 em `t`) da ponta da face mais perto de `p`; a outra se essa encosta na parede.
func _corner_side(p: Vector2, g: Rect2, t: Vector2, r: float) -> float:
	var inner: Rect2 = PlayArea.rect.grow(-r)
	var lo: Vector2 = g.position if t.x + t.y > 0.0 else g.end
	var hi: Vector2 = g.end if t.x + t.y > 0.0 else g.position
	# Pontas ao longo de t: `lo` fica atrás (−t), `hi` à frente (+t).
	var a: float = (p - lo).dot(t)
	var b: float = (hi - p).dot(t)
	var s: float = 1.0 if b <= a else -1.0
	var end_pt: Vector2 = p + t * s * ((b if s > 0.0 else a) + 1.0)
	if not inner.has_point(end_pt):
		s = -s
	return s


static func _face_normal(p: Vector2, g: Rect2) -> Vector2:
	var dx: float = maxf(g.position.x - p.x, p.x - g.end.x)
	var dy: float = maxf(g.position.y - p.y, p.y - g.end.y)
	if dx >= dy:
		return Vector2.LEFT if p.x < g.get_center().x else Vector2.RIGHT
	return Vector2.UP if p.y < g.get_center().y else Vector2.DOWN


## Onde uma letra ou gota de tinta fica: a até `drop_margin` de uma peça, sai para margem + folga.
func drop_point(p: Vector2) -> Vector2:
	if is_free(p, drop_margin):
		return p
	return nearest_free(p, drop_margin + drop_clearance)


## Onde um inimigo de raio `r` nasce: fora da peça inflada pelo raio + folga.
func spawn_point(p: Vector2, r: float) -> Vector2:
	var need: float = r + spawn_clearance
	return p if is_free(p, need) else nearest_free(p, need)


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
