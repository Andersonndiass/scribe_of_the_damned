class_name CutsceneCloses
extends RefCounted
## Closes das cutscenes em CAMADAS (feedback do autor: "sprites separados, juntados na cena"), 192×192
## (D-074; ficha T810; art bible §3 e §12). Cada rosto é uma pilha de camadas com fundo transparente —
## base (fundo, roupa, cabeça, cabelo/barba, contorno) + expressão (olhos, sobrancelhas, boca, detalhes)
## — montadas na cena pelo CloseView. Trocar de expressão troca só as camadas de expressão.
## Arte importada: um PNG por camada em `art_dir` do `speakers.json` (`<camada>.png` na base e
## `<camada>_<expressão>.png` na expressão, gerados com `tools/import_art.gd`); a camada que não tiver
## arquivo usa o placeholder por script (D-024), pintado uma vez (CloseRaster) e guardado em cache.
## Regras de pixel art (D-075/D-076): pele em blocos lisos (CHALK → PARCHMENT → PARCHMENT_OLD →
## INK_SOFT nos vincos), luz da direita, sombra com forma, sem pixel solto.

const SIZE := CloseRaster.SIZE
const ASMODEUS_TEX := preload("res://assets/placeholders/bss_asmodeus_idle.png")
const CLEAR := Color(0, 0, 0, 0)
## Ordem de empilhamento (de baixo para cima).
const BASE_LAYERS: Array[StringName] = [&"fundo", &"roupa", &"cabeca", &"cabelo", &"contorno"]
const EXPRESSION_LAYERS: Array[StringName] = [&"olhos", &"sobrancelhas", &"boca", &"detalhes"]

static var _cache: Dictionary = {}
static var _speakers: Dictionary = {}


## As texturas das camadas, de baixo para cima (camada vazia = null).
static func layers(speaker: String, expr: String) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	if speaker == "asmodeus":
		out.append(_solid(Palette.INK_SOFT))
		out.append(_art_or(speaker, "corpo", func() -> Texture2D: return ASMODEUS_TEX))
		return out
	for layer: StringName in BASE_LAYERS:
		out.append(_layer(speaker, String(layer), ""))
	for layer: StringName in EXPRESSION_LAYERS:
		out.append(_layer(speaker, String(layer), expr))
	return out


## Compatível com quem desenha direto (testes e ferramentas): pinta as camadas em ordem.
static func draw(ci: CanvasItem, o: Vector2, speaker: String, expr: String) -> void:
	for tex: Texture2D in layers(speaker, expr):
		if tex != null:
			ci.draw_texture_rect(tex, Rect2(o, Vector2(SIZE, SIZE)), false)


static func art_dir(speaker: String) -> String:
	if _speakers.is_empty():
		_speakers = CutsceneScript.load_speakers()
	return str((_speakers.get(speaker, {}) as Dictionary).get("art_dir", ""))


static func _art_or(speaker: String, file: String, fallback: Callable) -> Texture2D:
	var dir: String = art_dir(speaker)
	if dir != "":
		var path: String = dir.path_join(file + ".png")
		if ResourceLoader.exists(path):
			return load(path)
	return fallback.call()


static func _layer(speaker: String, layer: String, expr: String) -> Texture2D:
	var file: String = layer if expr == "" else "%s_%s" % [layer, expr]
	var key: String = "%s/%s" % [speaker, file]
	if not _cache.has(key):
		_cache[key] = _art_or(speaker, file, func() -> Texture2D: return _placeholder(speaker, layer, expr))
	return _cache[key]


static func _solid(c: Color) -> Texture2D:
	var key: String = "solid/" + c.to_html()
	if not _cache.has(key):
		var r := CloseRaster.new(c)
		_cache[key] = r.texture()
	return _cache[key]


static func _placeholder(speaker: String, layer: String, expr: String) -> Texture2D:
	match speaker:
		"anselmo":
			return _anselmo_layer(layer, expr)
		"abbot_ghost":
			return _abbot_layer(layer, expr)
	return null


