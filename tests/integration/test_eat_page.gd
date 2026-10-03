extends GutTest
## 012 F5 (FR-1212, SC-1203/1204): Eat_Page na luta — só na F3 por relógio; palavra no aviso cancela;
## arma não cancela; sem cancelamento a área encolhe e todos ficam dentro e fora das peças; a
## página volta inteira na luta seguinte.

const MAIN_SCENE := preload("res://src/main/main.tscn")
const MAE: BossData = preload("res://data/bosses/mae_tracas.tres")
const CH2: ChapterData = preload("res://data/chapters/chapter_2.tres")
const IMP := preload("res://data/enemies/imp.tres")

var _main: Node2D
var _boss: Boss
var _player: Player
var _manager: EnemyManager
var _cancelled: Array = []


func before_each() -> void:
	_cancelled.clear()
	_main = MAIN_SCENE.instantiate()
	var ch: ChapterData = CH2.duplicate()
	var fast: BossData = MAE.duplicate()
	fast.enter_time = 0.1
	fast.enter_rise_start = 0.0
	fast.enter_rise_end = 0.05
	ch.boss = fast
	_main.set("chapter", ch)
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_boss = _main.get_node("World/Boss")
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_player.vitals.iframes_left = 1.0e6
	_manager = _main.get_node("World/EnemyManager")
	EventBus.page_bite_cancelled.connect(_on_cancel)


func after_each() -> void:
	EventBus.page_bite_cancelled.disconnect(_on_cancel)
	PlayArea.reset()
	TimeScale.reset()


func _on_cancel(_side: StringName, reason: StringName) -> void:
	_cancelled.append(reason)


func _eat() -> AttackData:
	return MAE.phases[2].timed_attack


func _start() -> void:
	_main.call("start_boss")
	await wait_seconds(0.3)


func test_eat_page_only_in_phase_3() -> void:
	assert_null(MAE.phases[0].timed_attack)
	assert_null(MAE.phases[1].timed_attack)
	assert_eq(_eat().kind, &"eat_page")
	assert_gte(_eat().telegraph, 0.6)


func test_word_in_the_warning_cancels_the_bite() -> void:
	await _start()
	_boss.machine.transition_to(&"Telegraph", {"attack": _eat()})
	await wait_seconds(0.3)
	_boss.take(5, &"auto", 0)
	assert_eq(_boss.state_name(), &"Telegraph", "arma não cancela (e é imune)")
	_boss.take(20, &"lux", 77)
	assert_eq(_cancelled, [&"word"])
	await wait_seconds(_eat().telegraph + _eat().active)
	assert_false(PlayArea.is_shrunk(), "a página ficou inteira")


func test_uncancelled_bite_shrinks_and_pushes_everyone_inside() -> void:
	await _start()
	_player.global_position = Vector2(40, 200)  # na faixa da esquerda
	var j: int = _manager.spawn(IMP, Vector2(36, 300))
	_manager.stun_left[j] = 10.0  # atordoado também é empurrado
	_boss.machine.transition_to(&"Telegraph", {"attack": _eat()})
	await wait_seconds(_eat().telegraph + _eat().active + 0.2)
	assert_true(PlayArea.is_shrunk(), "comeu uma borda")
	var r: Rect2 = PlayArea.rect
	assert_true(r.grow(0.5).has_point(_player.global_position), "escriba dentro")
	for i: int in _manager.count:
		assert_true(r.grow(0.5).has_point(_manager.positions[i]), "inimigo dentro")
	assert_true(ObstacleQuery.is_free(_player.global_position, _player.data.hurtbox_radius), "fora das peças")


func test_bites_never_go_below_the_minimum() -> void:
	await _start()
	for k: int in 8:
		_boss.machine.transition_to(&"Telegraph", {"attack": _eat()})
		await wait_seconds(_eat().telegraph + _eat().active + 0.05)
	assert_true(PlayArea.rect.size.x >= 400.0 - 0.01 and PlayArea.rect.size.y >= 220.0 - 0.01)


func test_new_fight_restores_the_page() -> void:
	PlayArea.shrink_to(Rect2(120, 24, 400, 220))
	var m: Node2D = MAIN_SCENE.instantiate()
	add_child_autofree(m)
	assert_false(PlayArea.is_shrunk())
