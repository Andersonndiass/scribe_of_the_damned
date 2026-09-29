class_name CutsceneCloses
extends RefCounted
## Closes das cutscenes, 192×192 (D-074; ficha T810; art bible §3 e §12). Se o arquivo do close existir
## (`speakers.json`, gerado com `tools/import_art.gd`), usa a arte; senão, o placeholder por script
## (D-024), pintado uma vez numa Image (CloseRaster) e guardado como textura.
## Regras de pixel art (D-075): pele em blocos lisos, sem hachura nem xadrez — rampa CHALK (luz) →
## PARCHMENT (base) → PARCHMENT_OLD (sombra) → INK_SOFT (vincos); luz da direita; sombras com forma
## definida; poucos traços; nada de pixel solto. O crânio é o mesmo em todas as expressões; só olhos,
## sobrancelhas e boca mudam. O Abade é o Abade vivo (rosto humano e triste) como fantasma: a roupa em
## xadrez (a transparência dos fantasmas, art bible §3), o rosto em tinta clara sólida.

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


static func _anselmo(expr: String) -> CloseRaster:
	var r := CloseRaster.new(Palette.PARCHMENT_OLD)
	# Hábito: base INK_SOFT; o lado da sombra (esquerda) é um bloco INK; dobras poucas e longas.
	r.polygon(_v([14, 128, 22, 106, 42, 97, 86, 97, 106, 106, 114, 128]), Palette.INK_SOFT, 0, true)
	r.polygon(_v([14, 128, 22, 106, 42, 97, 50, 97, 44, 110, 40, 128]), Palette.INK)
	r.path(_v([56, 112, 55, 128]), Palette.INK)
	r.path(_v([84, 110, 86, 128]), Palette.INK)
	r.path(_v([100, 104, 106, 114, 110, 128]), Palette.PARCHMENT_OLD)
	# Capuz dobrado atrás do pescoço: volume com a parte de baixo na sombra e um fio de luz em cima.
	r.polygon(_v([32, 100, 40, 90, 52, 94, 64, 96, 76, 94, 88, 90, 96, 100, 88, 108, 64, 112, 40, 108]), Palette.INK_SOFT, 0, true)
	r.polygon(_v([34, 102, 64, 106, 94, 102, 88, 108, 64, 112, 40, 108]), Palette.INK)
	r.polygon(_v([32, 100, 40, 90, 48, 93, 44, 104]), Palette.INK)
	r.path(_v([72, 94, 80, 92, 88, 91, 94, 97]), Palette.PARCHMENT_OLD)
	r.path(_v([60, 97, 62, 105]), Palette.INK)
	# Pescoço: base de pele, sombra do queixo e do lado esquerdo em bloco.
	r.rect(56, 80, 16, 17, SKIN_SHADE, 0, true)
	r.rect(66, 86, 5, 11, SKIN)
	# Orelhas: a da sombra toda em tom médio; a da luz com a dobra interna.
	r.ellipse(40, 59, 4, 8, SKIN_SHADE, 0, true)
	r.ellipse(88, 59, 4, 8, SKIN, 0, true)
	r.path(_v([89, 55, 90, 59, 89, 63]), CREASE)
	# Rosto: base, sombra lateral (bloco com borda definida), luz na maçã e na testa do lado direito.
	_face_fill(r, 26, 86, SKIN, func(_x: int, _y: int, _h: float) -> bool: return true)
	_face_fill(r, 44, 86, SKIN_SHADE, func(x: int, _y: int, h: float) -> bool: return x < A_CX - h * 0.55)
	_face_fill(r, 80, 86, SKIN_SHADE, func(_x: int, _y: int, _h: float) -> bool: return true)
	r.polygon(_v([47, 64, 54, 66, 58, 72, 50, 72]), SKIN_SHADE)
	r.rect(74, 61, 6, 2, SKIN_LIGHT)
	r.rect(70, 38, 5, 2, SKIN_LIGHT)
	# Cabelo da tonsura: massa INK_SOFT com franja em degraus; um bloco de luz à direita e um de sombra à esquerda.
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
	# Coroa careca: sombra em crescente à esquerda, brilho em bloco à direita.
	r.ellipse(64.5, 31, 13, 6, SKIN)
	r.polygon(_v([52, 31, 56, 27, 58, 28, 55, 33]), SKIN_SHADE)
	r.rect(69, 28, 4, 2, SKIN_LIGHT)
	# Nariz: sombra lateral em bloco, ponta com a sombra embaixo, duas narinas.
	r.polygon(_v([62, 55, 62, 66, 57, 69, 59, 64]), SKIN_SHADE)
	r.rect(58, 69, 9, 2, SKIN_SHADE)
	r.rect(59, 68, 2, 1, CREASE)
	r.rect(65, 68, 2, 1, CREASE)
	r.rect(65, 60, 1, 4, SKIN_LIGHT)
	# Sombra da sobrancelha sobre os olhos (órbita).
	r.rect(48, 51, 11, 2, SKIN_SHADE)
	r.rect(70, 51, 11, 2, SKIN_SHADE)
	_anselmo_expression(r, expr)
	r.outline(Palette.INK, 3)
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


