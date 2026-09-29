class_name CharacterBusts
extends RefCounted
## Bustos da seleção de personagem, 63×63 (desenho em 42), em CAMADAS (feedback do autor: sprites separados, juntados
## na cena) — roupa, cabeça, cabelo/véu, rosto e acessório — pelas regras de pixel art (D-075/D-076):
## pele em blocos (PARCHMENT, sombra PARCHMENT_OLD à esquerda), contorno INK, silhueta própria de cada
## escriba (catálogo §1). Bloqueado = a silhueta lisa INK_SOFT (mostra quem vem, sem revelar o rosto).
## Tudo recortado no círculo do medalhão. Placeholder por script (D-024) até a arte chegar.

## Desenho em 42 e imagem em 63 (1,5×, como os closes): medalhão maior, mesmo traço.
const DESIGN := 42
const SIZE := 63
const R := 31
const CLEAR := Color(0, 0, 0, 0)
const PARTS: Array[StringName] = [&"roupa", &"veu", &"cabeca", &"cabelo", &"rosto", &"acessorio", &"contorno"]

static var _cache: Dictionary = {}


## Camadas de baixo para cima; `locked` devolve só a silhueta.
static func layers(id: String, locked: bool) -> Array[Texture2D]:
	var key: String = "%s/%s" % [id, locked]
	if _cache.has(key):
		return _cache[key]
	var rasters: Dictionary = _draw(id)
	var out: Array[Texture2D] = []
	if locked:
		var sil := CloseRaster.new(CLEAR, SIZE, DESIGN)
		for part: StringName in [&"roupa", &"veu", &"cabeca", &"cabelo", &"acessorio"]:
			if rasters.has(part):
				var r: CloseRaster = rasters[part]
				for i: int in r.mask.size():
					if r.mask[i] == 1 or r.img.get_pixel(i % SIZE, i / SIZE).a > 0.0:
						sil.mask[i] = 1
		for i: int in sil.mask.size():
			if sil.mask[i] == 1:
				sil.img.set_pixel(i % SIZE, i / SIZE, Palette.INK_SOFT)
		sil.outline(Palette.INK, 1)
		_clip(sil)
		out.append(sil.texture())
		# Cadeado 8×10 por cima, centrado (camada própria).
		var lock := CloseRaster.new(CLEAR, SIZE, DESIGN)
		for y: int in UiScreen.PADLOCK.size():
			for x: int in UiScreen.PADLOCK[y].length():
				var ch: String = UiScreen.PADLOCK[y][x]
				if ch != ".":
					var c: Color = Palette.INK if ch == "K" else (Palette.PARCHMENT_OLD if ch == "X" else Palette.PARCHMENT)
					lock.img.set_pixel(SIZE / 2 - 4 + x, SIZE / 2 - 5 + y, c)
		out.append(lock.texture())
	else:
		var outline := CloseRaster.new(CLEAR, SIZE, DESIGN)
		for part: StringName in [&"roupa", &"veu", &"cabeca", &"cabelo"]:
			if rasters.has(part):
				var r: CloseRaster = rasters[part]
				for i: int in r.mask.size():
					if r.mask[i] == 1:
						outline.mask[i] = 1
		outline.outline(Palette.INK, 1)
		rasters[&"contorno"] = outline
		for part: StringName in PARTS:
			if rasters.has(part):
				_clip(rasters[part])
				out.append((rasters[part] as CloseRaster).texture())
	_cache[key] = out
	return out


## Apaga o que sai do círculo do medalhão.
static func _clip(r: CloseRaster) -> void:
	for y: int in SIZE:
		for x: int in SIZE:
			if Vector2(x + 0.5, y + 0.5).distance_to(Vector2(SIZE / 2.0, SIZE / 2.0)) > SIZE / 2.0:
				r.img.set_pixel(x, y, CLEAR)


