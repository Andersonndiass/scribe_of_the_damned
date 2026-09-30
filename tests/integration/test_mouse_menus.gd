extends GutTest
## Mouse nos menus (D-084, pedido do autor): passar por cima foca, clique esquerdo confirma, clique
## direito volta — no menu principal, capítulos, Opções (linhas, volume, teclas), Grimório, Pausa e
## loja. As áreas clicáveis são as do desenho.

const MENU := preload("res://src/ui/screens/menu_screen.tscn")
const CHAPTER := preload("res://src/ui/screens/chapter_screen.tscn")
const OPTIONS := preload("res://src/ui/screens/options_screen.tscn")
const CODEX := preload("res://src/ui/screens/codex_screen.tscn")
const MAIN_SCENE := preload("res://src/main/main.tscn")

var _requested: Array[StringName] = []


func before_each() -> void:
	_requested.clear()
	EventBus.screen_requested.connect(_on_requested)


func after_each() -> void:
	EventBus.screen_requested.disconnect(_on_requested)
	get_tree().paused = false


func _on_requested(s: StringName) -> void:
	_requested.append(s)


func _click(pos: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = true
	ev.position = pos
	return ev


func _hover(pos: Vector2) -> InputEventMouseMotion:
	var ev := InputEventMouseMotion.new()
	ev.position = pos
	return ev


## Constante do script da tela (as telas não têm class_name).
func _k(s: Node, name: StringName) -> Variant:
	return s.get_script().get_script_constant_map()[name]


func _screen(scene: PackedScene) -> UiScreen:
	var s: UiScreen = scene.instantiate()
	add_child_autofree(s)
	await wait_frames(2)  # desenha e registra as áreas
	return s


func test_menu_list_hover_click_and_right_click() -> void:
	var m := MenuList.new()
	m.add(&"a", "A")
	m.add(&"b", "B")
	m.set_rect(0, Rect2(0, 0, 50, 10))
	m.set_rect(1, Rect2(0, 20, 50, 10))
	var chosen: Array[StringName] = []
	var backs: Array[int] = []
	m.chosen.connect(func(id: StringName) -> void: chosen.append(id))
	m.back.connect(func() -> void: backs.append(1))
	m.handle_input(_hover(Vector2(10, 25)))
	assert_eq(m.focus, 1, "passar por cima foca")
	m.handle_input(_click(Vector2(10, 5)))
	assert_eq(chosen, [&"a"] as Array[StringName], "clique confirma o item clicado")
	m.handle_input(_click(Vector2(300, 300), MOUSE_BUTTON_RIGHT))
	assert_eq(backs.size(), 1, "clique direito volta")


func test_main_menu_click_opens_options() -> void:
	var s: UiScreen = await _screen(MENU)
	var i: int = s.menu.items.map(func(it: Dictionary) -> StringName: return it["id"]).find(&"options")
	var r: Rect2 = s.menu.rects[i]
	s.handle_input(_click(r.get_center()))
	assert_has(_requested, &"options")


func test_chapter_page_click_starts() -> void:
	var s: UiScreen = await _screen(CHAPTER)
	var r: Rect2 = s.call(&"_page_rects")[0]
	s.handle_input(_hover(r.get_center()))
	assert_eq(s.get(&"index"), 0)
	s.handle_input(_click(r.get_center()))
	assert_true(_requested.has(&"game") or _requested.has(&"cutscene"), "clicar no Cap. 1 começa")


func test_options_click_toggles_and_opens_keys() -> void:
	var s: UiScreen = await _screen(OPTIONS)
	var row: int = (_k(s, &"ROWS") as Array).find(&"shake")
	var y: float = _k(s, &"ROW_Y0") + row * _k(s, &"ROW_STEP") + 4
	var before: bool = Settings.shake_enabled
	s.handle_input(_click(Vector2(200, y)))
	assert_ne(Settings.shake_enabled, before, "clique no sim/não alterna")
	Settings.shake_enabled = before
	var keys_row: int = (_k(s, &"ROWS") as Array).find(&"keys")
	s.handle_input(_click(Vector2(200, _k(s, &"ROW_Y0") + keys_row * _k(s, &"ROW_STEP") + 4)))
	assert_true(s.get(&"in_keys"), "clique em Teclas abre a subpágina")
	s.handle_input(_click(Vector2(200, _k(s, &"KEY_Y0") + 2 * _k(s, &"KEY_STEP") + 4)))
	assert_true(s.get(&"waiting_key"), "clique numa tecla espera a nova")
	s.handle_input(_click(Vector2(10, 10), MOUSE_BUTTON_RIGHT))
	assert_false(s.get(&"waiting_key"), "clique direito cancela")


func test_options_volume_goes_where_clicked() -> void:
	var s: UiScreen = await _screen(OPTIONS)
	var before: float = Settings.volume(&"Master")
	var x: float = _k(s, &"VALUE_X") + 50
	s.handle_input(_click(Vector2(x, _k(s, &"ROW_Y0") + 6)))
	assert_almost_eq(Settings.volume(&"Master"), 0.5, 0.001)
	Settings.set_volume(&"Master", before)


func test_codex_tab_click() -> void:
	var s: UiScreen = await _screen(CODEX)
	var r: Rect2 = s.call(&"_tab_rects")[2]
	s.handle_input(_click(r.get_center()))
	assert_eq(s.get(&"tab"), 2)


func test_pause_menu_click_resumes() -> void:
	var main: Node2D = MAIN_SCENE.instantiate()
	add_child_autofree(main)
	main.get_node("WaveDirector").stop()
	var ov: GameOverlays = main.get_node("Overlays")
	ov.toggle_pause()
	await get_tree().create_timer(0.6, true).timeout  # o rolo desenrola antes do menu
	var i: int = ov.menu.items.map(func(it: Dictionary) -> StringName: return it["id"]).find(&"resume")
	ov._unhandled_input(_click(ov.menu.rects[i].get_center()))
	assert_eq(ov.mode, GameOverlays.Mode.NONE, "clique em Continuar volta ao jogo")


func test_shop_click_buys_and_ribbon_goes_on() -> void:
	var main: Node2D = MAIN_SCENE.instantiate()
	main.set_meta(&"shop_manual", true)
	add_child_autofree(main)
	main.get_node("WaveDirector").stop()
	var shop: Shop = main.get_node("Shop")
	var screen: ShopScreen = main.get_node("ShopScreen")
	GameState.gold_ink = 999
	main.call(&"_open_shop")
	await get_tree().create_timer(0.6, true).timeout
	var center := Vector2(ShopScreen.CARD_X[0] + 50, ShopScreen.CARD_Y + 70)
	assert_true(screen.handle_input(_click(center)))
	assert_true(shop.offer.is_sold(0), "clique na carta compra")
	assert_true(screen.handle_input(_click(ShopScreen.RIBBON.get_center())))
	assert_false(shop.is_open, "clique em Próxima onda fecha a loja")
