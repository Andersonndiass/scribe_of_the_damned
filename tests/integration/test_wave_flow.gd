extends GutTest
## T037 Fluxo de onda: começa, telegrafa, cria inimigos longe do jogador, termina e dissolve (FR-009, FR-010).

const TELEGRAPH_SCENE := preload("res://src/enemies/spawn_telegraph.tscn")
const DISSOLVE_SCENE := preload("res://src/enemies/dissolve_fx.tscn")
const IMP := preload("res://data/enemies/imp.tres")

var _manager: EnemyManager
var _director: WaveDirector
var _player: Node2D
var _events: Array[String] = []


func _short_wave() -> WaveData:
	var g := SpawnGroup.new()
	g.enemy = IMP
	g.start_time = 0.0
	g.end_time = 2.0
	g.spawn_rate_start = 8.0
	g.spawn_rate_end = 8.0
	g.max_alive = 6
	var w := WaveData.new()
	w.index = 1
	w.duration = 2.0
	w.min_spawn_distance = 96.0
	w.groups = [g]
	return w


func before_each() -> void:
	PoolManager.clear_all()
	_events.clear()
	var root := Node2D.new()
	add_child_autofree(root)
	var layer := Node2D.new()
	root.add_child(layer)
	PoolManager.register(SpawnTelegraph.POOL_KEY, TELEGRAPH_SCENE, 16, layer)
	PoolManager.register(DissolveFx.POOL_KEY, DISSOLVE_SCENE, 16, layer)
	_player = Node2D.new()
	_player.position = Vector2(320, 180)
	root.add_child(_player)
	_manager = EnemyManager.new()
	_manager.player = null  # os inimigos ficam parados: o teste mede o spawn, não a perseguição
	root.add_child(_manager)
	_director = WaveDirector.new()
	_director.manager = _manager
	_director.player = _player
	root.add_child(_director)
	GameState.rng.seed = 1348
	EventBus.wave_started.connect(_on_started)
	EventBus.wave_ended.connect(_on_ended)
	EventBus.enemy_spawned.connect(_on_spawned)


func after_each() -> void:
	EventBus.wave_started.disconnect(_on_started)
	EventBus.wave_ended.disconnect(_on_ended)
	EventBus.enemy_spawned.disconnect(_on_spawned)
	PoolManager.clear_all()


func _on_started(i: int, _d: float) -> void:
	_events.append("start %d" % i)


func _on_ended(i: int) -> void:
	_events.append("end %d" % i)


func _on_spawned(slot: int, _d: EnemyData) -> void:
	var p: Vector2 = _manager.positions[slot]
	if p.distance_to(_player.position) < 96.0:
		_events.append("spawn perto demais: %s" % p)


func test_wave_runs_spawns_and_ends() -> void:
	var before: int = PoolManager.instantiate_count
	_director.start(_short_wave())
	assert_eq(_events, ["start 1"])
	await wait_seconds(1.2)
	assert_gt(_manager.count, 0, "inimigos surgiram depois da telegrafia")
	assert_lte(_manager.count, 6, "respeita max_alive")
	await wait_seconds(1.3)
	assert_has(_events, "end 1")
	assert_eq(_manager.count, 0, "fim da onda dissolve os restantes")
	for e: String in _events:
		assert_false(e.begins_with("spawn perto"), e)
	await wait_seconds(0.7)
	assert_eq(_manager.count, 0, "telegrafias pendentes não criam inimigos depois do fim")
	assert_eq(PoolManager.instantiate_count, before, "nenhum instantiate durante a onda")
