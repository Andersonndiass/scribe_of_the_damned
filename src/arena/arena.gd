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
## Estágio de degradação 0..3 visível (FR-026, art bible §7.2; 004: vem do `PageDegradation`).
var degradation_stage: int = 0
## Estado da página (004 FR-401..FR-404): o estágio só avança, com ameaça e revelação.
var page := PageDegradation.new()
var data: ArenaData
var wave_tuning: WaveTuning = preload("res://data/tuning/wave.tres")
var _map: ObstacleMap
var _obstacle_body: StaticBody2D

const DEGRADATION_STAGES := 4
## Camadas geradas (tools/gen_arena_placeholders.gd); a arte do autor em `ArenaData.layer_dir`
## com o mesmo nome da camada (bg.png, ghost_0.png…) substitui cada uma (FR-407).
## 012: por capítulo (env_page_c<N>_…); cai na do Cap. 1 se o capítulo não tiver.
const PLACEHOLDER_PAGE := "res://assets/placeholders/env_page_c%d_%s.png"
const PLACEHOLDER_OBSTACLE := "res://assets/placeholders/env_obs_%s%s.png"
const DEFAULT_LAYER_DIR := "res://assets/arena/chapter_1/"
const SHADOW_OFFSET := Vector2(-2, 2)
const REVEAL_SHADER := preload("res://src/arena/stage_reveal.gdshader")

var _stamp: DecalStamp
## Pilha da página (FR-405): fundo, texto-fantasma, ornamentos, estágios 1..3 — texturas em cache.
## A página inteira num desenho só (SC-405): as camadas estáticas são montadas numa imagem fora do
## combate (fim da onda, começo da onda); só o estágio sendo revelado fica por cima, com o shader.
var _page_sprite: Sprite2D
var _reveal_sprite: Sprite2D
var _page_texture: ImageTexture
var _page_image: Image
## Estágio que está montado na textura da página (-1 = nenhum).
var composed_stage: int = -1
var _bg_image: Image
var _ornaments_image: Image
var _ghost_images: Array[Image] = []
var _stage_images: Array[Image] = []
var _stage_textures: Array[Texture2D] = []
var _reveal_material := ShaderMaterial.new()
var _obstacle_sprites: Array[Sprite2D] = []
var ambience: FrameAmbience
var ambience_tuning: ArenaAmbienceTuning = preload("res://data/tuning/arena_ambience.tres")


func _ready() -> void:
	add_to_group(&"arena")
	_reveal_material.shader = REVEAL_SHADER
	_build_layers()
	_build_walls()
	_build_decal_layer()
	ambience = FrameAmbience.new()
	ambience.name = "FrameAmbience"
	ambience.tuning = ambience_tuning
	ambience.page = page
	add_child(ambience)
	page.degraded.connect(func(stage: int) -> void:
		set_degradation(stage)
		EventBus.page_degraded.emit(stage))
	EventBus.page_stage_changed.connect(func(stage: int, next: int, animated: bool) -> void:
		page.apply(stage, next, animated)
		_update_layers())
	EventBus.wave_closing.connect(func(_i: int, _left: float) -> void: page.on_closing())
	# A loja pausa a árvore: a revelação termina antes (004 FR-402).
	EventBus.shop_opened.connect(func(_w: int) -> void:
		page.snap()
		_update_layers())
	EventBus.arena_layout_changed.connect(_on_layout_changed)
	EventBus.enemy_killed.connect(func(_s: int, _d: EnemyData, p: Vector2) -> void: stamp(&"stain", p, 0.0))


func _exit_tree() -> void:
	if ObstacleQuery.map != null and ObstacleQuery.map == _map:
		ObstacleQuery.map = null


func _process(delta: float) -> void:
	if page.state == PageDegradation.Phase.TRANSITIONING:
		page.tick(delta, wave_tuning.reveal_time)
		_update_layers()


## Monta a página do capítulo (004): o mapa de obstáculos das ondas passa a responder às consultas.
func load_page(arena_data: ArenaData) -> void:
	data = arena_data
	_load_layer_textures()
	_build_obstacle_sprites()
	_on_layout_changed(false)


func _on_layout_changed(boss_layout: bool) -> void:
	_map = ObstacleMap.from_arena(data, boss_layout)
	ObstacleQuery.map = _map
	_sync_obstacle_bodies(boss_layout)
	for k: int in _obstacle_sprites.size():
		var o: ObstacleData = data.obstacles[k]
		_obstacle_sprites[k].visible = o.in_boss if boss_layout else o.in_waves


## Paredes das peças para o escriba (004 FR-410): criadas uma vez ao montar a página; a troca de
## layout (chefe) só liga e desliga as formas — nada é criado durante a onda.
func _sync_obstacle_bodies(boss_layout: bool) -> void:
	if data == null:
		return
	if _obstacle_body == null:
		_obstacle_body = StaticBody2D.new()
		_obstacle_body.name = "Obstacles"
		_obstacle_body.collision_layer = 1
		_obstacle_body.collision_mask = 0
		add_child(_obstacle_body)
		for o: ObstacleData in data.obstacles:
			var shape := RectangleShape2D.new()
			shape.size = Vector2(o.type.footprint)
			var col := CollisionShape2D.new()
			col.shape = shape
			col.position = o.rect().get_center()
			_obstacle_body.add_child(col)
	for k: int in data.obstacles.size():
		var o: ObstacleData = data.obstacles[k]
		var blocks_walk: bool = o.type.blocks & ObstacleTypeData.Block.WALK != 0
		var on: bool = blocks_walk and (o.in_boss if boss_layout else o.in_waves)
		(_obstacle_body.get_child(k) as CollisionShape2D).set_deferred(&"disabled", not on)


