class_name ArtQuantizer
extends RefCounted
## Converte qualquer imagem (IA de imagem, artista, foto) para a arte do jogo (D-074, 3A): redimensiona
## para o tamanho do asset e reduz às 9 cores travadas (constituição VII), com pontilhado.
## - `fit`: "cover" (preenche e corta o centro), "contain" (cabe inteira, sobra transparente) ou
##   "stretch".
## - `dither`: "fs" (Floyd–Steinberg: melhor para ilustrações e rostos), "bayer" (padrão 4×4: melhor
##   para UI e superfícies) ou "none".
## - Pixel com alpha abaixo de `alpha_cut` fica transparente (sprites); `bg` (nome de token) pinta o
##   fundo transparente com uma cor da paleta (closes e cenários, que são opacos).
## As cores vêm do hex do `design-tokens.json` (valores exatos, sem arredondamento de float).

const TOKENS_PATH := "res://specs/000-game-bible/design-tokens.json"
const BAYER4: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
## Força do pontilhado Bayer (fração da distância típica entre tons da paleta).
const BAYER_SPREAD := 0.14


static func palette() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TOKENS_PATH))
	var out: Dictionary = {}
	if parsed is Dictionary:
		var colors: Dictionary = (parsed as Dictionary).get("color", {})
		for name: String in colors:
			out[name] = Color.html(str(colors[name]["hex"]))
	return out


static func to_game_art(src: Image, size: Vector2i, fit: String = "cover", dither: String = "fs",
		bg: String = "", alpha_cut: float = 0.5) -> Image:
	var pal: Dictionary = palette()
	var colors: Array = pal.values()
	var img: Image = _fit(src, size, fit)
	if bg != "" and pal.has(bg):
		_fill_background(img, pal[bg], alpha_cut)
	match dither:
		"fs":
			_floyd_steinberg(img, colors, alpha_cut)
		"bayer":
			_ordered(img, colors, alpha_cut, true)
		_:
			_ordered(img, colors, alpha_cut, false)
	return img


static func _fit(src: Image, size: Vector2i, fit: String) -> Image:
	var img: Image = src.duplicate()
	img.convert(Image.FORMAT_RGBA8)
	var s := Vector2(img.get_width(), img.get_height())
	if fit == "stretch":
		img.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
		return img
	var k: float = maxf(size.x / s.x, size.y / s.y) if fit == "cover" else minf(size.x / s.x, size.y / s.y)
	var scaled := Vector2i(maxi(1, roundi(s.x * k)), maxi(1, roundi(s.y * k)))
	img.resize(scaled.x, scaled.y, Image.INTERPOLATE_LANCZOS)
	var out := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var offset := Vector2i((size.x - scaled.x) / 2, (size.y - scaled.y) / 2)
	out.blit_rect(img, Rect2i(Vector2i.ZERO, scaled), offset)
	return out


static func _fill_background(img: Image, c: Color, alpha_cut: float) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			var p: Color = img.get_pixel(x, y)
			if p.a < 1.0:
				# Mistura sobre o fundo (bordas suaves viram a cor certa antes de reduzir).
				var mixed: Color = c.lerp(Color(p.r, p.g, p.b, 1.0), p.a)
				img.set_pixel(x, y, mixed if p.a >= 0.0 else c)


## Cor da paleta mais próxima (distância "redmean": pesa como o olho vê).
static func nearest(c: Color, colors: Array) -> Color:
	var best: Color = colors[0]
	var best_d: float = INF
	for p: Color in colors:
		var rm: float = (c.r + p.r) * 0.5
		var dr: float = c.r - p.r
		var dg: float = c.g - p.g
		var db: float = c.b - p.b
		var d: float = (2.0 + rm) * dr * dr + 4.0 * dg * dg + (3.0 - rm) * db * db
		if d < best_d:
			best_d = d
			best = p
	return best


static func _ordered(img: Image, colors: Array, alpha_cut: float, bayer: bool) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			var p: Color = img.get_pixel(x, y)
			if p.a < alpha_cut:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var c := Color(p.r, p.g, p.b, 1.0)
			if bayer:
				var t: float = (BAYER4[(y % 4) * 4 + (x % 4)] + 0.5) / 16.0 - 0.5
				c = Color(c.r + t * BAYER_SPREAD, c.g + t * BAYER_SPREAD, c.b + t * BAYER_SPREAD, 1.0)
			img.set_pixel(x, y, nearest(c, colors))


static func _floyd_steinberg(img: Image, colors: Array, alpha_cut: float) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var buf := PackedFloat32Array()
	buf.resize(w * h * 3)
	var solid := PackedByteArray()
	solid.resize(w * h)
	for y: int in h:
		for x: int in w:
			var p: Color = img.get_pixel(x, y)
			var i: int = y * w + x
			solid[i] = 1 if p.a >= alpha_cut else 0
			buf[i * 3] = p.r
			buf[i * 3 + 1] = p.g
			buf[i * 3 + 2] = p.b
	for y: int in h:
		for x: int in w:
			var i: int = y * w + x
			if solid[i] == 0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var old := Color(buf[i * 3], buf[i * 3 + 1], buf[i * 3 + 2], 1.0)
			var q: Color = nearest(old, colors)
			img.set_pixel(x, y, q)
			var err := [old.r - q.r, old.g - q.g, old.b - q.b]
			for n: Array in [[1, 0, 7.0], [-1, 1, 3.0], [0, 1, 5.0], [1, 1, 1.0]]:
				var nx: int = x + n[0]
				var ny: int = y + n[1]
				if nx < 0 or nx >= w or ny >= h:
					continue
				var j: int = ny * w + nx
				if solid[j] == 0:
					continue
				for ch: int in 3:
					buf[j * 3 + ch] += err[ch] * n[2] / 16.0
