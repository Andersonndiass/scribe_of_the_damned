extends Miracle
## CAECITAS / Cegueira (LUX + PAX) — clarão que fere e cega no raio (002 FR-203, D-046):
## os cegos vagam e não atacam, mas o contato continua ferindo. Usa: radius, damage, stun (duração
## da cegueira). Visual (design-agent): disco em xadrez CHALK por 2 quadros, depois anel do PAX.

const FLASH_TIME := 0.12
const RING_TIME := 0.3

var _t: float = 0.0


func _on_start() -> void:
	_t = 0.0
	var em := EnemyQuery.provider as EnemyManager
	if em != null:
		em.blind_in_radius(origin, word.radius, word.stun)
		em.damage_in_radius(origin, word.radius, dmg(word.damage))
	if word.kill_zone:
		# D-084: o clarão mata o comum no raio enquanto dura (`duration`, antes FLASH + RING).
		var z := open_zone(KillZone.Shape.CIRCLE, word.duration)
		z.origin = origin
		z.radius = word.radius
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= maxf(FLASH_TIME + RING_TIME, word.duration):
		finish()


func _draw() -> void:
	if word == null:
		return
	var r: float = word.radius
	if _t < FLASH_TIME:
		var ri: int = ceili(r)
		for y: int in range(-ri, ri + 1):
			for x: int in range(-ri + (absi(y) % 2), ri + 1, 2):
				if Vector2(x, y).length() <= r:
					draw_rect(Rect2(x, y, 1, 1), Palette.CHALK)
		return
	var k: float = clampf((_t - FLASH_TIME) / RING_TIME, 0.1, 1.0)
	draw_arc(Vector2.ZERO, r * k, 0.0, TAU, 48, Palette.GOLD, 3.0, false)
	draw_arc(Vector2.ZERO, r * k, 0.0, TAU, 48, Palette.CHALK, 1.0, false)
