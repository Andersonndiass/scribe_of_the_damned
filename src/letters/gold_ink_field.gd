class_name GoldInkField
extends Node2D
## Tinta dourada no chão (005 FR-512): gotas pooled, puxadas pelo ímã do jogador e somadas a
## GameState.gold_ink. Não expiram; no fim da onda, as que sobraram voam até o jogador (D-042).

const PICKUP_RADIUS := 6.0
const MAGNET_ACCEL := 900.0
const SCATTER := 10.0
const PLAYER_BODY_OFFSET := Vector2(0, -6)

@export var player: Player

var _active: Array[GoldInk] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group(&"gold_ink_field")
	_rng.seed = 1348
	EventBus.wave_ended.connect(func(_i: int) -> void: collect_all())


func active_count() -> int:
	return _active.size()


## Solta `amount` gotas ao redor de `pos` (acima do teto do pool, as excedentes somem: D-037).
func spawn_drops(amount: int, pos: Vector2) -> void:
	for k: int in amount:
		var g := PoolManager.try_acquire(GoldInk.POOL_KEY) as GoldInk
		if g == null:
			return
		var offset := Vector2(_rng.randf_range(-SCATTER, SCATTER), _rng.randf_range(-SCATTER, SCATTER))
		g.start(pos + offset)
		_active.append(g)


## Todas as gotas passam a voar até o jogador (fim da onda).
func collect_all() -> void:
	for g: GoldInk in _active:
		g.homing = true


func _physics_process(delta: float) -> void:
	if _active.is_empty() or player == null:
		return
	var body: Vector2 = player.global_position + PLAYER_BODY_OFFSET
	var magnet_r: float = player.data.magnet_radius
	for idx: int in range(_active.size() - 1, -1, -1):
		var g: GoldInk = _active[idx]
		var dist: float = g.global_position.distance_to(body)
		if dist <= PICKUP_RADIUS:
			_collect(idx)
			continue
		if g.homing or dist <= magnet_r:
			g.homing = true
			g.magnet_speed += MAGNET_ACCEL * delta
			g.global_position = g.global_position.move_toward(body, g.magnet_speed * delta)


func _collect(idx: int) -> void:
	var g: GoldInk = _active[idx]
	_active[idx] = _active[_active.size() - 1]
	_active.pop_back()
	PoolManager.release(g)
	GameState.gold_ink += 1
	EventBus.gold_ink_collected.emit(1, GameState.gold_ink)
