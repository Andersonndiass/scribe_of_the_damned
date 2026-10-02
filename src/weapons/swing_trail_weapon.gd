class_name SwingTrailWeapon
extends Node2D
## Turíbulo (017 T1737; rules-agent, design-agent e animation-agent T1700): a cada intervalo, com
## inimigo por perto, balança num arco de `swing_arc_deg` (alternando os lados) a `range` px do
## escriba; a cabeça fere quem toca (1× por balanço) e deixa nuvens de incenso que ferem a cada
## `trail_tick` s enquanto duram. O rastro que já está no chão continua ferindo depois da troca
## de arma (animation-agent). Duas WeaponZones: CIRCLE (cabeça) e POINTS (nuvens).

const CENSER := preload("res://assets/placeholders/prj_censer.png")
const LINK := preload("res://assets/placeholders/prj_censer_link.png")
const SMOKE: Array[Texture2D] = [
	preload("res://assets/placeholders/vfx_incense_l.png"),
	preload("res://assets/placeholders/vfx_incense_m.png"),
	preload("res://assets/placeholders/vfx_incense_s.png"),
]
const BODY := Vector2(0, -6)
## Elo da corrente a cada tantos px (design-agent).
const LINK_STEP := 3.0
## Nuvem: tamanho cai a cada terço da vida e sobe 1 px a cada 0,4 s (animation-agent).
const SMOKE_RISE_EVERY := 0.4

var head := WeaponZone.new()
var trail := WeaponZone.new()
## Balanço em curso: tempo que falta (< 0 = parado).
var swing_left: float = -1.0

var _side: float = 1.0
var _aim_angle: float = 0.0
var _swing_time: float = 0.4
var _arc: float = 0.0
var _radius: float = 40.0
var _head_pos: Vector2 = Vector2.ZERO
var _origin: Vector2 = Vector2.ZERO
var _since_cloud: float = 0.0
var _clouds := PackedVector2Array()
var _cloud_age := PackedFloat32Array()
var _cloud_life := PackedFloat32Array()
var _trail_cap: int = 25
var _trail_life: float = 1.5
var _trail_every: float = 0.1


func _ready() -> void:
	top_level = true
	z_index = 1
	trail.open(ZoneShape.Shape.POINTS)
	trail.live = false


func _exit_tree() -> void:
	head.close()
	trail.close()
	WeaponZones.unregister(head)
	WeaponZones.unregister(trail)


## Começa um balanço para o lado de `toward` (direção do alvo).
func start_swing(owner_pos: Vector2, toward: Vector2, s: WeaponLevelData, w: WeaponData, mul: float) -> void:
	_side = -_side
	_aim_angle = toward.angle()
	_swing_time = maxf(w.swing_time, 0.05)
	_arc = deg_to_rad(w.swing_arc_deg)
	_radius = s.range
	_trail_cap = w.trail_cap
	swing_left = _swing_time
	_since_cloud = 0.0
	head.open(ZoneShape.Shape.CIRCLE)
	WeaponZones.register(head)
	head.radius = w.head_radius
	head.damage = s.damage
	head.slow_factor = s.slow_factor
	head.slow_time = s.slow_time
	head.interval = _swing_time  # cada inimigo 1× por balanço
	head.precision_mul = w.precision_mul
	head.tag = w.boss_tag
	trail.radius = s.width / 2.0
	trail.damage = s.damage
	trail.slow_factor = s.slow_factor
	trail.slow_time = s.slow_time
	trail.interval = w.trail_tick * mul
	trail.precision_mul = w.precision_mul
	trail.tag = w.boss_tag
	_trail_life = s.trail_life
	_trail_every = w.trail_every
	_follow(owner_pos)


## Avança o balanço (só a arma ativa chama); `owner_pos` = o escriba agora.
func swing_tick(owner_pos: Vector2, delta: float) -> void:
	if swing_left < 0.0:
		return
	swing_left -= delta
	_follow(owner_pos)
	_since_cloud += delta
	if _since_cloud >= _trail_every:
		_since_cloud = 0.0
		_add_cloud(_head_pos, _trail_life)
	if swing_left < 0.0:
		stop_swing()


## Troca de arma: a cabeça some na hora; o rastro fica.
func stop_swing() -> void:
	swing_left = -1.0
	head.close()
	WeaponZones.unregister(head)
	queue_redraw()


func is_swinging() -> bool:
	return swing_left >= 0.0


func _follow(owner_pos: Vector2) -> void:
	_origin = owner_pos + BODY
	var t: float = clampf(1.0 - swing_left / _swing_time, 0.0, 1.0)
	var a: float = _aim_angle + _side * (-_arc / 2.0 + _arc * t)
	_head_pos = _origin + Vector2.RIGHT.rotated(a) * _radius
	head.origin = _head_pos
	queue_redraw()


func _add_cloud(at: Vector2, life: float) -> void:
	if _clouds.size() >= _trail_cap:
		_clouds.remove_at(0)
		_cloud_age.remove_at(0)
		_cloud_life.remove_at(0)
	_clouds.append(at)
	_cloud_age.append(0.0)
	_cloud_life.append(life)
	WeaponZones.register(trail)  # a zona do incenso só existe enquanto há nuvem


## As nuvens envelhecem sempre (mesmo com a arma guardada).
func _physics_process(delta: float) -> void:
	if _clouds.is_empty():
		return
	for i: int in range(_clouds.size() - 1, -1, -1):
		_cloud_age[i] += delta
		if _cloud_age[i] >= _cloud_life[i]:
			_clouds.remove_at(i)
			_cloud_age.remove_at(i)
			_cloud_life.remove_at(i)
	trail.points = _clouds
	trail.live = not _clouds.is_empty()
	if not trail.live:
		WeaponZones.unregister(trail)
	queue_redraw()


func _draw() -> void:
	for i: int in _clouds.size():
		var stage: int = mini(int(_cloud_age[i] / (_cloud_life[i] / 3.0)), SMOKE.size() - 1)
		var tex: Texture2D = SMOKE[stage]
		var rise := Vector2(0, -floorf(_cloud_age[i] / SMOKE_RISE_EVERY))
		draw_texture(tex, (_clouds[i] + rise - tex.get_size() / 2.0).round())
	if swing_left < 0.0:
		return
	var span: float = _origin.distance_to(_head_pos)
	var dir: Vector2 = (_head_pos - _origin).normalized()
	var d: float = LINK_STEP
	while d < span - 3.0:
		draw_texture(LINK, (_origin + dir * d - Vector2.ONE).round())
		d += LINK_STEP
	draw_texture(CENSER, (_head_pos - CENSER.get_size() / 2.0).round())
