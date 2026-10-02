extends GutTest
## T070–T078 HUD, degradação, pausa e Game Over na cena principal (FR-005, FR-023..FR-026).

const MAIN_SCENE := preload("res://src/main/main.tscn")
const SAFE_RECT := Rect2(160, 60, 320, 240)

var _main: Node2D
var _player: Player
var _field: LetterField
var _caster: Caster
var _hud: CanvasLayer
var _overlays: GameOverlays
var _arena: Arena


func before_each() -> void:
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_field = _main.get_node("World/LetterField")
	_caster = _main.get_node("Caster")
	_hud = _main.get_node("Hud")
	_overlays = _main.get_node("Overlays")
	_arena = _main.get_node("Arena")


func after_each() -> void:
	get_tree().paused = false
	TimeScale.reset()
	Input.action_release(&"word_list")


func test_hud_never_covers_the_central_area() -> void:
	for child: Node in _hud.get_children():
		assert_true(child.has_method(&"hud_rect"), "%s declara sua área" % child.name)
		var r: Rect2 = child.call(&"hud_rect")
		assert_false(r.intersects(SAFE_RECT), "%s %s invade X160–480 Y60–300" % [child.name, r])


## T1800: todo painel a ≥ 6 px da borda da tela e sem cobrir outro (menos os que moram juntos).
func test_hud_panels_keep_the_margin_and_do_not_overlap() -> void:
	# A lista de palavras (TAB) esconde a ajuda de teclas (D-098): nunca aparecem juntas.
	var together: Array = [["Candles", "GraceBar"], ["WaveTimer", "BossBar"], ["Atril", "ComboWindow"], ["WordList", "HelpKeys"]]
	var screen := Rect2(UiStyle.HUD_MARGIN, UiStyle.HUD_MARGIN, 640 - 2 * UiStyle.HUD_MARGIN, 360 - 2 * UiStyle.HUD_MARGIN)
	var was_high: bool = GameState.high_contrast
	GameState.high_contrast = false  # no alto contraste a borda tem 2 px (margem 5)
	var kids: Array[Node] = _hud.get_children()
	for a: Node in kids:
		var ra: Rect2 = a.call(&"hud_rect")
		assert_true(screen.encloses(ra), "%s %s fica a 6 px da borda" % [a.name, ra])
		for b: Node in kids:
			var pair: Array = [String(a.name), String(b.name)]
			if a == b or together.has(pair) or together.has([pair[1], pair[0]]):
				continue
			var rb: Rect2 = b.call(&"hud_rect")
			assert_false(ra.intersects(rb), "%s %s cobre %s %s" % [a.name, ra, b.name, rb])
	GameState.high_contrast = was_high


func test_atril_view_follows_atril_state_and_hints() -> void:
	var view: HudAtril = _hud.get_node("Atril")
	_field.collect("L", false)
	_field.collect("U", true)
	assert_eq(view.letters, PackedStringArray(["L", "U"]))
	assert_eq(view.status, Atril.Status.PARTIAL)
	assert_eq(view.rare_mask, 0b10, "U é rara")
	assert_has(view.hints, "LUX")
	_field.collect("X", false)
	assert_eq(view.status, Atril.Status.VALID)


func test_atril_view_slots_follow_capacity() -> void:
	var view: HudAtril = _hud.get_node("Atril")
	var five: float = view.slots_rect().size.x
	_field.atril.set_capacity(8)
	_field.emit_atril()
	assert_gt(view.slots_rect().size.x, five)


func test_heresy_plays_animation() -> void:
	var view: HudAtril = _hud.get_node("Atril")
	_field.collect("L", false)
	_field.collect("Q", false)
	_caster.cast()
	assert_eq(view.anim, HudAtril.Anim.HERESY)


func test_word_list_shows_while_tab_is_held() -> void:
	var list: HudWordList = _hud.get_node("WordList")
	assert_false(list.visible)
	Input.action_press(&"word_list")
	await wait_process_frames(2)
	assert_true(list.visible)
	Input.action_release(&"word_list")
	await wait_process_frames(2)
	assert_false(list.visible)


