extends GutTest
## D-098 Ajuda de teclas (design-agent UI_HELP_KEYS): cheia nas ondas 1–2, recolhe na onda 3 em
## 4 degraus, H alterna; os rótulos seguem as teclas atuais; fica fora da área central.

var _h: HelpKeys


func before_each() -> void:
	_h = HelpKeys.new()
	add_child_autofree(_h)


func _steps(n: int) -> void:
	for k: int in n:
		_h._process(HelpKeys.STEP_TIME + 0.001)


func test_full_in_first_waves_and_folds_at_wave_3() -> void:
	EventBus.wave_started.emit(1, 60.0)
	assert_eq(_h.stage, 4, "cheia na onda 1")
	EventBus.wave_started.emit(3, 70.0)
	_steps(2)
	assert_eq(_h.stage, 2, "recolhe em degraus")
	_steps(2)
	assert_eq(_h.stage, 0, "só a aba")


func test_toggle_reopens() -> void:
	_h.target = 0
	_steps(4)
	_h.toggle()
	_steps(4)
	assert_eq(_h.stage, 4)


func test_labels_follow_the_bindings() -> void:
	assert_eq(HelpKeys.potions_label(), "3-6", "4 dígitos seguidos viram faixa")
	assert_eq(HelpKeys.label_of("letter_browse"), "<>")
	assert_lte(HelpKeys.move_label().length(), HelpKeys.MAX_GLYPHS)


func test_stays_out_of_the_central_area() -> void:
	var hc: bool = GameState.high_contrast
	GameState.high_contrast = false  # borda de 1 px (no alto contraste é 2)
	assert_false(_h.hud_rect().intersects(Rect2(160, 60, 320, 240)))
	assert_eq(_h.hud_rect(), Rect2(6, 45, 134, 138), "a área que o design-agent reservou")
	GameState.high_contrast = hc
