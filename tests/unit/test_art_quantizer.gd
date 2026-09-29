extends GutTest
## D-074 (3A) Conversor de arte: qualquer imagem vira o tamanho do asset com só as 9 cores da paleta
## (ou transparente), com pontilhado; o fundo opcional é uma cor da paleta.

func _gradient(w: int, h: int, with_alpha: bool) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y: int in h:
		for x: int in w:
			var a: float = 0.0 if with_alpha and x < w / 4 else 1.0
			img.set_pixel(x, y, Color(float(x) / w, float(y) / h, 0.5, a))
	return img


func _only_palette(img: Image, allow_clear: bool) -> bool:
	var pal: Array = ArtQuantizer.palette().values()
	for y: int in img.get_height():
		for x: int in img.get_width():
			var p: Color = img.get_pixel(x, y)
			if p.a == 0.0 and allow_clear:
				continue
			var ok: bool = false
			for c: Color in pal:
				if absf(c.r - p.r) < 0.003 and absf(c.g - p.g) < 0.003 and absf(c.b - p.b) < 0.003 and p.a == 1.0:
					ok = true
					break
			if not ok:
				return false
	return true


func test_palette_has_the_nine_tokens() -> void:
	assert_eq(ArtQuantizer.palette().size(), 9)


func test_every_mode_outputs_only_palette_colors_at_the_asked_size() -> void:
	for dither: String in ["fs", "bayer", "none"]:
		for fit: String in ["cover", "contain", "stretch"]:
			var out: Image = ArtQuantizer.to_game_art(_gradient(90, 60, false), Vector2i(48, 48), fit, dither)
			assert_eq(out.get_size(), Vector2i(48, 48), "%s/%s tamanho" % [fit, dither])
			assert_true(_only_palette(out, fit == "contain"), "%s/%s só paleta" % [fit, dither])


func test_transparency_is_kept_or_filled_with_background() -> void:
	var clear: Image = ArtQuantizer.to_game_art(_gradient(32, 32, true), Vector2i(32, 32), "stretch", "fs")
	assert_eq(clear.get_pixel(0, 0).a, 0.0, "sem bg, fica transparente")
	var filled: Image = ArtQuantizer.to_game_art(_gradient(32, 32, true), Vector2i(32, 32), "stretch", "fs", "parchment_old")
	assert_true(_only_palette(filled, false), "com bg, tudo opaco e da paleta")
	assert_true(filled.get_pixel(0, 0).is_equal_approx(Color.html("#BDB39A")))
