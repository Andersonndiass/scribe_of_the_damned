extends GutTest
## T824 Cutscenes no jogo (008 SC-802, SC-805; FR-807–FR-810): Capítulo → C1-01 → C1-02 → onda 1 na
## primeira vez e direto nas seguintes; C1-03 pulada solta o chefe já lutando (boss_spawned uma vez);
## C1-04 pulada leva à Vitória; o Esc dentro da cena não abre a Pausa.

const APP := preload("res://src/app/app.tscn")
const HOP := ScreenRouter.FADE_MENU * 2 + 0.15
const HOP_GAME := ScreenRouter.FADE_GAME * 2 + 0.15

var _app: ScreenRouter
var _boss_spawns: int = 0


func before_each() -> void:
	Codex.reset()
	_boss_spawns = 0
	EventBus.boss_spawned.connect(_on_boss_spawned)
	_app = APP.instantiate()
	add_child_autofree(_app)


func after_each() -> void:
	EventBus.boss_spawned.disconnect(_on_boss_spawned)
	Codex.reset()
	Codex.load_saved()
	get_tree().paused = false
	TimeScale.reset()


func _on_boss_spawned(_b: BossData) -> void:
	_boss_spawns += 1


func _wait(t: float) -> void:
	await get_tree().create_timer(t, true).timeout


func _press_key(action: StringName) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = Settings.binding(action) as Key
		ev.keycode = ev.physical_keycode
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await get_tree().process_frame


func _choose_chapter_1() -> void:
	_app.goto(&"chapter")
	await get_tree().process_frame
	await _press_key(&"cast")


func test_intro_plays_the_first_time_then_goes_straight_to_the_game() -> void:
	await _choose_chapter_1()
	await _wait(HOP)
	assert_eq(_app.current_name, &"cutscene", "primeira vez: as cenas de abertura")
	var screen: CutsceneScreen = _app.current
	await get_tree().process_frame
	assert_eq(screen.player.cutscene_id, &"c1_01")
	screen.player.skip()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(screen.player.cutscene_id, &"c1_02", "corte direto para a C1-02")
	screen.player.skip()
	await _wait(HOP_GAME)
	assert_eq(_app.current_name, &"game")
	assert_true(Codex.cutscene_seen(&"c1_01") and Codex.cutscene_seen(&"c1_02"), "vistas ficam gravadas")
	# Segunda vez: direto para a partida.
	await _choose_chapter_1()
	await _wait(HOP_GAME)
	assert_eq(_app.current_name, &"game", "segunda vez: sem as cenas 'once'")


func test_boss_cutscene_releases_the_boss_fighting() -> void:
	_app.goto(&"game")
	var main: Node = _app.current
	await get_tree().process_frame
	assert_not_null(main.boss_cutscene, "a C1-03 está carregada na partida de verdade")
	main.start_boss()
	assert_true(get_tree().paused, "o jogo para durante a cena")
	assert_true(main.boss_cutscene.is_playing())
	await _press_key(&"pause")
	assert_eq(main.overlays.mode, GameOverlays.Mode.NONE, "o Esc da cena não abre a Pausa")
	main.boss_cutscene.skip()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_false(get_tree().paused)
	assert_true(main.boss.targetable, "o chefe já pode apanhar")
	assert_eq(main.boss.state_name(), &"Idle", "sem a animação de entrada")
	assert_eq(_boss_spawns, 1, "boss_spawned uma vez só")


func test_outro_cutscene_then_victory() -> void:
	_app.goto(&"game")
	var main: Node = _app.current
	await get_tree().process_frame
	EventBus.chapter_completed.emit(1)
	await get_tree().process_frame
	assert_true(main.outro_cutscene.is_playing(), "a C1-04 antes da Vitória")
	main.outro_cutscene.skip()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(main.overlays.mode, GameOverlays.Mode.VICTORY)
