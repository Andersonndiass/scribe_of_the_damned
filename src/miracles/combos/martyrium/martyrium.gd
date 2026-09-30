extends Miracle
## MARTYRIUM / Martírio (CRUX + LUX) — cruz de laser GOLD girando em volta do escriba
## (002 FR-203). Usa: damage, hit_cooldown (cada inimigo é acertado no máximo 1× por intervalo),
## length (braço), width, duration, rotation_speed (voltas/s).
## Visual (design-agent): braço de 5 px INK|GOLD|CHALK|GOLD|INK — única exceção de GOLD em projétil.

const BLINK_WINDOW := 0.5

var _left: float = 0.0
var _tick: float = 0.0
var _angle: float = 0.0


func _on_start() -> void:
	_left = word.duration
	_tick = 0.0
	_angle = direction.angle()
	_follow()
	if word.kill_zone:
		# D-084: a cruz de laser mata o comum que ela varre, girando junto.
		var z := open_zone(KillZone.Shape.CROSS, word.duration)
		z.length = word.length
		z.width = word.width
		_move_zone()
	queue_redraw()


func _physics_process(delta: float) -> void:
	_left -= delta
	_tick -= delta
	_angle += TAU * word.rotation_speed * delta
	_follow()
	_move_zone()
	if _tick <= 0.0:
		_tick += word.hit_cooldown
		var em := EnemyQuery.provider as EnemyManager
		if em != null:
			em.damage_cross_rotated(global_position, _angle, word.length, word.width, dmg(word.damage))
	visible = _left > BLINK_WINDOW or int(_left / 0.1) % 2 == 0
	queue_redraw()
	if _left <= 0.0:
		visible = true
		finish()


func _move_zone() -> void:
	zone.origin = global_position
	zone.angle = _angle


func _follow() -> void:
	var em := EnemyQuery.provider as EnemyManager
	if em != null and em.player != null:
		global_position = em.player_body().round()


func _draw() -> void:
	if word == null:
		return
	var a: float = word.length
	var colors: Array[Color] = [Palette.INK, Palette.GOLD, Palette.CHALK, Palette.GOLD, Palette.INK]
	for arm: int in 2:
		var d: Vector2 = Vector2.RIGHT.rotated(_angle + arm * PI / 2.0)
		var n: Vector2 = d.orthogonal()
		for k: int in colors.size():
			var off: Vector2 = n * float(k - 2)
			draw_line((-d * a + off).round(), (d * a + off).round(), colors[k], 1.0, false)