static func _v(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i: int in range(0, points.size(), 2):
		out.append(Vector2(points[i], points[i + 1]))
	return out


static func _new() -> CloseRaster:
	return CloseRaster.new(CLEAR, SIZE, DESIGN)


## Ombros com o lado da sombra (esquerda) em bloco.
static func _habit(r: CloseRaster, narrow: bool = false) -> void:
	var w: int = 3 if narrow else 0
	r.polygon(_v([3 + w, 42, 7 + w, 33, 15, 30, 27, 30, 35 - w, 33, 39 - w, 42]), Palette.INK_SOFT, 0, true)
	r.polygon(_v([3 + w, 42, 7 + w, 33, 15, 30, 17, 30, 13, 36, 12, 42]), Palette.INK)
	r.path(_v([30, 31, 34 - w, 35]), Palette.PARCHMENT_OLD)


## Cabeça: pescoço, rosto oval, sombra lateral e sob o queixo em blocos, luz na maçã direita.
static func _head(r: CloseRaster, cy: float = 18.0, rx: float = 8.0, ry: float = 10.0) -> void:
	r.rect(18, cy + ry - 3, 7, 6, Palette.PARCHMENT_OLD, 0, true)
	r.ellipse(21.5, cy, rx, ry, Palette.PARCHMENT, 0, true)
	for y: int in range(int(cy - ry), int(cy + ry) + 1):
		var q: float = 1.0 - pow((y + 0.5 - cy) / ry, 2)
		if q <= 0.0:
			continue
		var half: float = rx * sqrt(q)
		var x0: int = int(roundf(21.5 - half))
		r.rect(x0, y, maxi(1, int(roundf(half * 0.55))), 1, Palette.PARCHMENT_OLD)
	r.rect(18, cy + ry - 2, 7, 1, Palette.PARCHMENT_OLD)
	r.rect(25, cy + 2, 2, 1, Palette.CHALK)


## Olhos (massa + brilho), sobrancelhas e boca simples.
static func _face(r: CloseRaster, cy: float, mouth: Color = Palette.INK_SOFT, big: bool = false) -> void:
	var eh: int = 3 if big else 2
	for ex: int in [17, 24]:
		r.rect(ex, cy - 1, 2, eh, Palette.INK)
		r.rect(ex + 1, cy - 1, 1, 1, Palette.CHALK)
		r.rect(ex - 1, cy - 4, 4, 1, Palette.INK)
	r.rect(21, cy + 2, 2, 1, Palette.PARCHMENT_OLD)
	r.rect(19, cy + 5, 5, 1, mouth)


static func _draw(id: String) -> Dictionary:
	var parts: Dictionary = {}
	var roupa := _new()
	var veu := _new()
	var cabeca := _new()
	var cabelo := _new()
	var rosto := _new()
	var acessorio := _new()
	match id:
		"anselmo":
			_habit(roupa)
			roupa.polygon(_v([12, 31, 16, 28, 21, 30, 27, 28, 31, 31, 27, 34, 21, 35, 15, 34]), Palette.INK_SOFT, 0, true)
			roupa.rect(14, 33, 15, 1, Palette.INK)
			_head(cabeca)
			# Tonsura: anel de cabelo com a coroa careca e costeletas.
			for y: int in range(8, 17):
				for x: int in range(13, 31):
					var crown: bool = pow((x + 0.5 - 21.5) / 5.0, 2) + pow((y + 0.5 - 9.0) / 2.5, 2) <= 1.0
					var in_head: bool = pow((x + 0.5 - 21.5) / 8.0, 2) + pow((y + 0.5 - 18.0) / 10.0, 2) <= 1.0
					if in_head and not crown and (y <= 12 or absf(x + 0.5 - 21.5) > 6.0):
						cabelo.px(x, y, Palette.INK_SOFT)
			cabelo.rect(14, 10, 2, 4, Palette.INK)
			cabelo.rect(26, 10, 2, 2, Palette.PARCHMENT_OLD)
			_face(rosto, 18.0)
		"hildegarda":
			_habit(roupa)
			# Véu: moldura escura em volta do rosto, caindo nos ombros; touca branca por dentro.
			veu.polygon(_v([9, 34, 10, 14, 14, 7, 21, 5, 29, 7, 33, 14, 34, 34, 27, 32, 21, 31, 15, 32]), Palette.INK_SOFT, 0, true)
			veu.polygon(_v([9, 34, 10, 14, 14, 7, 17, 6, 13, 16, 13, 33]), Palette.INK)
			veu.ellipse(21.5, 18, 9.5, 11.5, Palette.CHALK, 0, true)
			_head(cabeca, 18.0, 7.0, 9.0)
			_face(rosto, 18.0, Palette.BLOOD_DARK)
		"tome":
			_habit(roupa)
			roupa.rect(29, 37, 2, 2, Palette.PARCHMENT_OLD)
			_head(cabeca)
			for y: int in range(8, 16):
				for x: int in range(13, 31):
					var crown: bool = pow((x + 0.5 - 21.5) / 6.0, 2) + pow((y + 0.5 - 9.5) / 3.0, 2) <= 1.0
					var in_head: bool = pow((x + 0.5 - 21.5) / 8.0, 2) + pow((y + 0.5 - 18.0) / 10.0, 2) <= 1.0
					if in_head and not crown and (y <= 12 or absf(x + 0.5 - 21.5) > 6.0):
						cabelo.px(x, y, Palette.INK_SOFT)
			# Barba cheia cobrindo o queixo.
			cabelo.polygon(_v([13, 20, 16, 24, 21, 25, 27, 24, 30, 20, 30, 26, 26, 32, 21, 33, 16, 32, 13, 26]), Palette.INK_SOFT, 0, true)
			cabelo.polygon(_v([13, 20, 16, 24, 17, 32, 13, 26]), Palette.INK)
			_face(rosto, 17.0)
			rosto.rect(19, 23, 5, 1, Palette.PARCHMENT_OLD)
			# Pena CHALK na orelha direita.
			acessorio.line(Vector2(29, 15), Vector2(33, 8), Palette.CHALK, 2)
			acessorio.rect(29, 15, 1, 1, Palette.INK)
		"iluminador":
			_habit(roupa)
			roupa.rect(26, 35, 2, 2, Palette.GOLD)
			_head(cabeca)
			# Cabelo curto em capacete.
			cabelo.polygon(_v([13, 16, 13, 11, 16, 8, 21, 7, 27, 8, 30, 11, 30, 16, 27, 12, 21, 11, 16, 12]), Palette.INK_SOFT, 0, true)
			cabelo.rect(14, 11, 3, 4, Palette.INK)
			_face(rosto, 18.0)
			# Óculos redondos: aros INK, lentes CHALK, ponte.
			for ex: int in [15, 23]:
				acessorio.rect(ex, 15, 6, 6, Palette.INK)
				acessorio.rect(ex + 1, 16, 4, 4, Palette.CHALK)
				acessorio.rect(ex + 2, 17, 2, 2, Palette.INK)
				acessorio.rect(ex + 3, 16, 1, 1, Palette.PARCHMENT)
			acessorio.rect(21, 17, 2, 1, Palette.INK)
		"beda":
			_habit(roupa, true)
			_head(cabeca, 19.0, 8.5, 10.0)
			# Cabelo claro e cheio (noviço, sem tonsura).
			cabelo.polygon(_v([12, 18, 12, 11, 15, 7, 21, 6, 28, 7, 31, 11, 31, 18, 28, 13, 23, 12, 17, 13, 14, 16]), Palette.PARCHMENT_OLD, 0, true)
			cabelo.polygon(_v([12, 18, 12, 11, 15, 7, 17, 7, 14, 13]), Palette.INK_SOFT)
			cabelo.rect(24, 8, 3, 1, Palette.PARCHMENT)
			_face(rosto, 19.0, Palette.INK_SOFT, true)
	parts[&"roupa"] = roupa
	parts[&"veu"] = veu
	parts[&"cabeca"] = cabeca
	parts[&"cabelo"] = cabelo
	parts[&"rosto"] = rosto
	parts[&"acessorio"] = acessorio
	return parts
