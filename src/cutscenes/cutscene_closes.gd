class_name CutsceneCloses
extends RefCounted
## Closes das cutscenes, 192×192 (D-074; ficha T810 + art bible §4 e §12). Se o arquivo do close
## existir (`speakers.json`, gerado com `tools/import_art.gd`), usa a arte; senão, o placeholder por
## script (D-024), pintado uma vez numa Image (CloseRaster) e guardado como textura. Sombra por hachura (cruzada
## no close; luz da direita, sombra à esquerda); contorno de 2 px. O crânio é o mesmo em todas as
## expressões; só olhos, sobrancelhas e boca mudam. O Abade é o Abade vivo (rosto humano e triste)
## com o "filtro fantasma": tinta clara (CHALK em xadrez) sobre INK_SOFT.

const SIZE := CloseRaster.SIZE
const ASMODEUS_TEX := preload("res://assets/placeholders/bss_asmodeus_idle.png")

static var _cache: Dictionary = {}
static var _speakers: Dictionary = {}


static func draw(ci: CanvasItem, o: Vector2, speaker: String, expr: String) -> void:
	var tex: Texture2D = texture(speaker, expr)
	if speaker == "asmodeus":
		ci.draw_rect(Rect2(o, Vector2(SIZE, SIZE)), Palette.INK_SOFT)
	if tex != null:
		ci.draw_texture_rect(tex, Rect2(o, Vector2(SIZE, SIZE)), false)


static func texture(speaker: String, expr: String) -> Texture2D:
	var art: String = art_path(speaker, expr)
	if art != "" and ResourceLoader.exists(art):
		return load(art)
	if speaker == "asmodeus":
		return ASMODEUS_TEX
	var key: String = speaker + "/" + expr
	if not _cache.has(key):
		match speaker:
			"anselmo":
				_cache[key] = _anselmo(expr).texture()
			"abbot_ghost":
				_cache[key] = _abbot_ghost(expr).texture()
			_:
				return null
	return _cache[key]


## Caminho da arte do close em `speakers.json` ("" = só placeholder).
static func art_path(speaker: String, expr: String) -> String:
	if _speakers.is_empty():
		_speakers = CutsceneScript.load_speakers()
	return str(((_speakers.get(speaker, {}) as Dictionary).get("closes", {}) as Dictionary).get(expr, ""))