func set_degradation(stage: int) -> void:
	degradation_stage = clampi(stage, 0, DEGRADATION_STAGES - 1)
	_update_layers()


## A página montada no estágio visível; o estágio sendo revelado aparece por cima, em degraus.
func _update_layers() -> void:
	if _page_sprite == null or _bg_image == null:
		return
	if composed_stage != page.shown_stage:
		_compose(page.shown_stage)
	var revealing: bool = page.state == PageDegradation.Phase.TRANSITIONING and page.stage > page.shown_stage
	_reveal_sprite.visible = revealing
	if revealing:
		var steps: int = ambience_tuning.reveal_steps
		_reveal_sprite.texture = _stage_textures[page.stage - 1]
		_reveal_material.set_shader_parameter(&"level", clampi(ceili(page.reveal * steps), 0, steps))


## Monta fundo + texto-fantasma do estágio + ornamentos + estágios até `stage` numa imagem só.
## Roda só quando o estágio visível muda (fora do combate); atualiza a mesma textura, sem alocar.
func _compose(stage: int) -> void:
	var full := Rect2i(Vector2i.ZERO, Vector2i(PAGE_SIZE))
	_page_image.copy_from(_bg_image)
	_page_image.blend_rect(_ghost_images[clampi(stage, 0, _ghost_images.size() - 1)], full, Vector2i.ZERO)
	_page_image.blend_rect(_ornaments_image, full, Vector2i.ZERO)
	for s: int in range(1, stage + 1):
		_page_image.blend_rect(_stage_images[s - 1], full, Vector2i.ZERO)
	if _page_texture == null:
		_page_texture = ImageTexture.create_from_image(_page_image)
		_page_sprite.texture = _page_texture
	else:
		_page_texture.update(_page_image)
	composed_stage = stage


func _build_layers() -> void:
	_page_sprite = Sprite2D.new()
	_page_sprite.name = "Page"
	_page_sprite.centered = false
	add_child(_page_sprite)
	_reveal_sprite = Sprite2D.new()
	_reveal_sprite.name = "Reveal"
	_reveal_sprite.centered = false
	_reveal_sprite.material = _reveal_material
	_reveal_sprite.visible = false
	add_child(_reveal_sprite)
	_load_layer_textures()


func _load_layer_textures() -> void:
	_bg_image = _layer_image("bg")
	_ornaments_image = _layer_image("ornaments")
	_ghost_images.clear()
	for s: int in DEGRADATION_STAGES:
		_ghost_images.append(_layer_image("ghost_%d" % s))
	_stage_images.clear()
	_stage_textures.clear()
	for s: int in range(1, DEGRADATION_STAGES):
		_stage_textures.append(_layer_texture("stage_%d" % s))
		_stage_images.append(_layer_image("stage_%d" % s))
	_page_image = Image.create(int(PAGE_SIZE.x), int(PAGE_SIZE.y), false, Image.FORMAT_RGBA8)
	composed_stage = -1
	_update_layers()


func _layer_image(layer: String) -> Image:
	var img: Image = _layer_texture(layer).get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


## Arte do autor da camada, se existir; senão, a gerada.
func _layer_texture(layer: String) -> Texture2D:
	var dir: String = data.layer_dir if data != null else DEFAULT_LAYER_DIR
	var author: String = dir + layer + ".png"
	if ResourceLoader.exists(author):
		return load(author)
	var own: String = PLACEHOLDER_PAGE % [data.chapter if data != null else 1, layer]
	return load(own) if ResourceLoader.exists(own) else load(PLACEHOLDER_PAGE % [1, layer])


## Peças e sombras (FR-412), acima dos decals: criadas uma vez ao montar a página.
func _build_obstacle_sprites() -> void:
	for sprite: Sprite2D in _obstacle_sprites:
		sprite.queue_free()
	_obstacle_sprites.clear()
	if data == null:
		return
	for o: ObstacleData in data.obstacles:
		var holder := Sprite2D.new()
		holder.name = "Obstacle_%s" % o.type.id
		holder.centered = false
		holder.position = Vector2(o.position)
		holder.texture = o.type.texture if o.type.texture != null else _obstacle_texture(o.type.id, "")
		var shadow_tex: Texture2D = _obstacle_texture(o.type.id, "_shadow")
		if shadow_tex != null:
			var shadow := Sprite2D.new()
			shadow.name = "Shadow"
			shadow.centered = false
			shadow.texture = shadow_tex
			shadow.position = SHADOW_OFFSET
			shadow.show_behind_parent = true
			holder.add_child(shadow)
		add_child(holder)
		_obstacle_sprites.append(holder)
	# O ambiente da moldura fica por cima de tudo.
	move_child(ambience, -1)


func _obstacle_texture(id: StringName, suffix: String) -> Texture2D:
	var path: String = PLACEHOLDER_OBSTACLE % [id, suffix]
	return load(path) if ResourceLoader.exists(path) else null


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
