class_name EnemyProjectileManager
extends Node2D
## Projéteis inimigos num laço único (005 FR-508, lição do T085): arrays + um único _draw,
## nenhum nó por tiro. Somem ao acertar o jogador, ao tocar um bloqueador (CRUX), ao sair da
## página ou ao expirar. Teto fixo: acima dele o tiro é descartado (nunca instancia).

const CAPACITY := 128
const PLAYER_BODY_OFFSET := Vector2(0, -4)

@export var player: Node2D
@export var player_hurt_radius: float = 5.0
@export var world_rect: Rect2 = Rect2(Vector2.ZERO, Arena.PAGE_SIZE)

var count: int = 0
## Total disparado desde o início (métricas e testes).
var fired_total: int = 0

var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _life := PackedFloat32Array()
var _data: Array[EnemyProjectileData] = []


func _init() -> void:
	_pos.resize(CAPACITY)
	_vel.resize(CAPACITY)
	_life.resize(CAPACITY)
	_data.resize(CAPACITY)


func _ready() -> void:
	add_to_group(&"enemy_projectiles")


## Dispara na direção `dir` (normalizada aqui). Retorna false se o teto foi atingido.
func fire(data: EnemyProjectileData, from: Vector2, dir: Vector2) -> bool:
	if count >= CAPACITY:
		return false
	var i: int = count
	_pos[i] = from
	_vel[i] = dir.normalized() * data.speed if not dir.is_zero_approx() else Vector2.ZERO
	_life[i] = data.lifetime
	_data[i] = data
	count += 1
	fired_total += 1
	return true


## Posições dos tiros ativos (SALVATOR desenha uma cruz onde cada um sumiu).
func snapshot_positions() -> PackedVector2Array:
	return _pos.slice(0, count)


func clear() -> void:
	count = 0
	queue_redraw()


func _physics_process(delta: float) -> void:
	if count == 0:
		return
	var t0: int = Prof.start()
	var body: Vector2 = player.global_position + PLAYER_BODY_OFFSET if player != null else Vector2.INF
	var can_hit: bool = player != null and player.has_method(&"take_hit")
	var i: int = 0
	while i < count:
		var d: EnemyProjectileData = _data[i]
		var p: Vector2 = _pos[i] + _vel[i] * delta
		_pos[i] = p
		_life[i] -= delta
		# Tiros do Monge param no vitral e no altar (004, rules-agent).
		var gone: bool = _life[i] <= 0.0 or not world_rect.has_point(p) or ProjectileBlockers.blocks(p) \
				or ObstacleQuery.blocks(p, ObstacleTypeData.Block.ENEMY_SHOT)
		if not gone and can_hit and p.distance_to(body) <= d.radius + player_hurt_radius:
			player.call(&"take_hit", d.damage, &"projectile")
			EventBus.enemy_projectile_hit.emit()
			gone = true
		if gone:
			_remove(i)
		else:
			i += 1
	queue_redraw()
	Prof.stop(&"projeteis_inimigos", t0)


## Tiro BLOOD com contorno INK (art bible §2.2: projétil inimigo sempre com BLOOD).
func _draw() -> void:
	for i: int in count:
		var s: Vector2 = Vector2(_data[i].size)
		var r := Rect2((_pos[i] - s / 2.0).round(), s)
		draw_rect(r.grow(1.0), Palette.INK)
		draw_rect(r, Palette.BLOOD)


func _remove(i: int) -> void:
	var last: int = count - 1
	if i != last:
		_pos[i] = _pos[last]
		_vel[i] = _vel[last]
		_life[i] = _life[last]
		_data[i] = _data[last]
	_data[last] = null
	count -= 1