static func _v(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i: int in range(0, points.size(), 2):
		out.append(Vector2(points[i], points[i + 1]))
	return out


# --- Irmão Anselmo --------------------------------------------------------------------------------

const A_CX := 64
## Meia-largura do rosto por linha (crânio oval, queixo afunilando).
static func _anselmo_half(y: float) -> float:
	if y < 26 or y > 85:
		return -1.0
	if y <= 60:
		return 23.0 * sqrt(maxf(0.0, 1.0 - pow((y - 55.0) / 29.0, 2)))
	var t: float = (y - 60.0) / 25.0
	return lerpf(22.6, 8.0, pow(t, 1.4))


static func _in_face(x: float, y: float) -> bool:
	var h: float = _anselmo_half(y)
	return h >= 0.0 and absf(x + 0.5 - A_CX) <= h


static func _anselmo(expr: String) -> CloseRaster:
	var r := CloseRaster.new(Palette.PARCHMENT_OLD)
	# Hábito (ombros) e o capuz dobrado atrás do pescoço.
	var habit: PackedVector2Array = _v([14, 128, 22, 106, 42, 97, 86, 97, 106, 106, 114, 128])
	r.polygon(habit, Palette.INK_SOFT, 0, true)
	r.hatch(Rect2i(14, 97, 40, 31), func(x: float, y: float) -> bool: return Geometry2D.is_point_in_polygon(Vector2(x, y), habit), 45, 3, Palette.INK)
	r.hatch(Rect2i(14, 108, 22, 20), func(x: float, y: float) -> bool: return Geometry2D.is_point_in_polygon(Vector2(x, y), habit), 135, 3, Palette.INK)
	r.path(_v([40, 110, 42, 118, 41, 128]), Palette.INK)
	r.path(_v([88, 110, 86, 119, 87, 128]), Palette.INK)
	r.path(_v([64, 112, 64, 128]), Palette.INK)
	r.path(_v([102, 106, 108, 116, 111, 128]), Palette.PARCHMENT_OLD)
	var cowl: PackedVector2Array = _v([32, 100, 40, 90, 52, 94, 64, 96, 76, 94, 88, 90, 96, 100, 88, 108, 64, 112, 40, 108])
	r.polygon(cowl, Palette.INK_SOFT, 0, true)
	r.path(_v([36, 99, 44, 104, 54, 107, 64, 108, 74, 107, 84, 104, 92, 99]), Palette.INK)
	r.path(_v([44, 94, 48, 100, 50, 106]), Palette.INK)
	r.path(_v([84, 94, 80, 100, 79, 106]), Palette.INK)
	r.path(_v([56, 97, 58, 103]), Palette.INK)
	r.path(_v([72, 97, 70, 103]), Palette.INK)
	r.path(_v([76, 93, 86, 91, 93, 97]), Palette.PARCHMENT_OLD)
	r.hatch(Rect2i(32, 90, 20, 20), func(x: float, y: float) -> bool: return Geometry2D.is_point_in_polygon(Vector2(x, y), cowl), 45, 3, Palette.INK)
	# Pescoço (sombra do queixo cruzada).
	r.rect(55, 80, 18, 16, Palette.PARCHMENT, 0, true)
	r.hatch(Rect2i(55, 80, 8, 16), func(_x: float, _y: float) -> bool: return true, 135, 3, Palette.INK_SOFT)
	r.hatch(Rect2i(55, 80, 18, 6), func(_x: float, _y: float) -> bool: return true, 45, 3, Palette.INK_SOFT)
	# Orelhas.
	for side: int in [-1, 1]:
		var ex: int = A_CX + side * 24
		r.ellipse(ex, 59, 4, 8, Palette.PARCHMENT, 0, true)
		r.path(_v([ex - side, 54, ex + side * 2, 57, ex + side, 63, ex - side, 65]), Palette.INK_SOFT)
	r.hatch(Rect2i(36, 50, 8, 18), func(x: float, y: float) -> bool: return Vector2(x, y).distance_to(Vector2(40, 59)) < 8.0, 135, 2, Palette.INK_SOFT)
	# Rosto.
	for y: int in range(26, 86):
		var h: float = _anselmo_half(y)
		if h >= 0.0:
			for x: int in range(int(roundf(A_CX - h)), int(roundf(A_CX + h))):
				r.px(x, y, Palette.PARCHMENT, 0, true)
	# Sombra do rosto (esquerda) em hachura cruzada; mais funda no queixo.
	r.hatch(Rect2i(40, 46, 16, 40), func(x: float, y: float) -> bool: return _in_face(x, y) and x < A_CX - _anselmo_half(y) * 0.62, 135, 4, Palette.INK_SOFT)
	r.hatch(Rect2i(44, 72, 16, 14), func(x: float, y: float) -> bool: return _in_face(x, y) and x < A_CX - _anselmo_half(y) * 0.3, 45, 4, Palette.INK_SOFT)
	# Maçã do rosto e linha do queixo.
	r.path(_v([45, 64, 48, 69, 52, 72]), Palette.INK_SOFT)
	r.path(_v([60, 83, 68, 83]), Palette.INK_SOFT)
	# Cabelo (anel da tonsura) com fios, franja irregular e costeletas.
	for y: int in range(26, 48):
		var h: float = _anselmo_half(y)
		for x: int in range(int(roundf(A_CX - h)), int(roundf(A_CX + h))):
			var crown: bool = pow((x - 64.5) / 13.0, 2) + pow((y - 31.0) / 6.0, 2) <= 1.0
			var fringe_end: int = 44 + (2 if x % 5 == 0 else (1 if x % 3 == 0 else 0))
			if not crown and y <= fringe_end:
				r.px(x, y, Palette.INK_SOFT)
	for y: int in range(44, 58):
		var h: float = _anselmo_half(y)
		for x: int in range(int(roundf(A_CX - h)), int(roundf(A_CX + h))):
			if absf(x + 0.5 - A_CX) > h - 4.0:
				r.px(x, y, Palette.INK_SOFT)
	# Fios verticais: só onde já é cabelo; o lado da sombra mais escuro.
	r.hatch(Rect2i(40, 28, 48, 30), func(x: float, y: float) -> bool: return _in_face(x, y) and r.color_at(x, y).is_equal_approx(Palette.INK_SOFT), 90, 3, Palette.INK)
	r.hatch(Rect2i(40, 32, 13, 26), func(x: float, y: float) -> bool: return _in_face(x, y) and r.color_at(x, y).is_equal_approx(Palette.INK_SOFT), 45, 2, Palette.INK)
	# Coroa careca com brilho (luz da direita).
	r.ellipse(64.5, 31, 13, 6, Palette.PARCHMENT)
	r.px(70, 28, Palette.CHALK)
	r.px(71, 28, Palette.CHALK)
	r.px(72, 29, Palette.CHALK)
	r.px(73, 30, Palette.CHALK)
	r.path(_v([52, 33, 57, 36, 64, 37, 71, 36, 77, 33]), Palette.INK_SOFT)
	# Nariz: dorso na sombra, ponta, narinas e brilho.
	r.path(_v([61, 56, 60, 62, 59, 67]), Palette.INK_SOFT)
	r.path(_v([58, 68, 60, 70, 64, 70, 68, 69]), Palette.INK)
	r.px(59, 69, Palette.INK)
	r.px(66, 69, Palette.INK)
	r.px(66, 62, Palette.CHALK)
	r.px(66, 63, Palette.CHALK)
	r.hatch(Rect2i(57, 70, 10, 3), func(_x: float, _y: float) -> bool: return true, 135, 2, Palette.INK_SOFT)
	_anselmo_expression(r, expr)
	r.outline(Palette.INK, 3)
	return r


## Olho: branco, íris com pupila e brilho, pálpebra de cima (espessura `lid`) e de baixo.
## `open`: altura do branco; `look`: desvio da íris; `lid_drop`: a pálpebra cobre o topo da íris.
static func _eye(r: CloseRaster, cx: int, cy: int, open: int, iris: int, lid: int, lid_drop: int, outer_down: int, side: int) -> void:
	var w: int = 10
	var x0: int = cx - w / 2
	var top: int = cy - open / 2
	r.rect(x0 + 1, top, w - 2, open, Palette.CHALK)
	r.rect(x0, top + 1, w, maxi(open - 2, 1), Palette.CHALK)
	var ix: int = cx - iris / 2
	var iy: int = cy - iris / 2 + (1 if open <= 4 else 0)
	r.rect(ix, iy, iris, iris, Palette.INK_SOFT)
	var p: int = maxi(1, iris / 2)
	r.rect(cx - p / 2, cy - p / 2 + (1 if open <= 4 else 0), p, p, Palette.INK)
	r.px(ix + iris - 1, iy, Palette.CHALK)
	# Pálpebra de cima: cobre `lid_drop` px do topo e cai `outer_down` px no canto de fora.
	for i: int in w + 2:
		var x: int = x0 - 1 + i
		var from_outer: float = float(i) / (w + 1) if side < 0 else 1.0 - float(i) / (w + 1)
		var drop: int = int(roundf(outer_down * (1.0 - from_outer)))
		r.rect(x, top - lid + lid_drop + drop, 1, lid, Palette.INK)
		if lid_drop + drop > 0:
			r.rect(x, top, 1, lid_drop + drop, Palette.PARCHMENT)
			r.rect(x, top - lid + lid_drop + drop, 1, lid, Palette.INK)
	# Pálpebra de baixo e a olheira.
	r.line(Vector2(x0 + 1, top + open), Vector2(x0 + w - 2, top + open), Palette.INK_SOFT)
	r.line(Vector2(x0 + 2, top + open + 3), Vector2(x0 + w - 3, top + open + 3), Palette.INK_SOFT)


static func _anselmo_expression(r: CloseRaster, expr: String) -> void:
	var lx: int = 53
	var rx: int = 75
	var ey: int = 57
	match expr:
		"scared":
			_eye(r, lx, ey, 7, 3, 2, 0, 0, -1)
			_eye(r, rx, ey, 7, 3, 2, 0, 0, 1)
			# Sobrancelhas erguidas no meio (preocupação) e rugas de medo na testa.
			r.path(_v([46, 48, 51, 47, 56, 45, 58, 44]), Palette.INK, 2)
			r.path(_v([82, 48, 77, 47, 72, 45, 70, 44]), Palette.INK, 2)
			r.path(_v([56, 40, 60, 39, 64, 40, 68, 39, 72, 40]), Palette.INK_SOFT)
			# Boca aberta: fundo INK, dentes CHALK, lábio de baixo na luz.
			r.ellipse(64, 77, 3.5, 4, Palette.INK)
			r.rect(62, 74, 5, 1, Palette.CHALK)
			r.path(_v([60, 81, 64, 82, 68, 81]), Palette.INK_SOFT)
			# Gota de suor na têmpora (lado da luz).
			r.rect(84, 44, 2, 1, Palette.CHALK)
			r.rect(83, 45, 4, 3, Palette.CHALK)
			r.px(83, 47, Palette.INK_SOFT)
			r.px(86, 47, Palette.INK_SOFT)
			r.rect(84, 48, 2, 1, Palette.INK_SOFT)
		"relieved":
			_eye(r, lx, ey, 5, 3, 2, 2, 1, -1)
			_eye(r, rx, ey, 5, 3, 2, 2, 1, 1)
			# Sobrancelhas soltas (arco suave), bochechas levantadas, sorriso de canto.
			r.path(_v([46, 49, 50, 47, 55, 47, 59, 48]), Palette.INK, 2)
			r.path(_v([69, 48, 73, 47, 78, 47, 82, 49]), Palette.INK, 2)
			r.path(_v([47, 66, 50, 68]), Palette.INK_SOFT)
			r.path(_v([81, 66, 78, 68]), Palette.INK_SOFT)
			r.path(_v([58, 75, 61, 77, 66, 77, 70, 74]), Palette.INK)
			r.path(_v([61, 79, 67, 79]), Palette.INK_SOFT)
		_:  # determined
			_eye(r, lx, ey, 5, 4, 3, 1, 0, -1)
			_eye(r, rx, ey, 5, 4, 3, 1, 0, 1)
			# Sobrancelhas grossas descendo para o centro; ruga entre elas; boca firme.
			r.path(_v([45, 46, 50, 47, 55, 49, 59, 51]), Palette.INK, 3)
			r.path(_v([83, 46, 78, 47, 73, 49, 69, 51]), Palette.INK, 3)
			r.path(_v([63, 47, 63, 52]), Palette.INK_SOFT)
			r.path(_v([57, 77, 60, 76, 68, 76, 71, 77]), Palette.INK, 2)
			r.path(_v([60, 80, 68, 80]), Palette.INK_SOFT)
			r.hatch(Rect2i(46, 72, 12, 12), func(x: float, y: float) -> bool: return _in_face(x, y), 135, 2, Palette.INK_SOFT)


# --- Abade Gerbrand (fantasma) --------------------------------------------------------------------

static func _abbot_ghost(expr: String) -> CloseRaster:
	var r := CloseRaster.new(Palette.INK_SOFT)
	var ink := Palette.INK_SOFT
	# Capa nos ombros: tinta clara, mais densa no lado da luz (direita).
	var cape: PackedVector2Array = _v([6, 128, 14, 104, 38, 94, 90, 94, 114, 104, 122, 128])
	r.polygon(cape, Palette.CHALK, 2, true)
	r.polygon(_v([64, 94, 90, 94, 114, 104, 122, 128, 64, 128]), Palette.CHALK, 3)
	for fold: PackedVector2Array in [_v([30, 100, 26, 114, 24, 128]), _v([46, 98, 44, 114, 46, 128]), _v([82, 98, 84, 114, 82, 128]), _v([100, 102, 104, 116, 106, 128])]:
		r.path(fold, Palette.CHALK)
	# Capuz pontudo, com pregas; o lado da sombra é mais ralo.
	var hood: PackedVector2Array = _v([64, 4, 74, 16, 86, 40, 96, 70, 104, 98, 24, 98, 32, 70, 42, 40, 54, 16])
	r.polygon(hood, Palette.CHALK, 1, true)
	r.polygon(_v([64, 4, 74, 16, 86, 40, 96, 70, 104, 98, 64, 98]), Palette.CHALK, 2)
	for fold: PackedVector2Array in [_v([60, 14, 50, 40, 40, 70, 34, 96]), _v([68, 14, 78, 40, 88, 70, 96, 96]), _v([56, 30, 48, 60]), _v([72, 30, 82, 62])]:
		r.path(fold, Palette.CHALK)
	# Abertura do rosto: sombra funda do capuz.
	r.ellipse(64, 60, 21, 28, ink)
	r.ellipse(64, 60, 20, 27, Palette.INK)
	r.hatch(Rect2i(44, 32, 40, 56), func(x: float, y: float) -> bool: return pow((x - 64) / 20.0, 2) + pow((y - 60) / 27.0, 2) <= 1.0, 45, 3, ink)
	# Rosto humano, velho e triste: tinta clara (75%), traços em INK_SOFT sólido.
	r.ellipse(65, 60, 16, 23, Palette.CHALK)
	r.hatch(Rect2i(48, 40, 9, 36), func(x: float, y: float) -> bool: return pow((x - 65) / 16.0, 2) + pow((y - 60) / 23.0, 2) <= 1.0 and x < 57, 135, 3, ink)
	# Rugas da testa.
	r.path(_v([56, 44, 60, 43, 66, 43, 72, 44]), ink)
	r.path(_v([58, 47, 63, 46, 69, 46, 73, 47]), ink)
	# Sobrancelhas brancas e fartas, caídas para fora (tristeza).
	r.path(_v([51, 51, 55, 49, 60, 50]), Palette.CHALK, 3)
	r.path(_v([70, 50, 75, 49, 79, 51]), Palette.CHALK, 3)
	r.path(_v([50, 54, 52, 53]), Palette.CHALK)
	r.path(_v([80, 53, 81, 54]), Palette.CHALK)
	if expr == "smiling":
		# Olhos apertados num sorriso que esconde algo; pés de galinha.
		r.path(_v([53, 58, 56, 56, 59, 58]), ink, 2)
		r.path(_v([71, 58, 74, 56, 77, 58]), ink, 2)
		r.path(_v([50, 57, 48, 56]), ink)
		r.path(_v([50, 59, 48, 60]), ink)
		r.path(_v([80, 57, 82, 56]), ink)
		r.path(_v([80, 59, 82, 60]), ink)
	else:
		# Olhos pesados: pálpebra caída para fora, íris pequena.
		r.path(_v([52, 56, 56, 56, 59, 57]), ink, 2)
		r.path(_v([71, 57, 74, 56, 78, 56]), ink, 2)
		r.rect(55, 58, 2, 2, ink)
		r.rect(73, 58, 2, 2, ink)
	# Bolsas sob os olhos.
	r.path(_v([53, 62, 56, 63, 59, 62]), ink)
	r.path(_v([71, 62, 74, 63, 77, 62]), ink)
	# Nariz longo (dorso na sombra) e bochechas encovadas.
	r.path(_v([63, 56, 62, 63, 61, 70]), ink)
	r.path(_v([60, 71, 63, 72, 67, 71]), ink)
	r.path(_v([53, 66, 55, 72]), ink)
	r.path(_v([78, 66, 76, 72]), ink)
	# Bigode e barba longa em camadas, com fios.
	var beard: PackedVector2Array = _v([50, 74, 56, 72, 64, 74, 72, 72, 80, 74, 80, 88, 74, 104, 64, 120, 54, 104, 50, 88])
	r.polygon(beard, Palette.CHALK, 0, true)
	r.hatch(Rect2i(50, 84, 10, 30), func(x: float, y: float) -> bool: return Geometry2D.is_point_in_polygon(Vector2(x, y), beard), 135, 3, ink)
	r.path(_v([54, 75, 58, 74, 63, 76, 68, 74, 74, 75, 77, 78]), Palette.CHALK, 2)
	if expr == "smiling":
		r.path(_v([59, 79, 62, 80, 68, 80, 71, 78]), ink)
	else:
		r.path(_v([59, 80, 62, 79, 68, 79, 71, 80]), ink)
	for x: int in range(53, 78, 3):
		var bottom: float = 118.0 - absf(x - 64) * 1.6
		r.path(_v([x, 83, x + (1 if x > 64 else -1), (83 + bottom) / 2.0, x, bottom]), ink)
	r.path(_v([50, 88, 56, 104, 64, 120, 72, 104, 80, 88]), Palette.CHALK)
	r.outline(Palette.CHALK, 3)
	return r
