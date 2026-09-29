extends GutTest
## T721 Grimório (007 FR-709, FR-710, SC-703): 4 abas; ←/→ vira a entrada, ↑/↓ troca a aba; a
## entrada só aparece descoberta depois de descoberta; todo verbete e nome existe nos dois idiomas.

const SCENE := preload("res://src/ui/screens/codex_screen.tscn")
const CSV := "res://i18n/ui.csv"

var _screen: Node


func before_each() -> void:
	Codex.reset()
	_screen = SCENE.instantiate()
	_screen.embedded = true
	add_child_autofree(_screen)


func after_each() -> void:
	Codex.reset()
	Codex.load_saved()


func _press(action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	_screen.handle_input(ev)


func test_has_the_four_tabs() -> void:
	var ids: Array = _screen.tabs.map(func(t: Dictionary) -> String: return t["id"])
	assert_eq(ids, ["words", "combos", "enemies", "bosses"])
	for t: Dictionary in _screen.tabs:
		assert_true(StringName(t["id"]) in Codex.CATEGORIES)


func test_entry_is_hidden_until_discovered() -> void:
	var lux: Dictionary = _screen.current()
	assert_eq(lux["id"], "lux")
	assert_false(_screen.is_known(lux))
	assert_eq(_screen.found_count(), 0)
	Codex.discover(&"words", &"lux")
	assert_true(_screen.is_known(lux))
	assert_eq(_screen.found_count(), 1)


func test_arrows_turn_pages_and_switch_tabs() -> void:
	_press(&"move_left")
	assert_eq(_screen.index, 0, "na ponta não volta ao fim")
	_press(&"move_right")
	assert_eq(_screen.index, 1)
	_press(&"move_right")
	assert_eq(_screen.index, 1, "durante a virada o comando fica guardado")
	await get_tree().create_timer(0.5, true).timeout
	assert_eq(_screen.index, 2, "o comando guardado vira depois")
	_press(&"move_down")
	assert_eq(_screen.category(), &"combos")
	assert_eq(_screen.index, 0)
	_press(&"move_up")
	_press(&"move_up")
	assert_eq(_screen.category(), &"bosses", "↑ na primeira aba vai à última")


func test_every_entry_has_texts_in_both_languages() -> void:
	var keys := {}
	var f := FileAccess.open(CSV, FileAccess.READ)
	f.get_csv_line()
	while not f.eof_reached():
		var row: PackedStringArray = f.get_csv_line()
		if row.size() >= 3:
			keys[row[0]] = row
	for t: Dictionary in _screen.tabs:
		for e: Dictionary in t["entries"]:
			for field: String in ["meaning", "name_key", "lore"]:
				if e.has(field) and e[field] != "":
					assert_true(keys.has(e[field]), "%s: %s" % [e["id"], e[field]])
			if e.get("lore", "") != "":
				var lines: int = _screen.wrap_words(keys[e["lore"]][1], 40).size()
				assert_lte(lines, 6, "%s cabe na página" % e["id"])


func test_words_and_combos_exist_in_data() -> void:
	for t: Dictionary in _screen.tabs:
		if t["id"] in ["words", "combos"]:
			for e: Dictionary in t["entries"]:
				assert_true(ResourceLoader.exists("res://data/%s/%s.tres" % [t["id"], e["id"]]), e["id"])
