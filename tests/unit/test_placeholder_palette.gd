extends GutTest
## D-076 Constituição VII: todo PNG gerado por script usa só as 9 cores exatas do design-tokens.json
## (byte a byte) ou transparência total. Pega o erro antigo de 1 abaixo por arredondamento.

const DIR := "res://assets/placeholders/"
## Máscaras brancas que o jogo tinge na hora de desenhar (a cor final sai da paleta).
const MASKS: PackedStringArray = ["ui_font_atlas.png"]


func _allowed() -> Dictionary:
	var out: Dictionary = {}
	for c: Color in ArtQuantizer.palette().values():
		out[Vector3i(c.r8, c.g8, c.b8)] = true
	return out


func test_every_placeholder_png_uses_exact_palette_bytes() -> void:
	var allowed: Dictionary = _allowed()
	var files: int = 0
	for f: String in DirAccess.get_files_at(DIR):
		if not f.ends_with(".png") or MASKS.has(f):
			continue
		files += 1
		var img := Image.load_from_file(ProjectSettings.globalize_path(DIR + f))
		img.convert(Image.FORMAT_RGBA8)
		var d: PackedByteArray = img.get_data()
		var bad: int = 0
		var first: String = ""
		for i: int in range(0, d.size(), 4):
			var a: int = d[i + 3]
			if a == 0:
				continue
			if a != 255 or not allowed.has(Vector3i(d[i], d[i + 1], d[i + 2])):
				bad += 1
				if first == "":
					first = "(%d,%d,%d,%d)" % [d[i], d[i + 1], d[i + 2], a]
		assert_eq(bad, 0, "%s: %d pixels fora da paleta, ex. %s" % [f, bad, first])
	assert_gt(files, 10, "conferiu os PNGs")
