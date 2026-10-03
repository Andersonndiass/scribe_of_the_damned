extends SceneTree
## Gera as camadas da página do Cap. 1 e as peças (004 T421; parecer do design-agent T420).
## Pixel art em blocos sólidos, só as 9 cores exatas, sem xadrez em área pequena nem pixel solto
## (D-075/D-076). Saída: só PNG em assets/placeholders/ (importado comprimido sem perda: as
## camadas de 640×360 em .tres embutido ocupavam ~1 MB cada no build). Rodar --import depois.
## A arte do autor por camada, em assets/arena/chapter_1/<camada>.png, substitui estas (FR-407).
## Uso: godot --headless --path . -s tools/gen_arena_placeholders.gd [-- chapter=2]
## 012: `chapter=N` gera só a página do capítulo N (env_page_cN_*, peças de `chapter_N.tres`).

const OUT := "res://assets/placeholders/"
const W := 640
const H := 360
const ARENA := "res://data/arena/chapter_%d.tres"
const BASE_SEED := 1348
## Texto-fantasma: % das palavras que ficam em cada estágio (a mesma palavra some e não volta).
const GHOST_KEEP: Array[int] = [100, 70, 50, 15]
## Faixas do HUD de cima em que o queimado do estágio 3 fica raso (x0, x1).
const HUD_TOP_SPANS: Array[Vector2i] = [Vector2i(8, 158), Vector2i(275, 365), Vector2i(520, 632)]

var K := Palette.INK
var k := Palette.INK_SOFT
var O := Palette.PARCHMENT_OLD
var P := Palette.PARCHMENT
var C := Palette.CHALK
var _obstacles: Array[Rect2] = []
var _chapter: int = 1
var SEED: int = BASE_SEED


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("chapter="):
			_chapter = int(a.substr(8))
	SEED = BASE_SEED + 97 * (_chapter - 1)
	var arena: ArenaData = load(ARENA % _chapter)
	for o: ObstacleData in arena.obstacles:
		_obstacles.append(Rect2(o.rect()))
	var pre: String = "env_page_c%d_" % _chapter
	_save(_bg(), pre + "bg")
	for s: int in 4:
		_save(_ghost(s), pre + "ghost_%d" % s)
	_save(_ornaments(), pre + "ornaments")
	_save(_stage_1(), pre + "stage_1")
	_save(_stage_2(), pre + "stage_2")
	_save(_stage_3(), pre + "stage_3")
	if _chapter != 1:
		quit()
		return
	_save(_hole(), "env_obs_hole")
	_save(_bench(), "env_obs_bench")
	_save(_solid(Vector2i(32, 8), k), "env_obs_bench_shadow")
	var win: Image = _window()
	_save(win, "env_obs_window")
	_save(_silhouette(win, k), "env_obs_window_shadow")
	_save(_altar(), "env_obs_altar")
	_save(_solid(Vector2i(60, 16), k), "env_obs_altar_shadow")
	_save(_ember(), "vfx_ember")
	print("gen_arena_placeholders: ok")
	quit()


func _page() -> Image:
	return Image.create(W, H, false, Image.FORMAT_RGBA8)


func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height())), c)


func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


## Bloco 2×2 (traço de pena de 2 px).
func _dot2(img: Image, x: int, y: int, c: Color) -> void:
	_rect(img, x, y, 2, 2, c)


## Traço de 2 px de (a) a (b) em degraus.
func _stroke(img: Image, a: Vector2i, b: Vector2i, c: Color) -> void:
	var n: int = maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i: int in n + 1:
		var t: float = float(i) / maxf(1.0, n)
		_dot2(img, roundi(lerpf(a.x, b.x, t)), roundi(lerpf(a.y, b.y, t)), c)


# --- Fundo ---------------------------------------------------------------------------------

func _bg() -> Image:
	var img := _page()
	img.fill(P)
	# Borda externa gasta (2 px) e a linha da parede (2 px) fora da área jogável.
	for r: Rect2i in [Rect2i(0, 0, W, 2), Rect2i(0, H - 2, W, 2), Rect2i(0, 0, 2, H), Rect2i(W - 2, 0, 2, H)]:
		img.fill_rect(r, O)
	_rect(img, 22, 22, 596, 2, O)
	_rect(img, 22, 336, 596, 2, O)
	_rect(img, 22, 22, 2, 316, O)
	_rect(img, 616, 22, 2, 316, O)
	return img