func test_timer_counts_down_and_shows_wave() -> void:
	var timer: HudWaveTimer = _hud.get_node("WaveTimer")
	assert_eq(timer.wave_index, 1)
	assert_eq(timer.time_text(), "1:00")
	await wait_seconds(1.1)
	assert_eq(timer.time_text(), "0:59")


func test_hud_starts_with_three_candle_slots() -> void:
	var candles: HudCandles = _hud.get_node("Candles")
	await wait_process_frames(2)
	assert_eq(candles._max, 3, "começa com 3 espaços de vela, não com o teto de 8")
	assert_eq(candles._candles, 3)


func test_candles_mirror_game_state() -> void:
	var candles: HudCandles = _hud.get_node("Candles")
	_player.take_hit(1)
	await wait_process_frames(2)
	assert_eq(candles._candles, 2)
	assert_eq(candles._max, 3)


func test_degradation_follows_the_chapter_and_never_goes_back() -> void:
	# SC-401: o estágio vem das ondas (0,0,1,1,2,2,3,3,3), é revelado no fim da onda e nunca volta.
	var chapter: ChapterData = _main.chapter
	assert_eq(_arena.degradation_stage, chapter.stage_for_wave(0))
	var seen: Array[int] = []
	for slot: int in chapter.waves.size():
		_main.wave_slot = slot
		EventBus.wave_ended.emit(slot + 1)
		_arena.page.snap()
		seen.append(_arena.degradation_stage)
		assert_eq(_arena.degradation_stage, chapter.stage_after(slot))
	for i: int in range(1, seen.size()):
		assert_true(seen[i] >= seen[i - 1], "o estágio não volta (%s)" % [seen])
	assert_eq(seen[-1], chapter.boss_stage)


func test_closing_threatens_only_when_the_page_will_worsen() -> void:
	# Onda 1 → 2: estágio 0 → 0, sem ameaça; onda 2 → 3: 0 → 1, ameaça.
	EventBus.wave_closing.emit(1, 10.0)
	assert_false(_arena.page.threatened())
	_main.start_wave(1)
	EventBus.wave_closing.emit(2, 10.0)
	assert_true(_arena.page.threatened())


func test_arena_registers_the_obstacle_map() -> void:
	assert_not_null(ObstacleQuery.map)
	assert_false(ObstacleQuery.is_free(Vector2(80, 80), 5.0), "o furo do Cap. 1 está na página")


func test_enemy_death_leaves_a_permanent_stain() -> void:
	var before: int = _arena.stamp_count
	EventBus.enemy_killed.emit(0, load("res://data/enemies/imp.tres"), Vector2(100, 100))
	assert_eq(_arena.stamp_count, before + 1)


func test_pause_toggles_tree() -> void:
	_overlays.toggle_pause()
	assert_true(get_tree().paused)
	assert_eq(_overlays.mode, GameOverlays.Mode.PAUSED)
	_overlays.toggle_pause()
	assert_false(get_tree().paused)


func test_game_over_appears_after_death_and_offers_restart() -> void:
	watch_signals(_overlays)
	for i: int in 3:
		_player.vitals.iframes_left = 0.0
		_player.take_hit(1)
	assert_eq(_player.machine.current.name, &"Dead")
	await get_tree().create_timer(0.8, true).timeout
	assert_eq(_overlays.mode, GameOverlays.Mode.GAME_OVER)
	_overlays.toggle_pause()
	assert_eq(_overlays.mode, GameOverlays.Mode.GAME_OVER, "não dá para pausar o Game Over")
	_overlays.restart()
	assert_signal_emitted(_overlays, "restart_requested")


# --- 007 T712: pausa, Game Over e Vitória ----------------------------------------------------

