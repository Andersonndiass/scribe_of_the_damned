class_name OrbitWeapon
extends Node2D
## Rosário (017 T1736; rules-agent e design-agent T1700): contas em órbita em volta do escriba.
## O dano é uma WeaponZone POINTS (cada inimigo leva no máximo 1 acerto a cada `interval` s); a
## volta dura `orbit_period` (a Pena de Ganso encurta as duas). A 1ª conta é a cruz.

const CROSS := preload("res://assets/placeholders/prj_rosary_cross.png")
const BEAD := preload("res://assets/placeholders/prj_rosary_bead.png")
const BODY := Vector2(0, -6)

var zone := WeaponZone.new()
var on: bool = false
var _angle: float = 0.0


func _ready() -> void:
	top_level = true
	z_index = 2


## Liga (ou mantém) as contas em volta de `owner_pos`; `mul` = Pena de Ganso.
func hold(owner_pos: Vector2, s: WeaponLevelData, w: WeaponData, mul: float, delta: float) -> void:
	if not on:
		on = true
		zone.open(ZoneShape.Shape.POINTS)
		WeaponZones.register(zone)
	_angle = fmod(_angle + TAU * delta / maxf(s.orbit_period * mul, 0.05), TAU)
	var center: Vector2 = owner_pos + BODY
	var pts := PackedVector2Array()
	for k: int in s.count:
		pts.append(center + Vector2.RIGHT.rotated(_angle + TAU * float(k) / float(s.count)) * s.orbit_radius)
	zone.points = pts
	zone.radius = s.width / 2.0
	zone.damage = s.damage
	zone.interval = s.interval * mul
	zone.max_targets = 0
	zone.precision_mul = w.precision_mul
	zone.tag = w.boss_tag
	queue_redraw()


func release() -> void:
	if not on:
		return
	on = false
	zone.close()
	WeaponZones.unregister(zone)
	queue_redraw()


func _exit_tree() -> void:
	release()


func _draw() -> void:
	if not on:
		return
	for k: int in zone.points.size():
		var tex: Texture2D = CROSS if k == 0 else BEAD
		draw_texture(tex, (zone.points[k] - tex.get_size() / 2.0).round())