# --- Texto-fantasma -----------------------------------------------------------------------

## Linhas de base de 1 px com palavras de 6–22 px; 1 em cada 3 com haste de 1×2. Cada palavra
## some inteira por hash (estágio maior = subconjunto do anterior).
func _ghost(stage: int) -> Image:
	var img := _page()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var word_id: int = 0
	for col: Vector2i in [Vector2i(36, 300), Vector2i(340, 604)]:
		for line: int in 24:
			var y: int = 40 + line * 12
			var x: int = col.x
			var end: int = col.y - rng.randi_range(0, 60)
			while true:
				var w: int = rng.randi_range(6, 22)
				if x + w > end:
					break
				var keep: bool = (word_id * 2654435761) % 100 < GHOST_KEEP[stage]
				var r := Rect2(x, y - 2, w, 3)
				if keep and not _near_obstacle(r, 4.0):
					_rect(img, x, y, w, 1, O)
					if word_id % 3 == 0:
						_rect(img, x + w / 2, y - 2, 1, 2, O)
				word_id += 1
				x += w + 4
	return img


func _near_obstacle(r: Rect2, pad: float) -> bool:
	for o: Rect2 in _obstacles:
		if o.grow(pad).intersects(r):
			return true
	return false


# --- Ornamentos ---------------------------------------------------------------------------

func _ornaments() -> Image:
	var img := _page()
	# Cantos de baixo: L de hastes de 2 px, 3 folhas e nó no vértice.
	for right: bool in [false, true]:
		var x0: int = 618 if right else 2
		_rect(img, x0, 356, 20, 2, k)
		_rect(img, x0 + (18 if right else 0), 338, 2, 20, k)
		for leaf: Vector2i in [Vector2i(3, 5), Vector2i(3, 11), Vector2i(9, 13)]:
			var lx: int = x0 + (20 - leaf.x - 5 if right else leaf.x)
			_rect(img, lx, 338 + leaf.y, 5, 4, k)
			_rect(img, lx + 1, 338 + leaf.y + 1, 3, 2, O)
		_rect(img, x0 + (17 if right else 0), 355, 3, 3, k)
	# Cantos de cima: só o L externo (o HUD começa em x8/y6).
	_rect(img, 2, 2, 18, 2, k)
	_rect(img, 2, 2, 2, 18, k)
	_rect(img, 2, 2, 3, 3, O)
	_rect(img, 620, 2, 18, 2, k)
	_rect(img, 636, 2, 2, 18, k)
	_rect(img, 635, 2, 3, 3, O)
	# Sem capitular: a caixa com "I" em (3,38) parecia botão na coluna do HUD (T1800; game-design ok).
	return img


# --- Estágios -----------------------------------------------------------------------------

## Mancha de tinta: INK_SOFT com miolo INK 2×2.
func _stain(img: Image, x: int, y: int, w: int, h: int) -> void:
	_rect(img, x, y, w, h, k)
	_rect(img, x + w / 2 - 1, y + h / 2 - 1, 2, 2, K)


## Respingo baixo dentro da área jogável: PARCHMENT_OLD, cantos cortados.
func _speck(img: Image, x: int, y: int, w: int, h: int) -> void:
	_rect(img, x + 1, y, w - 2, h, O)
	_rect(img, x, y + 1, w, h - 2, O)


func _stage_1() -> Image:
	var img := _page()
	for s: Rect2i in [Rect2i(200, 9, 8, 5), Rect2i(430, 12, 6, 4), Rect2i(6, 312, 7, 6), Rect2i(624, 120, 6, 8), Rect2i(330, 346, 8, 5)]:
		_stain(img, s.position.x, s.position.y, s.size.x, s.size.y)
	_stroke(img, Vector2i(60, 350), Vector2i(100, 344), k)
	_stroke(img, Vector2i(380, 17), Vector2i(420, 15), k)
	for y: int in range(220, 256, 2):
		_dot2(img, 626 + (2 if (y / 6) % 2 == 1 else 0), y, k)
	for s: Vector2i in [Vector2i(30, 120), Vector2i(600, 236), Vector2i(40, 320)]:
		_speck(img, s.x, s.y, 5, 3)
	return img


## Rasura em zigue-zague de 2 px (16×8, ou 8×16 na vertical).
func _scribble(img: Image, x: int, y: int, vertical: bool) -> void:
	for i: int in range(0, 16, 2):
		var off: int = [0, 3, 6, 3][(i / 2) % 4]
		if vertical:
			_dot2(img, x + off, y + i, k)
		else:
			_dot2(img, x + i, y + off, k)


