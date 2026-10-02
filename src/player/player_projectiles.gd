class_name PlayerProjectileManager
extends Node2D
## Projéteis das armas (PRJ_INK_DROP da Pena, PRJ_CRUCIFIX do Crucifixo) num laço único (T085 §4
## item 2, C-005): arrays + um único _draw, nenhum nó por projétil. Somem ao passar do alcance ou
## quando já feriram tantos inimigos quanto o `pierce` deixa. Teto fixo dimensionado para o SC-001;
## acima dele o disparo é recusado (nunca instancia).

const CAPACITY := 200
const HIT_RADIUS := 3.0
## Visual por `WeaponData.projectile_kind` (0 = gota de tinta, 1 = crucifixo, 2 = gota de água benta). O crucifixo fica
## sempre de pé (design-agent) e deixa 1 silhueta INK_SOFT atrás.
const TEXTURES: Array[Texture2D] = [
	preload("res://assets/placeholders/prj_ink_drop.tres"),
	preload("res://assets/placeholders/prj_crucifix.png"),
	preload("res://assets/placeholders/prj_holy_drop.png"),
]
const TRAILS: Array[Texture2D] = [
	null,
	preload("res://assets/placeholders/prj_crucifix_trail.png"),
	null,
]
## Distância da silhueta do rastro atrás do projétil (px).
const TRAIL_GAP := 6.0

var count: int = 0

var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _damage := PackedInt32Array()
var _distance_left := PackedFloat32Array()
var _kind := PackedInt32Array()
## Lentidão no acerto (D-098), por projétil.
var _slow_f := PackedFloat32Array()
var _slow_t := PackedFloat32Array()
## Arma de cada `projectile_kind` (som do acerto).
const KIND_WEAPON: Array[StringName] = [&"pen", &"crucifix", &"aspergillum"]
var _radius := PackedFloat32Array()
## Quantos inimigos ainda pode ferir (1 = para no primeiro).
var _hits_left := PackedInt32Array()
var _freeze := PackedFloat32Array()
## Quem já foi ferido por este projétil (uids; só os que atravessam).
var _hit_uids: Array[PackedInt32Array] = []


func _init() -> void:
	_pos.resize(CAPACITY)
	_vel.resize(CAPACITY)
	_damage.resize(CAPACITY)
	_distance_left.resize(CAPACITY)
	_kind.resize(CAPACITY)
	_slow_f.resize(CAPACITY)
	_slow_t.resize(CAPACITY)
	_radius.resize(CAPACITY)
	_hits_left.resize(CAPACITY)
	_freeze.resize(CAPACITY)
	_hit_uids.resize(CAPACITY)


## Dispara de `origin` na direção `direction` (normalizada aqui). `pierce` = quantos inimigos fere
## no máximo (0/1 = o primeiro). Retorna false se o teto foi atingido.
func fire(origin: Vector2, direction: Vector2, speed: float, damage: int, max_distance: float,
		kind: int = 0, radius: float = HIT_RADIUS, pierce: int = 1, freeze: float = 0.0,
		slow_f: float = 1.0, slow_t: float = 0.0) -> bool:
	if count >= CAPACITY:
		return false
	var i: int = count
	_pos[i] = origin
	_vel[i] = direction.normalized() * speed
	_damage[i] = damage
	_distance_left[i] = max_distance
	_kind[i] = clampi(kind, 0, TEXTURES.size() - 1)
	_radius[i] = radius
	_hits_left[i] = maxi(pierce, 1)
	_freeze[i] = freeze
	_slow_f[i] = slow_f
	_slow_t[i] = slow_t
	_hit_uids[i] = PackedInt32Array()
	count += 1
	return true


func position_of(i: int) -> Vector2:
	return _pos[i]


func kind_of(i: int) -> int:
	return _kind[i]


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
		var spent: bool = false
		if _hits_left[i] == 1 and _freeze[i] <= 0.0:
			spent = EnemyQuery.hit(p, _radius[i], _damage[i], _slow_f[i], _slow_t[i])
			if spent:
				EventBus.weapon_hit.emit(KIND_WEAPON[_kind[i]])
		else:
			var got: PackedInt32Array = EnemyQuery.hit_pierce(p, _radius[i], _damage[i], _hit_uids[i], _freeze[i], _hits_left[i], _slow_f[i], _slow_t[i])
			if not got.is_empty():
				var seen: PackedInt32Array = _hit_uids[i]
				seen.append_array(got)
				_hit_uids[i] = seen
				_hits_left[i] -= got.size()
				EventBus.weapon_hit.emit(KIND_WEAPON[_kind[i]])
				spent = _hits_left[i] <= 0
		if spent or _distance_left[i] <= 0.0:
			_remove(i)
		else:
			i += 1
	DamageSource.clear()
	queue_redraw()
	Prof.stop(&"projeteis_total", t0)


func _draw() -> void:
	for i: int in count:
		var tex: Texture2D = TEXTURES[_kind[i]]
		var half: Vector2 = tex.get_size() / 2.0
		var trail: Texture2D = TRAILS[_kind[i]]
		if trail != null:
			draw_texture(trail, (_pos[i] - _vel[i].normalized() * TRAIL_GAP - half).round())
		draw_texture(tex, (_pos[i] - half).round())


func _remove(i: int) -> void:
	var last: int = count - 1
	if i != last:
		_pos[i] = _pos[last]
		_vel[i] = _vel[last]
		_damage[i] = _damage[last]
		_distance_left[i] = _distance_left[last]
		_kind[i] = _kind[last]
		_radius[i] = _radius[last]
		_hits_left[i] = _hits_left[last]
		_freeze[i] = _freeze[last]
		_slow_f[i] = _slow_f[last]
		_slow_t[i] = _slow_t[last]
		var spare: PackedInt32Array = _hit_uids[i]
		_hit_uids[i] = _hit_uids[last]
		_hit_uids[last] = spare
	count -= 1