func _press(action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	_overlays._unhandled_input(ev)


func test_pause_opens_options_on_top_and_returns() -> void:
	_press(&"pause")
	_press(&"move_down")
	_press(&"move_down")
	assert_eq(_overlays.menu.focused_id(), &"options")
	_press(&"cast")
	assert_not_null(_overlays.subscreen, "Opções abertas por cima da pausa")
	assert_true(get_tree().paused, "o jogo segue parado")
	_overlays.subscreen.handle_input(_action(&"pause"))
	await get_tree().process_frame
	assert_null(_overlays.subscreen)
	assert_eq(_overlays.mode, GameOverlays.Mode.PAUSED, "volta à pausa")


func _action(action: StringName) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev


func test_pause_menu_resumes() -> void:
	_press(&"pause")
	assert_eq(_overlays.mode, GameOverlays.Mode.PAUSED)
	assert_eq(_overlays.menu.focused_id(), &"resume")
	_press(&"move_down")
	assert_eq(_overlays.menu.focused_id(), &"codex")
	_press(&"move_up")
	_press(&"cast")
	assert_eq(_overlays.mode, GameOverlays.Mode.NONE)
	assert_false(get_tree().paused)


func test_game_over_shows_stats_and_buttons_later() -> void:
	EventBus.word_cast.emit(load("res://data/words/lux.tres"), 1.0, Vector2.ZERO, Vector2.RIGHT)
	_overlays._set_mode(GameOverlays.Mode.GAME_OVER)
	assert_false(_overlays.buttons_shown, "os botões esperam 3,5 s")
	assert_eq(_overlays._record["words"], 1)
	_press(&"cast")
	assert_false(_overlays.buttons_shown, "antes de 400 ms a tecla não adianta")
	_overlays.age = GameOverlays.SKIP_AFTER
	_press(&"cast")
	assert_true(_overlays.buttons_shown)
	assert_eq(_overlays.menu.focused_id(), &"retry")
	watch_signals(_overlays)
	_press(&"cast")
	assert_signal_emitted(_overlays, "restart_requested")


func test_victory_lists_new_codex_entries() -> void:
	Codex.reset()
	Codex.begin_run()
	EventBus.boss_spawned.emit(load("res://data/bosses/asmodeus.tres"))
	_overlays.show_victory()
	assert_eq(_overlays.mode, GameOverlays.Mode.VICTORY)
	assert_true(get_tree().paused)
	assert_has(_overlays._entries, tr(&"BOSS_ASMODEUS"))


# --- 002 T214: janela de combo ---------------------------------------------------------------

func _write(word: String) -> void:
	_field.atril.set_capacity(6)
	for ch: String in word:
		_field.collect(ch, false)


func test_combo_window_bar_waits_then_shrinks_in_steps() -> void:
	var bar: HudComboWindow = _hud.get_node("ComboWindow")
	_write("LUX")
	assert_true(_caster.cast())
	assert_true(bar.open)
	assert_eq(bar.fill_width(), HudComboWindow.BAR.size.x, "cheia até a 1ª letra")
	_field.collect("P", false)
	bar._process(1.25)
	var w: float = bar.fill_width()
	assert_eq(w, HudComboWindow.BAR.size.x / 2.0, "metade em 1,25 s")
	assert_eq(fmod(w, HudComboWindow.BAR.size.x / HudComboWindow.STEPS), 0.0, "passos de 4 px")


func test_combo_ready_and_partner_hints() -> void:
	var atril: HudAtril = _hud.get_node("Atril")
	_write("LUX")
	_caster.cast()
	assert_has(atril.combo_partners, "PAX")
	assert_has(atril.combo_partners, "IGNIS")
	assert_does_not_have(atril.combo_partners, "LUX")
	_write("PAX")
	assert_true(atril.is_combo_ready(), "PAX fecha CAECITAS")


func test_combo_name_shows_and_window_closes() -> void:
	var bar: HudComboWindow = _hud.get_node("ComboWindow")
	_write("LUX")
	_caster.cast()
	_write("PAX")
	_caster.cast()
	assert_eq(bar.shown_name, "CAECITAS")
	assert_false(bar.open, "combo não encadeia")
	bar._process(HudComboWindow.NAME_TIME + 0.01)
	assert_eq(bar.shown_name, "", "corte seco depois de 1 s")