## Rasgo vindo da borda: miolo INK afinando em degraus, lábio de 1 px PARCHMENT_OLD.
## `edge`: 0 topo, 1 direita, 2 base, 3 esquerda; `at` = posição ao longo da borda.
func _tear(img: Image, edge: int, at: int, width: int, depth: int) -> void:
	for d: int in depth:
		var w: int = maxi(2, (width * (depth - d) / depth) / 2 * 2)
		var a: int = at - w / 2
		for i: int in range(-1, w + 1):
			var c: Color = K if i >= 0 and i < w else O
			var p: Vector2i
			match edge:
				0: p = Vector2i(a + i, d)
				1: p = Vector2i(W - 1 - d, a + i)
				2: p = Vector2i(a + i, H - 1 - d)
				_: p = Vector2i(d, a + i)
			_px(img, p.x, p.y, c)
	# Lábio na ponta.
	var tip: int = depth
	match edge:
		0: _rect(img, at - 1, tip, 2, 1, O)
		1: _rect(img, W - 1 - tip, at - 1, 1, 2, O)
		2: _rect(img, at - 1, H - 1 - tip, 2, 1, O)
		_: _rect(img, tip, at - 1, 1, 2, O)


func _stage_2() -> Image:
	var img := _page()
	_scribble(img, 240, 344, false)
	_scribble(img, 560, 346, false)
	_scribble(img, 620, 60, true)
	_scribble(img, 470, 8, false)
	_tear(img, 0, 234, 8, 10)
	_tear(img, 1, 155, 10, 14)
	_tear(img, 1, 294, 8, 12)
	_tear(img, 2, 405, 10, 14)
	_tear(img, 3, 326, 8, 12)
	# Ornamentos riscados.
	_stroke(img, Vector2i(3, 55), Vector2i(19, 39), k)
	_stroke(img, Vector2i(3, 357), Vector2i(20, 339), k)
	_stroke(img, Vector2i(636, 357), Vector2i(619, 339), k)
	_speck(img, 440, 28, 5, 3)
	_speck(img, 596, 330, 5, 3)
	return img


func _under_top_hud(x: int) -> bool:
	for s: Vector2i in HUD_TOP_SPANS:
		if x >= s.x and x <= s.y:
			return true
	return false


## Queimado: INK irregular por fora, 2 px INK_SOFT e 2 px PARCHMENT_OLD; total ≤ 14 px.
func _burn_edge(img: Image, edge: int, rng: RandomNumberGenerator) -> void:
	var length: int = W if edge % 2 == 0 else H
	var s: int = 0
	var depth: int = 6
	while s < length:
		var run: int = rng.randi_range(6, 16)
		depth = clampi(depth + (2 if rng.randf() < 0.5 else -2), 3, 10)
		for t: int in range(s, mini(length, s + run)):
			var ink: int = depth
			if edge == 0 and _under_top_hud(t):
				ink = 1
			for d: int in ink + 4:
				var c: Color = K if d < ink else (k if d < ink + 2 else O)
				match edge:
					0: _px(img, t, d, c)
					1: _px(img, W - 1 - d, t, c)
					2: _px(img, t, H - 1 - d, c)
					_: _px(img, d, t, c)
		s += run


func _stage_3() -> Image:
	var img := _page()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + 3
	for edge: int in 4:
		_burn_edge(img, edge, rng)
	# Cantos chamuscados: triângulo em degraus (21 embaixo, 7 em cima).
	for corner: Vector2i in [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 0)]:
		var size: int = 21 if corner.y == 1 else 7
		for y: int in size:
			for x: int in size - y:
				var dist: int = x + y
				var c: Color = K if dist < size * 0.6 else (k if dist < size * 0.8 else O)
				_px(img, x if corner.x == 0 else W - 1 - x, y if corner.y == 0 else H - 1 - y, c)
	# Línguas baixas dentro da área jogável.
	for base: Vector2i in [Vector2i(24, 330), Vector2i(610, 330)]:
		for r: int in 6:
			var w: int = 6 - r
			var x0: int = base.x if base.x < 320 else base.x + r
			_rect(img, x0, base.y + r, w, 1, O)
	return img


# --- Peças --------------------------------------------------------------------------------

