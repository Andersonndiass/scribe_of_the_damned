extends GutTest
## T722 Fluxo das telas (007 SC-701, SC-705): do Splash à primeira onda e do Game Over de volta ao
## Menu só com teclado; trocar o idioma nas Opções muda o texto das telas na hora.

const APP := preload("res://src/app/app.tscn")
const HOP := ScreenRouter.FADE_MENU * 2 + 0.15
const HOP_GAME := ScreenRouter.FADE_GAME * 2 + 0.15

var _app: ScreenRouter


func before_each() -> void:
	Settings.reset_defaults()
	Settings.apply()
	# As cenas de abertura (008) têm teste próprio; desde a D-098 elas tocam sempre, e este teste
	# as pula (como o jogador faria).
	_app = APP.instantiate()
	add_child_autofree(_app)


func after_each() -> void:
	Codex.reset()
	Codex.load_saved()
	get_tree().paused = false
	TimeScale.reset()
	Settings.reset_defaults()
	Settings.apply()


## Aperta e solta a tecla da ação (a do Settings), entregue pela viewport como o jogador faria.
func _press(action: StringName) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = Settings.binding(action) as Key
		ev.keycode = ev.physical_keycode
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await get_tree().process_frame


func _wait(t: float) -> void:
	await get_tree().create_timer(t, true).timeout


func test_splash_to_first_wave_and_back_from_game_over() -> void:
	assert_eq(_app.current_name, &"splash")
	await _wait(0.5)
	await _press(&"cast")
	await _wait(HOP)
	assert_eq(_app.current_name, &"menu")
	await _press(&"cast")  # Jogar: o livro folheia
	await _wait(0.7 + HOP)
	assert_eq(_app.current_name, &"character")
	await _press(&"cast")  # Anselmo: selo de cera
	await _wait(0.3 + HOP)
	assert_eq(_app.current_name, &"chapter")
	await _press(&"cast")  # Cap. 1
	await _wait(HOP)
	for k: int in 2:  # pula C1-01 e C1-02
		if _app.current_name == &"cutscene":
			(_app.current as CutsceneScreen).player.skip()
			await get_tree().process_frame
			await get_tree().process_frame
	await _wait(HOP_GAME)
	assert_eq(_app.current_name, &"game")
	assert_eq(GameState.wave_index, 1, "primeira onda")
	var overlays: GameOverlays = _app.current.get_node("Overlays")
	overlays._set_mode(GameOverlays.Mode.GAME_OVER)
	overlays.age = GameOverlays.SKIP_AFTER
	await _press(&"cast")  # mostra os botões
	await _press(&"move_right")
	await _press(&"cast")  # Menu
	await _wait(HOP_GAME)
	assert_eq(_app.current_name, &"menu")


func test_language_switch_changes_screens_at_once() -> void:
	_app.goto(&"options")
	var options: Node = _app.current
	while options.focused_row() != &"language":
		options.handle_input(_action(&"move_down"))
	options.handle_input(_action(&"move_right"))
	assert_eq(TranslationServer.get_locale(), "en")
	assert_eq(tr(&"MENU_PLAY"), "PLAY")
	_app.goto(&"menu")
	assert_eq(tr(_app.current.menu.items[0]["label"]), "PLAY", "o Menu já sai em inglês")


func _action(action: StringName) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev
