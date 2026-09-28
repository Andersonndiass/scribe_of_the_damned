extends GutTest
## 005 T520 [TEST-FIRST] Campeões e tinta dourada (FR-509..FR-512, D-011, D-019).

const MAIN_SCENE := preload("res://src/main/main.tscn")
const IMP := preload("res://data/enemies/imp.tres")
const TUNING := preload("res://data/tuning/champion.tres")

var _main: Node2D
var _player: Player
var _m: EnemyManager
var _gold: GoldInkField
var _champion_kills: int = 0
var _hitstops: Array[int] = []


func before_each() -> void:
	_champion_kills = 0
	_hitstops.clear()
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_m = _main.get_node("World/EnemyManager")
	_m.dissolve_all()
	_gold = _main.get_node("World/GoldInkField")
	EventBus.champion_killed.connect(_on_champion)
	EventBus.hitstop_requested.connect(_on_hitstop)


func after_each() -> void:
	EventBus.champion_killed.disconnect(_on_champion)
	EventBus.hitstop_requested.disconnect(_on_hitstop)
	Engine.time_scale = 1.0


func _on_champion(_d: EnemyData, _p: Vector2) -> void:
	_champion_kills += 1


func _on_hitstop(ms: int) -> void:
	_hitstops.append(ms)


func test_champion_multipliers() -> void:
	var i: int = _m.spawn(IMP, Vector2(100, 100), true)
	assert_eq(_m.hp[i], roundi(IMP.max_hp * TUNING.hp_mul))
	assert_almost_eq(_m.speed_mul[i], TUNING.speed_mul, 0.001)
	assert_almost_eq(_m.radius_of[i], IMP.radius * TUNING.radius_mul, 0.001)
	var n: int = _m.spawn(IMP, Vector2(200, 100))
	assert_eq(_m.hp[n], IMP.max_hp, "inimigo comum não muda")


func test_champion_death_rewards() -> void:
	_player.take_hit(1)
	assert_eq(_player.vitals.candles, 2)
	var i: int = _m.spawn(IMP, Vector2(500, 300), true)
	_m.damage_at(i, 999)
	assert_eq(_champion_kills, 1)
	assert_eq(_player.vitals.candles, 3, "+1 vela (D-011)")
	assert_between(_gold.active_count(), TUNING.gold_drops_min, TUNING.gold_drops_max, "3–5 gotas")
	assert_has(_hitstops, TUNING.death_hitstop_ms, "hit-stop de 40 ms")


func test_common_enemy_death_gives_no_champion_reward() -> void:
	var i: int = _m.spawn(IMP, Vector2(500, 300))
	_m.damage_at(i, 999)
	assert_eq(_champion_kills, 0)
	assert_eq(_gold.active_count(), 0)


func test_gold_is_magnetized_and_collected() -> void:
	var before: int = GameState.gold_ink
	_gold.spawn_drops(3, _player.global_position + Vector2(25, 0))
	await wait_seconds(1.0)
	assert_eq(GameState.gold_ink, before + 3)
	assert_eq(_gold.active_count(), 0)


func test_leftover_gold_is_collected_at_wave_end() -> void:
	var before: int = GameState.gold_ink
	_gold.spawn_drops(4, Vector2(600, 330))
	EventBus.wave_ended.emit(1)
	await wait_seconds(1.5)
	var tithe: int = (load("res://data/shop/shop_tuning.tres") as ShopTuning).wave_clear_ink
	assert_eq(GameState.gold_ink, before + 4 + tithe, "sobra da onda vai para o jogador (D-042) + dízimo (D-058)")


func test_champion_spawn_telegraph_is_longer() -> void:
	var t: SpawnTelegraph = PoolManager.acquire(SpawnTelegraph.POOL_KEY)
	t.start(IMP, Vector2(300, 100), _m, Callable(), true)
	await wait_seconds(0.6)
	assert_eq(_m.count, 0, "a telegrafia do campeão dura 0.8 s")
	await wait_seconds(0.4)
	assert_eq(_m.count, 1)
	assert_eq(_m.champion[0], 1)


func test_hud_shows_gold_ink() -> void:
	var counter: HudInk = _main.get_node("Hud/Ink")
	GameState.gold_ink = 7
	await wait_process_frames(2)
	assert_eq(counter.shown, 7)