func _from_map(rows: Array[String]) -> Image:
	var colors: Dictionary = {"K": K, "k": k, "O": O, "P": P, "C": C}
	var img := Image.create(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)
	for y: int in rows.size():
		for x: int in rows[y].length():
			var ch: String = rows[y][x]
			if colors.has(ch):
				img.set_pixel(x, y, colors[ch])
	return img


func _hole() -> Image:
	var rows: Array[String] = [
		"....OOOOCCCC....",
		"..OOKKKKKKKKCC..",
		".OkkKKKKKKKKKKC.",
		".OkkKKKKKKKKKKC.",
	]
	for i: int in 4:
		rows.append("OkkKKKKKKKKKKKKC")
	for i: int in 4:
		rows.append("OkkKKKKKKKKKKKKO")
	rows.append_array([
		".OkkKKKKKKKKKKO.",
		".OkkKKKKKKKKKKO.",
		"..OOKKKKKKKKOO..",
		"....OOOOOOOO....",
	])
	return _from_map(rows)


func _bench() -> Image:
	var top: String = "KK" + "O".repeat(27) + "CKK"
	var plank: String = "KK" + "k".repeat(28) + "KK"
	var line: String = "K".repeat(32)
	var rows: Array[String] = [line, top, plank, plank, line, top, plank, line]
	return _from_map(rows)


## Vitral 20×40: arco ogival em degraus, contorno de 2 px, chumbo de 1 px, vidros lisos.
func _window() -> Image:
	var img := Image.create(20, 40, false, Image.FORMAT_RGBA8)
	var arch: Array[int] = [4, 8, 12, 16, 18, 20]
	var inside := func(x: int, y: int) -> bool:
		if x < 0 or y < 0 or x >= 20 or y >= 40:
			return false
		var w: int = arch[y] if y < arch.size() else 20
		return x >= (20 - w) / 2 and x < (20 + w) / 2
	for y: int in 40:
		for x: int in 20:
			if not inside.call(x, y):
				continue
			var edge: bool = false
			for d: Vector2i in [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2), Vector2i(0, 2), Vector2i(-1, -1), Vector2i(1, -1)]:
				if not inside.call(x + d.x, y + d.y):
					edge = true
			var c: Color
			if y >= 38:
				c = k  # peitoril
			elif edge:
				c = K
			elif y < 8:
				c = k if x >= 8 and x <= 11 and y >= 3 and y <= 6 else O  # rosácea no arco
			elif x == 9 or (y - 8) % 8 == 7:
				c = K  # chumbo
			else:
				c = O if x < 9 else C
			img.set_pixel(x, y, c)
	return img


func _altar() -> Image:
	var img := _solid(Vector2i(60, 16), K)
	_rect(img, 1, 1, 58, 14, O)
	_rect(img, 20, 1, 20, 14, C)
	_rect(img, 1, 1, 58, 1, C)
	_rect(img, 58, 1, 1, 14, C)
	_rect(img, 15, 2, 1, 13, k)
	_rect(img, 44, 2, 1, 13, k)
	_rect(img, 20, 13, 20, 2, k)
	_rect(img, 29, 3, 2, 10, k)
	_rect(img, 26, 5, 8, 2, k)
	return img


func _solid(size: Vector2i, c: Color) -> Image:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return img


func _silhouette(src: Image, c: Color) -> Image:
	var img := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
	for y: int in src.get_height():
		for x: int in src.get_width():
			if src.get_pixel(x, y).a > 0.5:
				img.set_pixel(x, y, c)
	return img


## Brasa 4×4 em 4 quadros (tira 16×4): cheia, esfriando, fria, apagando.
func _ember() -> Image:
	var img := Image.create(16, 4, false, Image.FORMAT_RGBA8)
	for f: int in 4:
		var ox: int = f * 4
		if f == 3:
			_rect(img, ox + 1, 1, 2, 1, k)
			continue
		_rect(img, ox + 1, 0, 2, 4, k)
		_rect(img, ox, 1, 4, 2, k)
		var core: Array[Color] = [C, C, C, C]
		if f == 1:
			core = [C, k, k, O]
		elif f == 2:
			core = [O, O, O, O]
		_px(img, ox + 1, 1, core[0])
		_px(img, ox + 2, 1, core[1])
		_px(img, ox + 1, 2, core[2])
		_px(img, ox + 2, 2, core[3])
	return img


func _save(img: Image, name: String) -> void:
	img.save_png(OUT + name + ".png")
