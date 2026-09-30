class_name WaveDirector
extends Node
## Conduz uma onda a partir do WaveData (FR-010): ritmo de spawn interpolado por grupo,
## teto de vivos por grupo, spawn telegrafado longe do jogador (FR-009) e fim da onda.

## Tentativas de achar um ponto a min_spawn_distance do jogador antes de aceitar o último.
const SPAWN_POINT_TRIES := 12

@export var wave: WaveData
@export var manager: EnemyManager
@export var player: Node2D
@export var telegraph_parent: Node2D
@export var tuning: WaveTuning = preload("res://data/tuning/wave.tres")

var running: bool = false
var elapsed: float = 0.0

var _accum: PackedFloat32Array
var _display_index: int = 1
var _champions_spawned: int = 0
var _pending: PackedInt32Array
## O aviso de fim da onda já saiu (004 FR-404).
var _closing_sent: bool = false


func _ready() -> void:
	EventBus.player_died.connect(stop)


## display_index: número mostrado no HUD (o protótipo repete a onda 1 como ondas 2, 3...).
func start(new_wave: WaveData = null, display_index: int = -1) -> void:
	if new_wave != null:
		wave = new_wave
	_display_index = display_index if display_index > 0 else wave.index
	elapsed = 0.0
	_accum = PackedFloat32Array()
	_accum.resize(wave.groups.size())
	_pending = PackedInt32Array()
	_pending.resize(wave.groups.size())
	_champions_spawned = 0
	_closing_sent = false
	running = true
	GameState.wave_index = _display_index
	GameState.letter_drop_mul = wave.letter_drop_mul
	EventBus.wave_started.emit(_display_index, wave.duration)


func stop() -> void:
	running = false


func _physics_process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	if elapsed >= wave.duration:
		_end()
		return
	if not _closing_sent and elapsed >= wave.duration - tuning.closing_warning:
		_closing_sent = true
		EventBus.wave_closing.emit(_display_index, wave.duration - elapsed)
	_spawn_due_champions()
	for g: int in wave.groups.size():
		var group: SpawnGroup = wave.groups[g]
		_accum[g] += group.rate_at(elapsed) * delta
		while _accum[g] >= 1.0:
			_accum[g] -= 1.0
			if manager.count_of(group.enemy) + _pending[g] >= group.max_alive:
				continue
			_telegraph(g, group.enemy)


func _telegraph(g: int, data: EnemyData) -> void:
	var t := PoolManager.acquire(SpawnTelegraph.POOL_KEY) as SpawnTelegraph
	_pending[g] += 1
	t.start(data, _pick_spawn_point(data.radius), manager, func() -> bool:
		_pending[g] = maxi(0, _pending[g] - 1)
		return running)


## Campeões nos instantes de champion_times (D-019: 1 por onda a partir da 3; D-040).
func _spawn_due_champions() -> void:
	var total: int = mini(wave.champions, wave.champion_times.size())
	while _champions_spawned < total and elapsed >= wave.champion_times[_champions_spawned]:
		_champions_spawned += 1
		if wave.champion_pool.is_empty():
			continue
		var data: EnemyData = wave.champion_pool[GameState.rng.randi_range(0, wave.champion_pool.size() - 1)]
		var t := PoolManager.acquire(SpawnTelegraph.POOL_KEY) as SpawnTelegraph
		t.start(data, _pick_spawn_point(data.radius * manager.champion_tuning.radius_mul), manager, func() -> bool: return running, true)


func champions_spawned() -> int:
	return _champions_spawned


## `radius`: raio do inimigo; o ponto nunca cai dentro de uma peça da página (004 FR-411).
func _pick_spawn_point(radius: float) -> Vector2:
	var rect: Rect2 = manager.world_rect
	var min_d2: float = wave.min_spawn_distance * wave.min_spawn_distance
	var p := Vector2.ZERO
	for i: int in SPAWN_POINT_TRIES:
		p = Vector2(
			GameState.rng.randf_range(rect.position.x, rect.end.x),
			GameState.rng.randf_range(rect.position.y, rect.end.y))
		p = ObstacleQuery.spawn_point(p, radius)
		if player == null or p.distance_squared_to(player.global_position) >= min_d2:
			break
	return p


func _end() -> void:
	running = false
	manager.dissolve_all()
	EventBus.wave_ended.emit(_display_index)
