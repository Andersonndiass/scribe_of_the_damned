class_name Arena
extends Node2D
## A página de 640×360 com parede de colisão na margem de 24px (FR-006, art bible §7.4)
## e a camada acumulativa de decals (SubViewport com custo fixo; usada a partir do T076).

const PAGE_SIZE := Vector2(640, 360)
const MARGIN := 24.0
## Área onde o jogador e os inimigos podem estar.
const PLAYABLE := Rect2(Vector2(MARGIN, MARGIN), PAGE_SIZE - Vector2(MARGIN, MARGIN) * 2.0)

## Carimbos pendentes para a camada acumulativa (desenhados uma vez e esquecidos: custo fixo).
class DecalStamp:
	extends Node2D
	var pending: Array[Dictionary] = []

	func _draw() -> void:
		for s: Dictionary in pending:
			if s["kind"] == &"burn":
				_draw_burn(s["pos"], s["radius"])
			elif s["kind"] == &"stain":
				_draw_stain(s["pos"])

	## Mancha permanente e discreta de cada morte (3 pixels INK_SOFT).
	func _draw_stain(p: Vector2) -> void:
		var q: Vector2 = p.round()
		draw_rect(Rect2(q.x - 1, q.y, 1, 1), Palette.INK_SOFT)
		draw_rect(Rect2(q.x + 1, q.y, 1, 1), Palette.INK_SOFT)
		draw_rect(Rect2(q.x, q.y + 1, 1, 1), Palette.INK_SOFT)

	## Queimado em dithering (IGNIS): borda INK_SOFT esparsa, miolo INK salpicado. Sem degradê.
	func _draw_burn(center: Vector2, radius: float) -> void:
		var r: int = ceili(radius)
		for y: int in range(-r, r + 1):
			for x: int in range(-r, r + 1):
				var d: float = Vector2(x, y).length()
				if d > radius:
					continue
				var inner: bool = d <= radius * 0.55
				if inner and (x * 7 + y * 13) % 5 == 0:
					draw_rect(Rect2(center.x + x, center.y + y, 1, 1), Palette.INK)
				elif not inner and (x + y) % 3 == 0:
					draw_rect(Rect2(center.x + x, center.y + y, 1, 1), Palette.INK_SOFT)


var decal_viewport: SubViewport
## Quantos carimbos já foram acumulados na página (para testes e métricas).
var stamp_count: int = 0
var stamps_by_kind: Dictionary[StringName, int] = {}
## Estágio de degradação 0..3 (FR-026, art bible §7.2). Avança 1 por onda, em loop no protótipo.
var degradation_stage: int = 0

const DEGRADATION_STAGES := 4
const WEAR_SEED := 1348

var _stamp: DecalStamp


func _ready() -> void:
	add_to_group(&"arena")
	_build_walls()
	_build_decal_layer()
	EventBus.wave_ended.connect(func(_i: int) -> void: set_degradation((degradation_stage + 1) % DEGRADATION_STAGES))
	EventBus.enemy_killed.connect(func(_s: int, _d: EnemyData, p: Vector2) -> void: stamp(&"stain", p, 0.0))


func set_degradation(stage: int) -> void:
	degradation_stage = clampi(stage, 0, DEGRADATION_STAGES - 1)
	queue_redraw()


## Carimba um decal permanente na página (queimado do IGNIS; mais tipos no T076).
func stamp(kind: StringName, pos: Vector2, radius: float) -> void:
	_stamp.pending.append({"kind": kind, "pos": pos, "radius": radius})
	stamp_count += 1
	stamps_by_kind[kind] = stamps_by_kind.get(kind, 0) + 1
	_stamp.queue_redraw()
	decal_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	if not RenderingServer.frame_post_draw.is_connected(_flush_stamps):
		RenderingServer.frame_post_draw.connect(_flush_stamps, CONNECT_ONE_SHOT)


func _flush_stamps() -> void:
	_stamp.pending.clear()
	_stamp.queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, PAGE_SIZE), Palette.PARCHMENT)
	draw_rect(PLAYABLE, Palette.PARCHMENT_OLD, false, 1.0)
	_draw_wear()


## Desgaste da página por estágio, determinístico (mesma seed = mesma página). Só dithering.
## 1: pontos de tinta perto das bordas · 2: + furos na margem · 3: + bordas queimadas e vinheta.
func _draw_wear() -> void:
	if degradation_stage == 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = WEAR_SEED
	for i: int in 90 * degradation_stage:
		var edge: int = i % 4
		var along: float = rng.randf()
		var depth: float = rng.randf_range(0.0, 36.0)
		var p: Vector2
		match edge:
			0: p = Vector2(along * PAGE_SIZE.x, depth)
			1: p = Vector2(along * PAGE_SIZE.x, PAGE_SIZE.y - 1 - depth)
			2: p = Vector2(depth, along * PAGE_SIZE.y)
			_: p = Vector2(PAGE_SIZE.x - 1 - depth, along * PAGE_SIZE.y)
		draw_rect(Rect2(p.round(), Vector2.ONE), Palette.INK_SOFT)
	if degradation_stage >= 2:
		for h: Vector2 in [Vector2(60, 11), Vector2(590, 348), Vector2(12, 300), Vector2(628, 70)]:
			draw_circle(h, 5.0, Palette.INK_SOFT)
			draw_circle(h, 3.0, Palette.INK)
	if degradation_stage >= 3:
		for y: int in range(0, int(PAGE_SIZE.y), 2):
			for x: int in range(0, 6, 2):
				draw_rect(Rect2(x + (y / 2) % 2, y, 1, 1), Palette.PARCHMENT_OLD)
				draw_rect(Rect2(PAGE_SIZE.x - 1 - x - (y / 2) % 2, y, 1, 1), Palette.PARCHMENT_OLD)
		for c: Vector2 in [Vector2(2, 2), Vector2(PAGE_SIZE.x - 3, 2), Vector2(2, PAGE_SIZE.y - 3), Vector2(PAGE_SIZE.x - 3, PAGE_SIZE.y - 3)]:
			for k: int in 6:
				draw_rect(Rect2(c + Vector2((k % 3) * 2 * signf(PAGE_SIZE.x / 2 - c.x), (k / 3) * 2 * signf(PAGE_SIZE.y / 2 - c.y)), Vector2.ONE), Palette.BLOOD)


func _build_walls() -> void:
	var body := StaticBody2D.new()
	body.name = "Walls"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var w: float = PAGE_SIZE.x
	var h: float = PAGE_SIZE.y
	var rects: Array[Rect2] = [
		Rect2(0, 0, w, MARGIN), Rect2(0, h - MARGIN, w, MARGIN),
		Rect2(0, 0, MARGIN, h), Rect2(w - MARGIN, 0, MARGIN, h),
	]
	for rect: Rect2 in rects:
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var col := CollisionShape2D.new()
		col.shape = shape
		col.position = rect.get_center()
		body.add_child(col)


func _build_decal_layer() -> void:
	decal_viewport = SubViewport.new()
	decal_viewport.name = "DecalViewport"
	decal_viewport.size = Vector2i(PAGE_SIZE)
	decal_viewport.transparent_bg = true
	decal_viewport.disable_3d = true
	decal_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	decal_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(decal_viewport)
	_stamp = DecalStamp.new()
	decal_viewport.add_child(_stamp)
	var view := Sprite2D.new()
	view.name = "DecalView"
	view.centered = false
	view.texture = decal_viewport.get_texture()
	add_child(view)
