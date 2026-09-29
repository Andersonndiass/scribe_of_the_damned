extends GutTest
## T701 Tradução (007 FR-711, SC-704, SC-705; D-066): toda chave tem PT-BR e EN; toda chave usada
## no código existe; nenhum texto de interface escrito direto no código; troca de idioma na hora.

const CSV := "res://i18n/ui.csv"
## Pastas com texto de interface.
const UI_DIRS: Array[String] = ["res://src/ui/", "res://src/bosses/"]
## Literais permitidos (o latim nunca é traduzido, game bible §4).
const ALLOWED: Array[String] = ["HÆRESIS!"]


func _keys() -> Dictionary:
	var out := {}
	var f := FileAccess.open(CSV, FileAccess.READ)
	var header: PackedStringArray = f.get_csv_line()
	while not f.eof_reached():
		var row: PackedStringArray = f.get_csv_line()
		if row.size() < 3 or row[0] == "":
			continue
		out[row[0]] = [row[header.find("pt_BR")], row[header.find("en")]]
	return out


func _scripts(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f: String in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + f)
	for d: String in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir + d + "/"))
	return out


func after_each() -> void:
	TranslationServer.set_locale(Settings.language)


func test_every_key_has_both_languages() -> void:
	var keys := _keys()
	assert_gt(keys.size(), 10)
	for k: String in keys:
		assert_ne(keys[k][0], "", "%s tem PT-BR" % k)
		assert_ne(keys[k][1], "", "%s tem EN" % k)


func test_every_key_used_in_code_exists() -> void:
	var keys := _keys()
	var re := RegEx.create_from_string('tr\\(&?"([A-Z0-9_ ]+)"\\)')
	for path: String in _scripts("res://src/"):
		var src: String = FileAccess.get_file_as_string(path)
		for m: RegExMatch in re.search_all(src):
			assert_true(keys.has(m.get_string(1)), "%s usa %s" % [path.get_file(), m.get_string(1)])


func test_data_keys_exist() -> void:
	var keys := _keys()
	for f: String in DirAccess.get_files_at("res://data/shop/items/"):
		if not f.ends_with(".tres"):
			continue
		var card: ShopItemData = load("res://data/shop/items/" + f)
		assert_true(keys.has(card.short_desc), "%s.short_desc" % f)
		if card.kind == &"item":
			assert_true(keys.has(card.display_name), "%s.display_name" % f)
	assert_true(keys.has((load("res://data/bosses/asmodeus.tres") as BossData).display_name))


func test_no_ui_literals_in_code() -> void:
	# SC-704: nada de texto de interface passado direto ao PixelFont.
	var re := RegEx.create_from_string('PixelFont\\.draw(?:_centered)?\\([^,]+,\\s*"([^"]*)"')
	var scanned: int = 0
	for dir: String in UI_DIRS:
		for path: String in _scripts(dir):
			scanned += 1
			for m: RegExMatch in re.search_all(FileAccess.get_file_as_string(path)):
				assert_true(ALLOWED.has(m.get_string(1)), "%s escreve \"%s\" direto" % [path.get_file(), m.get_string(1)])
	assert_gt(scanned, 10, "leu os scripts de interface")


func test_switching_language_changes_text_at_once() -> void:
	TranslationServer.set_locale("pt_BR")
	assert_eq(tr(&"GAMEOVER_TITLE"), "A PÁGINA ARDEU")
	TranslationServer.set_locale("en")
	assert_eq(tr(&"GAMEOVER_TITLE"), "THE PAGE BURNED", "SC-705")
