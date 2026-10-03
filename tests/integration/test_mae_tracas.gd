extends GutTest
## 012 F4 (FR-1209, FR-1211, FR-1213, SC-1206; T1200 §4): a Mãe das Traças — telegrafia ≥ 600 ms,
## rajada fere e empurra (sem atravessar a parede), nuvem deixa poça, enxame respeita o teto, sem
## janela de exposição, chance de letra da luta, corpo 80×64 em dados.

const MAIN_SCENE := preload("res://src/main/main.tscn")
const MAE: BossData = preload("res://data/bosses/mae_tracas.tres")
const CH2: ChapterData = preload("res://data/chapters/chapter_2.tres")

var _main: Node2D
var _boss: Boss
var _player: Player
var _manager: EnemyManager


func before_each() -> void:
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
	_manager = _main.get_node("World/EnemyManager")


func after_each() -> void:
	TimeScale.reset()


func _start() -> void:
	_main.call("start_boss")
	await wait_seconds(0.3)


func _run(attack: AttackData) -> void:
	_boss.machine.transition_to(&"Telegraph", {"attack": attack})
	await wait_seconds(attack.telegraph + attack.active + 0.1)


func test_chapter_2_has_the_mother_as_boss() -> void:
	assert_eq(CH2.boss, MAE)
	assert_true(MAE.words_only)
	assert_eq(MAE.sprite_size, Vector2i(80, 64))
	assert_eq(MAE.exposed_time, 0.0, "FR-1213: sem janela de exposição")


func test_every_attack_telegraphs_at_least_the_minimum() -> void:
	for phase: PhaseData in MAE.phases:
		for a: AttackData in phase.attacks:
			assert_true(a.telegraph >= MAE.min_telegraph - 0.0001, "%s ≥ %.1f s (SC-1206)" % [a.id, MAE.min_telegraph])


func test_fight_uses_its_own_letter_chance() -> void:
	GameState.letter_drop_mul = 0.18
	await _start()
	assert_eq(GameState.letter_drop_mul, MAE.letter_drop_mul)


func test_gust_hurts_and_pushes_away() -> void:
	await _start()
	_player.global_position = _boss.global_position + Vector2(0, 70)
	_player.vitals.iframes_left = 0.0
	var candles: int = _player.vitals.candles
	var y0: float = _player.global_position.y
	await _run(MAE.phases[0].attacks[0])
	await wait_seconds(0.25)
	assert_lt(_player.vitals.candles, candles, "a rajada feriu")
	assert_gt(_player.global_position.y, y0 + 20.0, "empurrado para longe da Mãe")


func test_gust_does_not_push_through_the_wall() -> void:
	await _start()
	_player.global_position = Vector2(_boss.global_position.x, Arena.PLAYABLE.end.y - 8.0)
	_boss.global_position = _player.global_position - Vector2(0, 110)
	await _run(MAE.phases[0].attacks[0])
	await wait_seconds(0.3)
	assert_true(Arena.PLAYABLE.grow(1.0).has_point(_player.global_position), "a parede segura")


func test_dust_cloud_leaves_a_puddle() -> void:
	await _start()
	var hz: HazardField = _manager.get_hazards()
	var before: int = hz.count
	var dust: AttackData = MAE.phases[1].attacks[2]
	assert_eq(dust.kind, &"dust")
	await _run(dust)
	assert_eq(hz.count, before + 1)
	assert_lt(hz.slow_at(_player.global_position), 1.0, "a poça cai onde o escriba estava")


func test_swarm_respects_its_cap() -> void:
	await _start()
	var swarm: AttackData = MAE.phases[1].attacks[1]
	for k: int in 3:
		await _run(swarm)
	assert_lte(_manager.count_of(swarm.summon_enemy), swarm.summon_max_alive)
	assert_gt(_manager.count_of(swarm.summon_enemy), 0)
