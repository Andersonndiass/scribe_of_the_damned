extends GutTest
## T720 Opções (007 FR-707, FR-708, SC-702, SC-705; D-066, D-067): ↑/↓ escolhem a linha, ←/→ mudam o
## valor, Espaço ativa; cada mudança vale na hora (Settings.apply) — idioma troca o texto já; o
## remap espera uma tecla e, em conflito, troca as duas ações e avisa.

const SCENE := preload("res://src/ui/screens/options_screen.tscn")

var _screen: Node


func before_each() -> void:
	Settings.reset_defaults()
	Settings.apply()
	_screen = SCENE.instantiate()
	_screen.embedded = true
	add_child_autofree(_screen)


func after_each() -> void:
	Settings.reset_defaults()
	Settings.apply()


func _press(action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	_screen.handle_input(ev)


func _key(code: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = true
	_screen.handle_input(ev)


func _focus(row: StringName) -> void:
	for i: int in _screen.rows.size():
		if _screen.focused_row() == row:
			return
		_press(&"move_down")
	fail_test("linha %s não encontrada" % row)


func test_volume_steps_by_ten_percent() -> void:
	_focus(&"vol_music")
	_press(&"move_left")
	assert_almost_eq(Settings.volume(&"Music"), 0.9, 0.001)
	for i: int in 15:
		_press(&"move_left")
	assert_almost_eq(Settings.volume(&"Music"), 0.0, 0.001, "não passa de 0")


func test_toggles_apply_at_once() -> void:
	_focus(&"shake")
	_press(&"cast")
	assert_false(Settings.shake_enabled)
	assert_false(GameState.shake_enabled, "vale na hora")
	_focus(&"contrast")
	_press(&"move_right")
	assert_true(GameState.high_contrast)
	_focus(&"aim")
	_press(&"cast")
	assert_false(GameState.aim_with_mouse)


func test_language_switches_text_now() -> void:
	_focus(&"language")
	_press(&"move_right")
	assert_eq(Settings.language, "en")
	assert_eq(tr(&"OPTIONS_TITLE"), "OPTIONS", "SC-705: troca na hora")
	_press(&"move_right")
	assert_eq(Settings.language, "pt_BR")


func test_remap_waits_for_key_and_swaps_on_conflict() -> void:
	_focus(&"keys")
	_press(&"cast")
	assert_true(_screen.in_keys)
	# Primeira ação da lista: mover para cima (W). Escolher A (mover para a esquerda) troca as duas.
	_press(&"cast")
	assert_true(_screen.waiting_key)
	_key(KEY_A)
	assert_false(_screen.waiting_key)
	assert_eq(Settings.binding(&"move_up"), KEY_A)
	assert_eq(Settings.binding(&"move_left"), KEY_W, "a outra ação recebe a tecla antiga")
	assert_eq(_screen.swapped_with, [&"move_left"] as Array[StringName], "mostra o aviso da troca")


func test_shared_default_key_swaps_every_owner() -> void:
	# Reiniciar (jogo) e Loja: trocar (loja) dividem o R de fábrica. Desde os contextos (017), pegar
	# o R para mover só empurra o Reiniciar (mesmo contexto); na loja o R continua valendo.
	_focus(&"keys")
	_press(&"cast")
	_press(&"cast")
	_key(KEY_R)
	assert_eq(_screen.swapped_with, [&"restart"] as Array[StringName])
	assert_eq(Settings.binding(&"restart"), KEY_W)
	assert_eq(Settings.binding(&"shop_reroll"), KEY_R, "outro contexto: não é empurrado")


func test_escape_cancels_waiting_and_back_closes() -> void:
	_focus(&"keys")
	_press(&"cast")
	_press(&"cast")
	_key(KEY_ESCAPE)
	assert_false(_screen.waiting_key)
	assert_eq(Settings.binding(&"move_up"), KEY_W, "Esc cancela")
	_press(&"pause")
	assert_false(_screen.in_keys, "Esc sai da lista de teclas")
	watch_signals(_screen)
	_press(&"pause")
	assert_signal_emitted(_screen, "closed")


func test_reset_restores_defaults() -> void:
	Settings.set_volume(&"Master", 0.3)
	Settings.shake_enabled = false
	_focus(&"reset")
	_press(&"cast")
	assert_almost_eq(Settings.volume(&"Master"), 0.3, 0.001, "o primeiro Enter só pede confirmação")
	assert_true(_screen.confirm_reset)
	_press(&"cast")
	assert_almost_eq(Settings.volume(&"Master"), 1.0, 0.001)
	assert_true(Settings.shake_enabled)
