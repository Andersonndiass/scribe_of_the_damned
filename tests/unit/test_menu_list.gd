extends GutTest
## T711 MenuList (007 FR-713): foco com ↑/↓ (e W/S), dá a volta, pula os desabilitados; Espaço/Enter
## confirma; Esc volta. Lógica de navegação usada por todas as telas.

var _m: MenuList
var _chosen: Array[StringName] = []
var _back: int = 0


func before_each() -> void:
	_chosen.clear()
	_back = 0
	_m = MenuList.new()
	_m.add(&"play", "MENU_PLAY")
	_m.add(&"codex", "MENU_CODEX")
	_m.add(&"locked", "MENU_OPTIONS", false)
	_m.add(&"credits", "MENU_CREDITS")
	_m.chosen.connect(func(id: StringName) -> void: _chosen.append(id))
	_m.back.connect(func() -> void: _back += 1)


func _press(action: StringName) -> bool:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return _m.handle_input(ev)


func test_starts_on_the_first_enabled_item() -> void:
	assert_eq(_m.focused_id(), &"play")


func test_down_and_up_move_and_wrap() -> void:
	_press(&"move_down")
	assert_eq(_m.focused_id(), &"codex")
	_press(&"move_down")
	assert_eq(_m.focused_id(), &"credits", "pula o desabilitado")
	_press(&"move_down")
	assert_eq(_m.focused_id(), &"play", "dá a volta")
	_press(&"move_up")
	assert_eq(_m.focused_id(), &"credits")


func test_confirm_with_space_or_enter() -> void:
	_press(&"cast")
	_press(&"move_down")
	_press(&"shop_next")
	assert_eq(_chosen, [&"play", &"codex"] as Array[StringName])


func test_escape_goes_back() -> void:
	assert_true(_press(&"pause"))
	assert_eq(_back, 1)


func test_unrelated_input_is_not_consumed() -> void:
	assert_false(_press(&"purge"))
