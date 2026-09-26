class_name SpawnTelegraph
extends Node2D
## Aviso de spawn (FR-009): anel BLOOD que se fecha durante telegraph_time e então cria o inimigo.
## Pooled em &"spawn_telegraph". `can_spawn` (opcional) é chamado no fim e decide se o inimigo nasce
## (o WaveDirector recusa depois que a onda acabou).

const POOL_KEY := &"spawn_telegraph"
## O anel começa com este múltiplo do raio do inimigo e fecha até o raio.
const START_RADIUS_MUL := 2.5
## Campeão: anel ainda maior (ficha 15).
const CHAMPION_RADIUS_MUL := 4.0

var _data: EnemyData
var _manager: EnemyManager
var _can_spawn: Callable
var _champion: bool = false
var _total: float = 0.0
var _left: float = 0.0


func start(data: EnemyData, pos: Vector2, manager: EnemyManager, can_spawn: Callable = Callable(), champion: bool = false) -> void:
	_data = data
	_manager = manager
	_can_spawn = can_spawn
	_champion = champion
	global_position = pos
	var t: float = data.telegraph_time
	if champion and manager.champion_tuning != null:
		t = manager.champion_tuning.spawn_telegraph
	_total = maxf(t, 0.001)
	_left = _total
	queue_redraw()


func _process(delta: float) -> void:
	_left -= delta
	queue_redraw()
	if _left <= 0.0:
		var ok: bool = true
		if _can_spawn.is_valid():
			ok = _can_spawn.call()
		if ok:
			_manager.spawn(_data, global_position, _champion)
		PoolManager.release(self)


func _draw() -> void:
	if _data == null:
		return
	var k: float = clampf(1.0 - _left / _total, 0.0, 1.0)
	var mul: float = CHAMPION_RADIUS_MUL if _champion else START_RADIUS_MUL
	var r: float = lerpf(_data.radius * mul, _data.radius, k)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 16, Palette.BLOOD, 1.0, false)
