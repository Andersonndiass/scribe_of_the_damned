extends SceneTree
## Gera src/core/palette.gd a partir de specs/000-game-bible/design-tokens.json (T008).
## Uso: godot --headless --path . -s tools/gen_palette.gd

const TOKENS_PATH := "res://specs/000-game-bible/design-tokens.json"
const OUTPUT_PATH := "res://src/core/palette.gd"


func _init() -> void:
	var err: int = _generate()
	quit(err)


func _generate() -> int:
	var file := FileAccess.open(TOKENS_PATH, FileAccess.READ)
	if file == null:
		push_error("gen_palette: não foi possível abrir %s" % TOKENS_PATH)
		return 1
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not (parsed as Dictionary).has("color"):
		push_error("gen_palette: JSON inválido ou sem a chave 'color'")
		return 1

	var colors: Dictionary = (parsed as Dictionary)["color"]
	var names: Array = colors.keys()
	names.sort()

	var lines: PackedStringArray = [
		"class_name Palette",
		"extends RefCounted",
		"## GERADO por tools/gen_palette.gd a partir de design-tokens.json. NÃO EDITAR À MÃO.",
		"## Princípio VII: nenhuma cor fora desta lista.",
		"",
	]
	var all_entries: PackedStringArray = []
	for token_name: String in names:
		var hex: String = (colors[token_name] as Dictionary)["hex"]
		var c := Color.html(hex)
		var const_name: String = token_name.to_upper()
		# n/255 exato: com casas decimais arredondadas, a Image (RGBA8) trunca e grava 1 abaixo (D-076).
		lines.append("const %s := Color(%d / 255.0, %d / 255.0, %d / 255.0, 1.0)  # %s" % [const_name, c.r8, c.g8, c.b8, hex])
		all_entries.append("\t&\"%s\": %s," % [token_name, const_name])

	lines.append("")
	lines.append("const ALL: Dictionary[StringName, Color] = {")
	lines.append_array(all_entries)
	lines.append("}")
	lines.append("")
	lines.append("")
	lines.append("## Retorna true se a cor (ignorando alpha) pertence à paleta travada.")
	lines.append("static func is_locked_color(color: Color) -> bool:")
	lines.append("\tfor locked: Color in ALL.values():")
	lines.append("\t\tif locked.is_equal_approx(Color(color.r, color.g, color.b, 1.0)):")
	lines.append("\t\t\treturn true")
	lines.append("\treturn false")
	lines.append("")

	var out := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if out == null:
		push_error("gen_palette: não foi possível escrever %s" % OUTPUT_PATH)
		return 1
	out.store_string("\n".join(lines))
	print("gen_palette: %d cores escritas em %s" % [names.size(), OUTPUT_PATH])
	return 0
