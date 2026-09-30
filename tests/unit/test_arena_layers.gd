extends GutTest
## T423 Camadas da página (004 SC-403, SC-404; design-agent T420): a degradação dentro da área
## jogável é só PARCHMENT_OLD, pouca, colada na parede, longe do centro e das peças; sem BLOOD.
## Arena monta a pilha, revela o estágio em degraus e os ambientes ficam na moldura, fora do HUD.

const ARENA_SCENE := preload("res://src/arena/arena.tscn")
const CHAPTER := preload("res://data/chapters/chapter_1.tres")
const DIR := "res://assets/placeholders/"
const PLAYABLE := Rect2i(24, 24, 592, 312)
const CENTER := Rect2i(160, 60, 320, 240)
## Orçamento do design-agent: pixels de degradação dentro da área jogável, somando os 3 estágios.
const INSIDE_BUDGET := 600
## Dentro da área jogável, a degradação fica a até isto da parede.
const WALL_REACH := 36
const DT := 1.0 / 60.0

var _arena: Arena


func before_each() -> void:
	_arena = ARENA_SCENE.instantiate()
	add_child_autofree(_arena)
	_arena.load_page(CHAPTER.arena)


func _img(name: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(DIR + name + ".png"))
	img.convert(Image.FORMAT_RGBA8)
	return img


func _same(c: Color, p: Color) -> bool:
	return c.r8 == p.r8 and c.g8 == p.g8 and c.b8 == p.b8


func test_degradation_inside_the_playable_area_is_low_and_near_the_wall() -> void:
	var inside: int = 0
	var obstacles: Array[Rect2i] = []
	for o: ObstacleData in CHAPTER.arena.obstacles:
		obstacles.append(o.rect().grow(4))
	for s: int in range(1, 4):
		var img: Image = _img("env_page_c1_stage_%d" % s)
		for y: int in img.get_height():
			for x: int in img.get_width():
				var c: Color = img.get_pixel(x, y)
				if c.a8 == 0:
					continue
				assert_false(_same(c, Palette.BLOOD) or _same(c, Palette.BLOOD_DARK), "estágio %d sem BLOOD" % s)
				var p := Vector2i(x, y)
				if not PLAYABLE.has_point(p):
					continue
				inside += 1
				if not _same(c, Palette.PARCHMENT_OLD):
					fail_test("estágio %d: %s dentro da área jogável não é PARCHMENT_OLD" % [s, p])
					return
				if CENTER.has_point(p):
					fail_test("estágio %d: %s na área central" % [s, p])
					return
				var to_wall: int = mini(mini(x - PLAYABLE.position.x, PLAYABLE.end.x - 1 - x), mini(y - PLAYABLE.position.y, PLAYABLE.end.y - 1 - y))
				if to_wall > WALL_REACH:
					fail_test("estágio %d: %s longe da parede (%d px)" % [s, p, to_wall])
					return
				for r: Rect2i in obstacles:
					if r.has_point(p):
						fail_test("estágio %d: %s em cima de uma peça" % [s, p])
						return
	assert_lt(inside, INSIDE_BUDGET, "pouca área dentro da página (%d px)" % inside)


func test_page_layers_have_no_blood() -> void:
	var names: Array[String] = ["env_page_c1_bg", "env_page_c1_ornaments", "vfx_ember"]
	for s: int in 4:
		names.append("env_page_c1_ghost_%d" % s)
	for n: String in names:
		var img: Image = _img(n)
		var blood: int = 0
		for y: int in img.get_height():
			for x: int in img.get_width():
				var c: Color = img.get_pixel(x, y)
				if c.a8 > 0 and (_same(c, Palette.BLOOD) or _same(c, Palette.BLOOD_DARK)):
					blood += 1
		assert_eq(blood, 0, "%s sem BLOOD" % n)


