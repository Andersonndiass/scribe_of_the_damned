extends GutTest
## T070–T078 HUD, degradação, pausa e Game Over na cena principal (FR-005, FR-023..FR-026).

const MAIN_SCENE := preload("res://src/main/main.tscn")
const SAFE_RECT := Rect2(160, 60, 320, 240)

var _main: Node2D
var _player: Player
var _field: LetterField
var _caster: Caster
var _hud: CanvasLayer
var _overlays: MinimalOverlays
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
	Engine.time_scale = 1.0
	Input.action_release(&"word_list")


func test_hud_never_covers_the_central_area() -> void:
	for child: Node in _hud.get_children():
		assert_true(child.has_method(&"hud_rect"), "%s declara sua área" % child.name)
		var r: Rect2 = child.call(&"hud_rect")
		assert_false(r.intersects(SAFE_RECT), "%s %s invade X160–480 Y60–300" % [child.name, r])


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


func test_degradation_advances_each_wave_and_loops() -> void:
	assert_eq(_arena.degradation_stage, 0)
	for expected: int in [1, 2, 3, 0]:
		EventBus.wave_ended.emit(9)
		assert_eq(_arena.degradation_stage, expected)


func test_enemy_death_leaves_a_permanent_stain() -> void:
	var before: int = _arena.stamp_count
	EventBus.enemy_killed.emit(0, load("res://data/enemies/imp.tres"), Vector2(100, 100))
	assert_eq(_arena.stamp_count, before + 1)


func test_pause_toggles_tree() -> void:
	_overlays.toggle_pause()
	assert_true(get_tree().paused)
	assert_eq(_overlays.mode, MinimalOverlays.Mode.PAUSED)
	_overlays.toggle_pause()
	assert_false(get_tree().paused)


func test_game_over_appears_after_death_and_offers_restart() -> void:
	watch_signals(_overlays)
	for i: int in 3:
		_player.vitals.iframes_left = 0.0
		_player.take_hit(1)
	assert_eq(_player.machine.current.name, &"Dead")
	await wait_seconds(0.8)
	assert_eq(_overlays.mode, MinimalOverlays.Mode.GAME_OVER)
	_overlays.toggle_pause()
	assert_eq(_overlays.mode, MinimalOverlays.Mode.GAME_OVER, "não dá para pausar o Game Over")
	_overlays.restart()
	assert_signal_emitted(_overlays, "restart_requested")
