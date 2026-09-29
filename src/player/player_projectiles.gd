class_name PlayerProjectileManager
extends Node2D
## Projéteis do ataque automático (PRJ_INK_DROP) num laço único (T085 §4 item 2, C-005):
## arrays + um único _draw, nenhum nó por gota. Somem ao acertar um inimigo ou ao passar do
## alcance. Teto fixo dimensionado para o SC-001; acima dele o disparo é recusado (nunca instancia).

const CAPACITY := 200
const HIT_RADIUS := 3.0
const TEXTURE := preload("res://assets/placeholders/prj_ink_drop.tres")

var count: int = 0

var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _damage := PackedInt32Array()
var _distance_left := PackedFloat32Array()


func _init() -> void:
	_pos.resize(CAPACITY)
	_vel.resize(CAPACITY)
	_damage.resize(CAPACITY)
	_distance_left.resize(CAPACITY)


## Dispara de `origin` na direção `direction` (normalizada aqui). Retorna false se o teto foi atingido.
func fire(origin: Vector2, direction: Vector2, speed: float, damage: int, max_distance: float) -> bool:
	if count >= CAPACITY:
		return false
	var i: int = count
	_pos[i] = origin
	_vel[i] = direction.normalized() * speed
	_damage[i] = damage
	_distance_left[i] = max_distance
	count += 1
	return true


func position_of(i: int) -> Vector2:
	return _pos[i]


func clear() -> void:
	count = 0
	queue_redraw()


func _physics_process(delta: float) -> void:
	if count == 0:
		return
	var t0: int = Prof.start()
	DamageSource.mark(&"auto", 0)  # uma vez por laço: o chefe (006) lê a origem
	var i: int = 0
	while i < count:
		var v: Vector2 = _vel[i]
		var p: Vector2 = _pos[i] + v * delta
		_pos[i] = p
		_distance_left[i] -= v.length() * delta
		if EnemyQuery.hit(p, HIT_RADIUS, _damage[i]) or _distance_left[i] <= 0.0:
			_remove(i)
		else:
			i += 1
	DamageSource.clear()
	queue_redraw()
	Prof.stop(&"projeteis_total", t0)


func _draw() -> void:
	var half: Vector2 = TEXTURE.get_size() / 2.0
	for i: int in count:
		draw_texture(TEXTURE, (_pos[i] - half).round())


func _remove(i: int) -> void:
	var last: int = count - 1
	if i != last:
		_pos[i] = _pos[last]
		_vel[i] = _vel[last]
		_damage[i] = _damage[last]
		_distance_left[i] = _distance_left[last]
	count -= 1