static func _anselmo_expression(r: CloseRaster, expr: String) -> void:
	match expr:
		"scared":
			_eye(r, 53, 57, 5, 2, 0)
			_eye(r, 75, 57, 5, 2, 0)
			# Sobrancelhas erguidas por dentro (massas), boca pequena aberta, gota de suor.
			r.polygon(_v([46, 49, 52, 47, 59, 44, 59, 46, 52, 49, 46, 51]), Palette.INK)
			r.polygon(_v([82, 49, 76, 47, 69, 44, 69, 46, 76, 49, 82, 51]), Palette.INK)
			r.rect(62, 74, 4, 4, Palette.INK)
			r.rect(61, 75, 1, 2, Palette.INK)
			r.rect(66, 75, 1, 2, Palette.INK)
			r.rect(61, 79, 6, 1, SKIN_SHADE)
			r.polygon(_v([85, 44, 87, 47, 87, 49, 84, 49, 84, 47]), SKIN_LIGHT)
			r.rect(84, 49, 3, 1, CREASE)
		"relieved":
			_eye(r, 53, 58, 3, 3, 1)
			_eye(r, 75, 58, 3, 3, 1)
			# Sobrancelhas soltas; sorriso curto de canto; sombra sob o lábio.
			r.polygon(_v([46, 48, 52, 46, 59, 47, 59, 49, 52, 48, 46, 50]), Palette.INK)
			r.polygon(_v([69, 47, 76, 46, 82, 48, 82, 50, 76, 48, 69, 49]), Palette.INK)
			r.path(_v([58, 75, 60, 76, 66, 76, 69, 74]), Palette.INK)
			r.rect(61, 78, 6, 1, SKIN_SHADE)
		_:  # determined
			_eye(r, 53, 58, 3, 3, 0)
			_eye(r, 75, 58, 3, 3, 0)
			# Sobrancelhas grossas descendo para o centro; ruga curta entre elas; boca firme.
			r.polygon(_v([45, 45, 52, 47, 59, 50, 59, 53, 52, 50, 45, 48]), Palette.INK)
			r.polygon(_v([83, 45, 76, 47, 69, 50, 69, 53, 76, 50, 83, 48]), Palette.INK)
			r.rect(64, 49, 1, 3, CREASE)
			r.rect(58, 76, 12, 2, Palette.INK)
			r.rect(57, 77, 1, 1, Palette.INK)
			r.rect(70, 77, 1, 1, Palette.INK)
			r.rect(60, 79, 8, 2, SKIN_SHADE)


# --- Abade Gerbrand (fantasma) --------------------------------------------------------------------

