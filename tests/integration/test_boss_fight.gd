extends GutTest
## T614 A luta contra Asmodeus na cena real (006 FR-605..FR-613, SC-601, SC-604..SC-606, SC-609).
## Os tempos de entrada/morte são encurtados numa cópia do BossData para o teste não demorar.

const MAIN_SCENE := preload("res://src/main/main.tscn")
const BOSS := preload("res://data/bosses/asmodeus.tres")

var _main: Node2D
var _boss: Boss
var _player: Player
var _field: LetterField
var _caster: Caster
var _events: Array[StringName] = []


func before_each() -> void:
	_events.clear()
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_boss = _main.get_node("World/Boss")
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_field = _main.get_node("World/LetterField")
	_field.atril.set_capacity(8)
	_caster = _main.get_node("Caster")
	var fast: BossData = BOSS.duplicate()
	fast.enter_time = 0.1
	fast.enter_rise_start = 0.0
	fast.enter_rise_end = 0.05
	fast.death_time = 0.2
	fast.death_burst_at = 0.1
	fast.chapter_end_delay = 0.2
	var ch: ChapterData = _main.get("chapter").duplicate()
	ch.boss = fast
	_main.set("chapter", ch)
	EventBus.boss_phase_changed.connect(_on_phase)
	EventBus.boss_defeated.connect(_on_defeated)
	EventBus.chapter_completed.connect(_on_completed)
	EventBus.player_died.connect(_on_player_died)


func after_each() -> void:
	EventBus.boss_phase_changed.disconnect(_on_phase)
	EventBus.boss_defeated.disconnect(_on_defeated)
	EventBus.chapter_completed.disconnect(_on_completed)
	EventBus.player_died.disconnect(_on_player_died)
	TimeScale.reset()


func _on_phase(_i: int) -> void:
	_events.append(&"phase")


func _on_defeated(_b: BossData) -> void:
	_events.append(&"defeated")


func _on_completed(_c: int) -> void:
	_events.append(&"completed")


func _on_player_died() -> void:
	_events.append(&"player_died")


func _start() -> void:
	_main.call("start_boss")
	await wait_seconds(0.3)


func test_boss_enters_then_becomes_targetable() -> void:
	_main.call("start_boss")
	assert_eq(_boss.state_name(), &"Enter")
	assert_false(_boss.is_targetable(), "invulnerável na entrada")
	await wait_seconds(0.3)
	assert_true(_boss.is_targetable())
	assert_ne(_boss.state_name(), &"Enter")


func test_words_hurt_the_boss() -> void:
	await _start()
	_player.global_position = _boss.global_position + Vector2(0, 60)
	_player.facing = Vector2.UP
	var before: int = _boss.filter.hp
	for ch: String in "LUX":
		_field.collect(ch, false)
	assert_true(_caster.cast())
	assert_lt(_boss.filter.hp, before, "LUX feriu o chefe")


func test_crossing_the_threshold_shifts_phase() -> void:
	await _start()
	_boss.filter.hp = 1000
	_boss.take(100, &"mortis", 999)
	assert_eq(_boss.filter.phase_index, 1)
	assert_eq(_boss.state_name(), &"PhaseShift")
	assert_has(_events, &"phase")
	assert_eq(_boss.phase(), BOSS.phases[1], "agora os ataques são os da F2 (SC-601)")


func test_killing_the_boss_completes_the_chapter() -> void:
	await _start()
	_boss.filter.phase_index = 2
	_boss.filter.hp = 10
	_boss.take(50, &"mortis", 1)
	assert_eq(_boss.state_name(), &"Dead")
	await wait_seconds(0.6)
	assert_has(_events, &"defeated")
	assert_has(_events, &"completed", "SC-606")


func test_dying_in_the_fight_is_the_normal_game_over() -> void:
	await _start()
	while _player.vitals.is_alive():
		_player.vitals.iframes_left = 0.0
		_player.take_hit(2, &"boss")
	assert_has(_events, &"player_died", "SC-609")


func test_every_attack_telegraphs_at_least_the_minimum() -> void:
	for phase: PhaseData in BOSS.phases:
		for a: AttackData in phase.attacks:
			assert_true(a.telegraph >= BOSS.min_telegraph - 0.0001, "%s ≥ %.1f s (SC-605)" % [a.id, BOSS.min_telegraph])


func test_beam_hits_the_scribe_in_its_line() -> void:
	await _start()
	var beam: AttackData = BOSS.phases[0].attacks[0]
	var candles: int = _player.vitals.candles
	_player.vitals.iframes_left = 0.0
	_boss.machine.transition_to(&"Telegraph", {"attack": beam})
	await wait_seconds(beam.telegraph + beam.active + 0.1)
	assert_lt(_player.vitals.candles, candles, "o Raio mirado no escriba acertou")


func test_erasure_respects_the_protections() -> void:
	await _start()
	_field.collect("L", false)
	_field.collect("U", false)
	EventBus.atril_erase_requested.emit()
	assert_eq(_field.atril.size(), 2, "letra pega agora há pouco: protegida")
	await wait_seconds(0.6)
	EventBus.atril_erase_requested.emit()
	assert_eq(_field.atril.text(), "L", "apagou a última")
	_field.collect("U", false)
	_field.collect("X", false)
	await wait_seconds(0.6)
	EventBus.atril_erase_requested.emit()
	assert_eq(_field.atril.text(), "LUX", "palavra pronta nunca é apagada")


func test_letter_safety_opens_a_menu_when_none_opened_for_a_while() -> void:
	await _start()
	_player.vitals.iframes_left = 1.0e6  # a espera é longa: o chefe não pode matar o escriba no teste
	var opened: Array[int] = [0]
	var on_open := func(_o: Array) -> void: opened[0] += 1
	EventBus.letter_menu_opened.connect(on_open)
	var tuning: LetterSafetyTuning = load("res://data/tuning/letter_safety.tres")
	await wait_seconds(tuning.wait + 2.0)
	EventBus.letter_menu_opened.disconnect(on_open)
	assert_gt(opened[0], 0, "SC-604: abriu um menu de segurança")