static func _v(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i: int in range(0, points.size(), 2):
		out.append(Vector2(points[i], points[i + 1]))
	return out


## Contorno da silhueta: a união das máscaras das camadas sólidas, numa camada própria.
static func _outline_layer(parts: Array[CloseRaster], c: Color, w: int) -> Texture2D:
	var r := CloseRaster.new(CLEAR)
	for p: CloseRaster in parts:
		for i: int in p.mask.size():
			if p.mask[i] == 1:
				r.mask[i] = 1
	r.outline(c, w)
	return r.texture()


# --- Irmão Anselmo --------------------------------------------------------------------------------

const A_CX := 64.0
const SKIN := Palette.PARCHMENT
const SKIN_SHADE := Palette.PARCHMENT_OLD
const SKIN_LIGHT := Palette.CHALK
const CREASE := Palette.INK_SOFT


## Meia-largura do rosto por linha (crânio oval, queixo afunilando).
static func _anselmo_half(y: float) -> float:
	if y < 26.0 or y > 85.0:
		return -1.0
	if y <= 60.0:
		return 23.0 * sqrt(maxf(0.0, 1.0 - pow((y - 55.0) / 29.0, 2)))
	var t: float = (y - 60.0) / 25.0
	return lerpf(22.6, 8.0, pow(t, 1.4))


## Preenche as linhas do rosto entre `y0` e `y1` onde `pick(x, y, half)` diz sim.
static func _face_fill(r: CloseRaster, y0: int, y1: int, c: Color, pick: Callable) -> void:
	for y: int in range(y0, y1):
		var h: float = _anselmo_half(y)
		if h < 0.0:
			continue
		for x: int in range(int(roundf(A_CX - h)), int(roundf(A_CX + h))):
			if pick.call(x, y, h):
				r.px(x, y, c, 0, true)


static func _anselmo_layer(layer: String, expr: String) -> Texture2D:
	match layer:
		"fundo":
			return _solid(Palette.PARCHMENT_OLD)
		"roupa":
			return _anselmo_roupa().texture()
		"cabeca":
			return _anselmo_cabeca().texture()
		"cabelo":
			return _anselmo_cabelo().texture()
		"contorno":
			return _outline_layer([_anselmo_roupa(), _anselmo_cabeca()], Palette.INK, 3)
		"olhos", "sobrancelhas", "boca", "detalhes":
			var r := CloseRaster.new(CLEAR)
			_anselmo_expression_part(r, layer, expr)
			return r.texture()
	return null


## Hábito e capuz dobrado atrás do pescoço.
static func _anselmo_roupa() -> CloseRaster:
	var r := CloseRaster.new(CLEAR)
	r.polygon(_v([14, 128, 22, 106, 42, 97, 86, 97, 106, 106, 114, 128]), Palette.INK_SOFT, 0, true)
	r.polygon(_v([14, 128, 22, 106, 42, 97, 50, 97, 44, 110, 40, 128]), Palette.INK)
	r.path(_v([56, 112, 55, 128]), Palette.INK)
	r.path(_v([84, 110, 86, 128]), Palette.INK)
	r.path(_v([100, 104, 106, 114, 110, 128]), Palette.PARCHMENT_OLD)
	r.polygon(_v([32, 100, 40, 90, 52, 94, 64, 96, 76, 94, 88, 90, 96, 100, 88, 108, 64, 112, 40, 108]), Palette.INK_SOFT, 0, true)
	r.polygon(_v([34, 102, 64, 106, 94, 102, 88, 108, 64, 112, 40, 108]), Palette.INK)
	r.polygon(_v([32, 100, 40, 90, 48, 93, 44, 104]), Palette.INK)
	r.path(_v([72, 94, 80, 92, 88, 91, 94, 97]), Palette.PARCHMENT_OLD)
	r.path(_v([60, 97, 62, 105]), Palette.INK)
	return r


## Pescoço, orelhas, rosto, coroa careca, nariz e a sombra das órbitas (o crânio igual em tudo).
static func _anselmo_cabeca() -> CloseRaster:
	var r := CloseRaster.new(CLEAR)
	r.rect(56, 80, 16, 17, SKIN_SHADE, 0, true)
	r.rect(66, 86, 5, 11, SKIN)
	r.ellipse(40, 59, 4, 8, SKIN_SHADE, 0, true)
	r.ellipse(88, 59, 4, 8, SKIN, 0, true)
	r.path(_v([89, 55, 90, 59, 89, 63]), CREASE)
	_face_fill(r, 26, 86, SKIN, func(_x: int, _y: int, _h: float) -> bool: return true)
	_face_fill(r, 44, 86, SKIN_SHADE, func(x: int, _y: int, h: float) -> bool: return x < A_CX - h * 0.55)
	_face_fill(r, 80, 86, SKIN_SHADE, func(_x: int, _y: int, _h: float) -> bool: return true)
	r.polygon(_v([47, 64, 54, 66, 58, 72, 50, 72]), SKIN_SHADE)
	r.rect(74, 61, 6, 2, SKIN_LIGHT)
	r.rect(70, 38, 5, 2, SKIN_LIGHT)
	r.ellipse(64.5, 31, 13, 6, SKIN)
	r.polygon(_v([52, 31, 56, 27, 58, 28, 55, 33]), SKIN_SHADE)
	r.rect(69, 28, 4, 2, SKIN_LIGHT)
	r.polygon(_v([62, 55, 62, 66, 57, 69, 59, 64]), SKIN_SHADE)
	r.rect(58, 69, 9, 2, SKIN_SHADE)
	r.rect(59, 68, 2, 1, CREASE)
	r.rect(65, 68, 2, 1, CREASE)
	r.rect(65, 60, 1, 4, SKIN_LIGHT)
	r.rect(48, 51, 11, 2, SKIN_SHADE)
	r.rect(70, 51, 11, 2, SKIN_SHADE)
	return r


## Cabelo da tonsura: massa INK_SOFT com franja em degraus, bloco de sombra à esquerda e de luz à direita.
static func _anselmo_cabelo() -> CloseRaster:
	var r := CloseRaster.new(CLEAR)
	for y: int in range(26, 58):
		var h: float = _anselmo_half(y)
		if h < 0.0:
			continue
		for x: int in range(int(roundf(A_CX - h)), int(roundf(A_CX + h))):
			var crown: bool = pow((x - 64.5) / 13.0, 2) + pow((y - 31.0) / 6.0, 2) <= 1.0
			var fringe: int = 44 + (1 if (x / 4) % 2 == 0 else 0)
			var side: bool = y > fringe and absf(x + 0.5 - A_CX) > h - 4.0 and y < 56
			if (not crown and y <= fringe) or side:
				r.px(x, y, Palette.INK_SOFT)
	r.polygon(_v([42, 40, 48, 34, 52, 36, 48, 45, 43, 50]), Palette.INK)
	r.polygon(_v([76, 36, 82, 36, 86, 42, 84, 45, 79, 41]), Palette.PARCHMENT_OLD)
	return r


## Olho simples: branco, íris escura com 1 brilho, pálpebra de cima como traço. `drop` baixa a
## pálpebra (cobre o topo); `open` é a altura do branco.
static func _eye(r: CloseRaster, cx: int, cy: int, open: int, iris_w: int, drop: int) -> void:
	var x0: int = cx - 4
	var top: int = cy - open / 2
	r.rect(x0, top, 8, open, SKIN_LIGHT)
	r.rect(cx - iris_w / 2, top, iris_w, open, Palette.INK)
	r.rect(cx - iris_w / 2 + iris_w - 1, top + (1 if open > 2 else 0), 1, 1, SKIN_LIGHT)
	r.rect(x0 - 1, top - 1, 10, 1 + drop, Palette.INK)
	if drop > 0:
		r.rect(x0 - 1, top - 1, 10, drop, SKIN)
		r.rect(x0 - 1, top - 1 + drop, 10, 1, Palette.INK)


static func _anselmo_expression_part(r: CloseRaster, part: String, expr: String) -> void:
	match expr:
		"scared":
			match part:
				"olhos":
					_eye(r, 53, 57, 5, 2, 0)
					_eye(r, 75, 57, 5, 2, 0)
				"sobrancelhas":
					r.polygon(_v([46, 49, 52, 47, 59, 44, 59, 46, 52, 49, 46, 51]), Palette.INK)
					r.polygon(_v([82, 49, 76, 47, 69, 44, 69, 46, 76, 49, 82, 51]), Palette.INK)
				"boca":
					r.rect(62, 74, 4, 4, Palette.INK)
					r.rect(61, 75, 1, 2, Palette.INK)
					r.rect(66, 75, 1, 2, Palette.INK)
					r.rect(61, 79, 6, 1, SKIN_SHADE)
				"detalhes":
					r.polygon(_v([85, 44, 87, 47, 87, 49, 84, 49, 84, 47]), SKIN_LIGHT)
					r.rect(84, 49, 3, 1, CREASE)
		"relieved":
			match part:
				"olhos":
					_eye(r, 53, 58, 3, 3, 1)
					_eye(r, 75, 58, 3, 3, 1)
				"sobrancelhas":
					r.polygon(_v([46, 48, 52, 46, 59, 47, 59, 49, 52, 48, 46, 50]), Palette.INK)
					r.polygon(_v([69, 47, 76, 46, 82, 48, 82, 50, 76, 48, 69, 49]), Palette.INK)
				"boca":
					r.path(_v([58, 75, 60, 76, 66, 76, 69, 74]), Palette.INK)
					r.rect(61, 78, 6, 1, SKIN_SHADE)
		_:  # determined
			match part:
				"olhos":
					_eye(r, 53, 58, 3, 3, 0)
					_eye(r, 75, 58, 3, 3, 0)
				"sobrancelhas":
					r.polygon(_v([45, 45, 52, 47, 59, 50, 59, 53, 52, 50, 45, 48]), Palette.INK)
					r.polygon(_v([83, 45, 76, 47, 69, 50, 69, 53, 76, 50, 83, 48]), Palette.INK)
					r.rect(64, 49, 1, 3, CREASE)
				"boca":
					r.rect(58, 76, 12, 2, Palette.INK)
					r.rect(57, 77, 1, 1, Palette.INK)
					r.rect(70, 77, 1, 1, Palette.INK)
					r.rect(60, 79, 8, 2, SKIN_SHADE)


# --- Abade Gerbrand (fantasma) --------------------------------------------------------------------

static func _abbot_layer(layer: String, expr: String) -> Texture2D:
	match layer:
		"fundo":
			return _solid(Palette.INK_SOFT)
		"roupa":
			return _abbot_roupa().texture()
		"cabeca":
			return _abbot_rosto().texture()
		"cabelo":
			return _abbot_barba().texture()
		"contorno":
			return _outline_layer([_abbot_roupa(), _abbot_barba()], Palette.CHALK, 3)
		"olhos", "sobrancelhas", "boca", "detalhes":
			var r := CloseRaster.new(CLEAR)
			_abbot_expression_part(r, layer, expr)
			return r.texture()
	return null


## Capa e capuz de fantasma: xadrez (a transparência dos fantasmas), mais denso no lado da luz.
static func _abbot_roupa() -> CloseRaster:
	var r := CloseRaster.new(CLEAR)
	r.polygon(_v([6, 128, 14, 104, 38, 94, 90, 94, 114, 104, 122, 128]), Palette.CHALK, 1, true)
	r.polygon(_v([64, 94, 90, 94, 114, 104, 122, 128, 64, 128]), Palette.CHALK, 2)
	r.path(_v([40, 100, 36, 128]), Palette.CHALK)
	r.path(_v([88, 100, 92, 128]), Palette.CHALK)
	r.polygon(_v([64, 4, 74, 16, 86, 40, 96, 70, 104, 98, 24, 98, 32, 70, 42, 40, 54, 16]), Palette.CHALK, 1, true)
	r.polygon(_v([64, 4, 74, 16, 86, 40, 96, 70, 104, 98, 64, 98]), Palette.CHALK, 2)
	r.path(_v([66, 12, 80, 44, 92, 94]), Palette.CHALK)
	return r


## O fundo escuro do capuz e o rosto velho em tinta clara sólida, com sombras em bloco.
static func _abbot_rosto() -> CloseRaster:
	var r := CloseRaster.new(CLEAR)
	var dark := Palette.INK_SOFT
	r.ellipse(64, 60, 21, 28, Palette.INK)
	r.ellipse(65, 60, 16, 23, Palette.CHALK)
	r.polygon(_v([50, 50, 54, 44, 56, 60, 55, 76, 52, 72]), Palette.PARCHMENT_OLD)
	r.rect(53, 52, 10, 2, Palette.PARCHMENT_OLD)
	r.rect(68, 52, 10, 2, Palette.PARCHMENT_OLD)
	r.polygon(_v([55, 64, 59, 66, 58, 72, 55, 70]), Palette.PARCHMENT_OLD)
	r.polygon(_v([76, 64, 72, 66, 73, 71, 76, 69]), Palette.PARCHMENT_OLD)
	r.rect(59, 44, 12, 1, dark)
	r.rect(61, 47, 8, 1, dark)
	r.rect(54, 61, 6, 1, Palette.PARCHMENT_OLD)
	r.rect(71, 61, 6, 1, Palette.PARCHMENT_OLD)
	r.polygon(_v([63, 56, 63, 68, 59, 71, 61, 64]), Palette.PARCHMENT_OLD)
	r.rect(61, 70, 2, 1, dark)
	r.rect(66, 70, 2, 1, dark)
	return r


## Bigode e barba longa: massa clara, lado da sombra em bloco, poucos fios longos.
static func _abbot_barba() -> CloseRaster:
	var r := CloseRaster.new(CLEAR)
	r.polygon(_v([50, 74, 56, 72, 64, 74, 72, 72, 80, 74, 80, 88, 74, 104, 64, 120, 54, 104, 50, 88]), Palette.CHALK, 0, true)
	r.polygon(_v([50, 74, 56, 73, 58, 90, 60, 110, 54, 104, 50, 88]), Palette.PARCHMENT_OLD)
	r.polygon(_v([52, 76, 58, 73, 64, 76, 70, 73, 77, 76, 72, 79, 64, 78, 56, 79]), Palette.CHALK)
	r.rect(56, 79, 16, 1, Palette.PARCHMENT_OLD)
	r.path(_v([64, 84, 64, 112]), Palette.PARCHMENT_OLD)
	r.path(_v([70, 84, 71, 100]), Palette.PARCHMENT_OLD)
	return r


static func _abbot_expression_part(r: CloseRaster, part: String, expr: String) -> void:
	var dark := Palette.INK_SOFT
	var smiling: bool = expr == "smiling"
	match part:
		"sobrancelhas":
			# Brancas e fartas, caídas para fora (tristeza).
			r.polygon(_v([51, 50, 56, 48, 61, 49, 61, 51, 56, 50, 52, 52]), Palette.CHALK)
			r.polygon(_v([69, 49, 74, 48, 79, 50, 78, 52, 74, 50, 69, 51]), Palette.CHALK)
			r.rect(51, 51, 10, 1, Palette.PARCHMENT_OLD)
			r.rect(69, 51, 10, 1, Palette.PARCHMENT_OLD)
		"olhos":
			if smiling:
				r.polygon(_v([53, 58, 56, 56, 59, 58, 58, 59, 56, 57, 54, 59]), dark)
				r.polygon(_v([71, 58, 74, 56, 77, 58, 76, 59, 74, 57, 72, 59]), dark)
			else:
				r.rect(53, 56, 7, 2, dark)
				r.rect(71, 56, 7, 2, dark)
				r.rect(52, 57, 1, 1, dark)
				r.rect(78, 57, 1, 1, dark)
				r.rect(56, 58, 2, 2, dark)
				r.rect(73, 58, 2, 2, dark)
		"boca":
			if smiling:
				r.path(_v([60, 80, 63, 81, 67, 81, 70, 79]), dark)
			else:
				r.path(_v([60, 81, 63, 80, 67, 80, 70, 81]), dark)