static func _abbot_ghost(expr: String) -> CloseRaster:
	var r := CloseRaster.new(Palette.INK_SOFT)
	var dark := Palette.INK_SOFT
	# Roupa de fantasma: xadrez (a transparência dos fantasmas); o lado da luz mais denso.
	r.polygon(_v([6, 128, 14, 104, 38, 94, 90, 94, 114, 104, 122, 128]), Palette.CHALK, 1, true)
	r.polygon(_v([64, 94, 90, 94, 114, 104, 122, 128, 64, 128]), Palette.CHALK, 2)
	r.path(_v([40, 100, 36, 128]), Palette.CHALK)
	r.path(_v([88, 100, 92, 128]), Palette.CHALK)
	var hood: PackedVector2Array = _v([64, 4, 74, 16, 86, 40, 96, 70, 104, 98, 24, 98, 32, 70, 42, 40, 54, 16])
	r.polygon(hood, Palette.CHALK, 1, true)
	r.polygon(_v([64, 4, 74, 16, 86, 40, 96, 70, 104, 98, 64, 98]), Palette.CHALK, 2)
	r.path(_v([66, 12, 80, 44, 92, 94]), Palette.CHALK)
	# Abertura do rosto: o fundo do capuz, escuro.
	r.ellipse(64, 60, 21, 28, Palette.INK)
	# Rosto velho e triste em tinta clara sólida; sombras em blocos PARCHMENT_OLD.
	r.ellipse(65, 60, 16, 23, Palette.CHALK)
	r.polygon(_v([50, 50, 54, 44, 56, 60, 55, 76, 52, 72]), Palette.PARCHMENT_OLD)
	r.rect(53, 52, 10, 2, Palette.PARCHMENT_OLD)
	r.rect(68, 52, 10, 2, Palette.PARCHMENT_OLD)
	r.polygon(_v([55, 64, 59, 66, 58, 72, 55, 70]), Palette.PARCHMENT_OLD)
	r.polygon(_v([76, 64, 72, 66, 73, 71, 76, 69]), Palette.PARCHMENT_OLD)
	# Rugas da testa: dois traços curtos; sobrancelhas brancas caídas para fora.
	r.rect(59, 44, 12, 1, dark)
	r.rect(61, 47, 8, 1, dark)
	r.polygon(_v([51, 50, 56, 48, 61, 49, 61, 51, 56, 50, 52, 52]), Palette.CHALK)
	r.polygon(_v([69, 49, 74, 48, 79, 50, 78, 52, 74, 50, 69, 51]), Palette.CHALK)
	r.rect(51, 51, 10, 1, Palette.PARCHMENT_OLD)
	r.rect(69, 51, 10, 1, Palette.PARCHMENT_OLD)
	if expr == "smiling":
		# Olhos apertados num sorriso que esconde algo.
		r.polygon(_v([53, 58, 56, 56, 59, 58, 58, 59, 56, 57, 54, 59]), dark)
		r.polygon(_v([71, 58, 74, 56, 77, 58, 76, 59, 74, 57, 72, 59]), dark)
	else:
		# Olhos pesados: pálpebra caída para fora, íris pequena.
		r.rect(53, 56, 7, 2, dark)
		r.rect(71, 56, 7, 2, dark)
		r.rect(52, 57, 1, 1, dark)
		r.rect(78, 57, 1, 1, dark)
		r.rect(56, 58, 2, 2, dark)
		r.rect(73, 58, 2, 2, dark)
	# Bolsas sob os olhos (blocos), nariz longo pela sombra lateral e narinas.
	r.rect(54, 61, 6, 1, Palette.PARCHMENT_OLD)
	r.rect(71, 61, 6, 1, Palette.PARCHMENT_OLD)
	r.polygon(_v([63, 56, 63, 68, 59, 71, 61, 64]), Palette.PARCHMENT_OLD)
	r.rect(61, 70, 2, 1, dark)
	r.rect(66, 70, 2, 1, dark)
	# Bigode e barba longa: massa clara, lado da sombra em bloco, poucos fios longos.
	var beard: PackedVector2Array = _v([50, 74, 56, 72, 64, 74, 72, 72, 80, 74, 80, 88, 74, 104, 64, 120, 54, 104, 50, 88])
	r.polygon(beard, Palette.CHALK, 0, true)
	r.polygon(_v([50, 74, 56, 73, 58, 90, 60, 110, 54, 104, 50, 88]), Palette.PARCHMENT_OLD)
	r.polygon(_v([52, 76, 58, 73, 64, 76, 70, 73, 77, 76, 72, 79, 64, 78, 56, 79]), Palette.CHALK)
	r.rect(56, 79, 16, 1, Palette.PARCHMENT_OLD)
	if expr == "smiling":
		r.path(_v([60, 80, 63, 81, 67, 81, 70, 79]), dark)
	else:
		r.path(_v([60, 81, 63, 80, 67, 80, 70, 81]), dark)
	r.path(_v([64, 84, 64, 112]), Palette.PARCHMENT_OLD)
	r.path(_v([70, 84, 71, 100]), Palette.PARCHMENT_OLD)
	r.outline(Palette.CHALK, 3)
	return r
