extends GutTest
## T1633 Entrada dos selos (016 FR-1606, FR-1607; design-agent T1600): 1/2/3, setas + Confirmar,
## clique no selo; nada vale na trava; Esc não é dos selos; a barra de Graça reage ao EventBus.

const MAIN_SCENE := preload("res://src/main/main.tscn")
const IGNIS := preload("res://data/words/ignis.tres")

var _main: Node2D
var _flow: GraceFlow
var _seals: GraceSeals
var _chosen: Array[StringName] = []


func before_each() -> void:
	_chosen.clear()
	_main = MAIN_SCENE.instantiate()
	_main.set_meta(&"grace_manual", true)
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	(_main.get_node("World/Player") as Player).auto_attack.enabled = false
	_flow = _main.get_node("GraceFlow")
	_flow.beam_enabled = false  # o feixe (018) tem teste próprio
	_seals = _main.get_node("GraceSeals")
	EventBus.blessing_chosen.connect(_on_chosen)


func after_each() -> void:
	EventBus.blessing_chosen.disconnect(_on_chosen)
	get_tree().paused = false


func _on_chosen(b: BlessingData, _l: int) -> void:
	_chosen.append(b.id)


func _wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout


func _open_and_unlock() -> void:
	EventBus.word_cast.emit(IGNIS, 1.0, Vector2.ZERO, Vector2.RIGHT)
	await _wait(0.05)
	await _wait(_flow.tuning.announce_time + _flow.tuning.pick_guard + 0.1)


func _key(action: StringName) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = Settings.binding(action) as Key
	ev.keycode = ev.physical_keycode
	ev.pressed = true
	return ev


func test_the_order_puts_the_seals_before_the_overlays() -> void:
	assert_lt(_seals.get_index(), _main.get_node("Overlays").get_index(), "a Pausa recebe a entrada primeiro")


func test_number_key_picks_that_seal() -> void:
	await _open_and_unlock()
	var want: StringName = _flow.offer[2].id
	_seals._unhandled_input(_key(&"grace_pick_3"))
	assert_eq(_chosen, [want] as Array[StringName])


func test_keys_do_nothing_while_locked() -> void:
	EventBus.word_cast.emit(IGNIS, 1.0, Vector2.ZERO, Vector2.RIGHT)
	await _wait(0.05)
	await _wait(_flow.tuning.announce_time + 0.05)
	_seals._unhandled_input(_key(&"grace_pick_1"))
	assert_eq(_chosen.size(), 0, "trava de 0,4 s")


func test_arrows_and_confirm() -> void:
	await _open_and_unlock()
	_seals._unhandled_input(_key(&"move_right"))
	assert_eq(_seals.focus, 1)
	var want: StringName = _flow.offer[1].id
	_seals._unhandled_input(_key(&"cast"))
	assert_eq(_chosen, [want] as Array[StringName])


func test_click_on_a_seal() -> void:
	await _open_and_unlock()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(_seals.card_x(0) + 60, GraceSeals.CARD_Y + 60)
	var want: StringName = _flow.offer[0].id
	_seals._unhandled_input(click)
	assert_eq(_chosen, [want] as Array[StringName])


func test_escape_is_not_taken_by_the_seals() -> void:
	await _open_and_unlock()
	Input.parse_input_event(_key(&"pause"))
	await _wait(0.1)
	var overlays: GameOverlays = _main.get_node("Overlays")
	assert_eq(overlays.mode, GameOverlays.Mode.PAUSED, "o Esc abre a Pausa por cima dos selos")
	assert_eq(_chosen.size(), 0)
	overlays.toggle_pause()


func test_grace_bar_follows_the_bus() -> void:
	var bar: GraceBar = _main.get_node("Hud/GraceBar")
	EventBus.grace_changed.emit(18, 36, 4)
	assert_eq(bar.level, 4)
	assert_almost_eq(bar.fraction, 0.5, 0.001)
	assert_false(bar.hud_rect().intersects(Rect2(160, 60, 320, 240)), "fora da área central")