func test_ghost_text_fades_word_by_word() -> void:
	var counts: Array[int] = []
	for s: int in 4:
		var img: Image = _img("env_page_c1_ghost_%d" % s)
		var n: int = 0
		for y: int in img.get_height():
			for x: int in img.get_width():
				if img.get_pixel(x, y).a8 > 0:
					n += 1
		counts.append(n)
	for s: int in range(1, 4):
		assert_lt(counts[s], counts[s - 1], "o texto-fantasma falha mais no estágio %d" % s)


func test_arena_stacks_the_stages_it_has_reached() -> void:
	EventBus.page_stage_changed.emit(2, 2, false)
	assert_true(_arena._stages[0].visible)
	assert_true(_arena._stages[1].visible)
	assert_false(_arena._stages[2].visible, "o estágio 3 ainda não")
	assert_eq(_arena._ghost.texture, _arena._ghost_textures[2])
	assert_eq(_arena._obstacle_sprites.size(), 7, "as 7 peças na página")


func test_reveal_comes_in_steps_then_settles() -> void:
	EventBus.page_stage_changed.emit(2, 3, false)
	EventBus.page_stage_changed.emit(3, 3, true)
	var stage3: Sprite2D = _arena._stages[2]
	assert_true(stage3.visible, "o estágio novo aparece já no começo da revelação")
	assert_eq(stage3.material, _arena._reveal_material, "em degraus, pelo shader")
	var levels: Array[int] = []
	for t: int in 30:
		_arena._process(DT)
		if stage3.material != null:
			levels.append(int(_arena._reveal_material.get_shader_parameter(&"level")))
	assert_eq(stage3.material, null, "terminou: sem shader")
	assert_eq(_arena.degradation_stage, 3)
	for i: int in range(1, levels.size()):
		assert_true(levels[i] >= levels[i - 1], "os degraus só sobem")
	assert_true(levels.has(1) and levels.has(2) and levels.has(3), "passa pelos degraus: %s" % [levels])


func test_ambience_stays_in_the_frame_and_off_the_hud() -> void:
	var amb: FrameAmbience = _arena.ambience
	var tuning: ArenaAmbienceTuning = amb.tuning
	EventBus.page_stage_changed.emit(3, 3, false)
	for t: int in 600:
		amb._process(DT)
		assert_lte(amb.count(FrameAmbience.Kind.EMBER), tuning.ember_max)
		assert_lte(amb.count(FrameAmbience.Kind.DUST), tuning.dust_max)
		for p: Vector2 in amb.positions():
			if not amb.in_band(p):
				fail_test("fora da moldura: %s" % p)
				return
			for r: Rect2 in tuning.hud_avoid:
				if r.has_point(p):
					fail_test("sob o HUD %s: %s" % [r, p])
					return
	assert_gt(amb.count(FrameAmbience.Kind.EMBER), 0, "brasas no estágio 3")
	assert_gt(amb.count(FrameAmbience.Kind.DUST), 0, "poeira no estágio ≥ 2")


func test_threat_only_before_a_worse_page_and_leaves_with_the_wave() -> void:
	var amb: FrameAmbience = _arena.ambience
	EventBus.page_stage_changed.emit(0, 0, false)
	EventBus.wave_closing.emit(1, 10.0)
	for t: int in 180:
		amb._process(DT)
	assert_eq(amb.count(FrameAmbience.Kind.SMOKE), 0, "0 → 0: sem ameaça")
	EventBus.page_stage_changed.emit(0, 1, false)
	EventBus.wave_closing.emit(2, 10.0)
	for t: int in 180:
		amb._process(DT)
	assert_gt(amb.count(FrameAmbience.Kind.SMOKE), 0, "0 → 1: fumaça de tinta")
	EventBus.page_stage_changed.emit(1, 1, true)
	for t: int in ceili(amb.tuning.fade_out / DT) + 1:
		amb._process(DT)
	assert_eq(amb.count(FrameAmbience.Kind.SMOKE), 0, "a ameaça sai junto com a revelação")
