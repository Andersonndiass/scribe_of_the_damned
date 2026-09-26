extends GutTest
## Fonte pixel do HUD: medidas, acentos e cobertura do atlas.


func test_width_is_six_per_char_minus_trailing_gap() -> void:
	assert_eq(PixelFont.width("LUX"), 17)
	assert_eq(PixelFont.width("LUX", 2), 34)
	assert_eq(PixelFont.width(""), 0)


func test_accents_are_normalized() -> void:
	assert_eq(PixelFont.normalize("página ardeu ç"), "PAGINA ARDEU C")


func test_atlas_covers_every_char() -> void:
	var img: Image = PixelFont.ATLAS.get_image()
	assert_eq(img.get_width(), PixelFont.CHARS.length() * PixelFont.ADVANCE)


func test_generator_uses_the_same_char_order() -> void:
	var src: String = FileAccess.get_file_as_string("res://tools/gen_placeholders.gd")
	assert_string_contains(src, 'const FONT_CHARS := "%s"' % PixelFont.CHARS)
