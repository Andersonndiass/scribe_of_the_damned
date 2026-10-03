class_name PlayArea
extends RefCounted
## Área jogável viva (012 FR-1212; mechanics-agent T1200): começa na página inteira
## (`ArenaData.PLAYABLE`) e só encolhe — `shrink_to` faz a interseção, então nunca cresce por
## construção. A Mãe das Traças come as bordas (EatPageAttack); escriba, inimigos, chefe, mapa
## de peças e gotas leem `rect`. A borda de cima nunca é comida (é onde o chefe fica).

static var rect: Rect2 = ArenaData.PLAYABLE


static func reset() -> void:
	rect = ArenaData.PLAYABLE
	_emit()


## Pelo nó (não pelo identificador): scripts `-s` (sonda) não enxergam autoloads em class_name.
static func _emit() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var bus: Node = tree.root.get_node_or_null(^"EventBus") if tree != null else null
	if bus != null:
		bus.emit_signal(&"play_area_changed", rect)


static func is_shrunk() -> bool:
	return rect != ArenaData.PLAYABLE


## Encolhe para a interseção com `r` (nunca cresce) e avisa quem usa a área.
static func shrink_to(r: Rect2) -> void:
	var next: Rect2 = rect.intersection(r)
	if next == rect or not next.has_area():
		return
	rect = next
	_emit()


## O ponto empurrado para dentro (círculo de raio `r`).
static func push_inside(p: Vector2, r: float) -> Vector2:
	var inner: Rect2 = rect.grow(-r)
	return p.clamp(inner.position, inner.end)


## A menor área permitida: `min_size` centrada na largura da página, presa no topo.
static func min_rect(min_size: Vector2) -> Rect2:
	return Rect2(ArenaData.PLAYABLE.get_center().x - min_size.x / 2.0, ArenaData.PLAYABLE.position.y, min_size.x, min_size.y)


## A área depois de morder `depth` px da borda `side` (&"left", &"right", &"bottom"), sem passar do mínimo.
static func target(side: StringName, depth: float, min_size: Vector2) -> Rect2:
	var m: Rect2 = min_rect(min_size)
	var r: Rect2 = rect
	match side:
		&"left":
			var x: float = minf(r.position.x + depth, m.position.x)
			r = Rect2(Vector2(maxf(x, r.position.x), r.position.y), Vector2(r.end.x - maxf(x, r.position.x), r.size.y))
		&"right":
			var e: float = maxf(r.end.x - depth, m.end.x)
			r.size.x = minf(e, r.end.x) - r.position.x
		&"bottom":
			var b: float = maxf(r.end.y - depth, m.end.y)
			r.size.y = minf(b, r.end.y) - r.position.y
	return r


## A faixa que a mordida come.
static func strip(side: StringName, depth: float, min_size: Vector2) -> Rect2:
	var t: Rect2 = target(side, depth, min_size)
	match side:
		&"left":
			return Rect2(rect.position, Vector2(t.position.x - rect.position.x, rect.size.y))
		&"right":
			return Rect2(Vector2(t.end.x, rect.position.y), Vector2(rect.end.x - t.end.x, rect.size.y))
		_:
			return Rect2(Vector2(rect.position.x, t.end.y), Vector2(rect.size.x, rect.end.y - t.end.y))


## Folga (px) que a borda `side` ainda pode perder.
static func slack(side: StringName, min_size: Vector2) -> float:
	var m: Rect2 = min_rect(min_size)
	match side:
		&"left":
			return m.position.x - rect.position.x
		&"right":
			return rect.end.x - m.end.x
		_:
			return rect.end.y - m.end.y
