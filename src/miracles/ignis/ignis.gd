extends Miracle
## IGNIS — área de fogo com dano contínuo; queima a página (FR-021).
## Usa: damage, tick_interval, radius, duration. BLOOD só na borda das chamas (art bible §2.1).

const FLAMES := 18

var _left: float = 0.0
var _tick: float = 0.0
var _flicker: int = 0


func _on_start() -> void:
	_left = word.duration
	_tick = 0.0
	var arena := get_tree().get_first_node_in_group(&"arena") as Arena
	if arena != null:
		arena.stamp(&"burn", origin, word.radius * power)
	if word.kill_zone:
		# D-084: comum no fogo morre enquanto ele queima (os ticks seguem para chefe e campeão).
		var z := open_zone(KillZone.Shape.CIRCLE, word.duration)
		z.origin = origin
		z.radius = word.radius * power
	queue_redraw()


func _process(delta: float) -> void:
	_left -= delta
	_tick -= delta
	if _tick <= 0.0:
		_tick += word.tick_interval
		_flicker += 1
		queue_redraw()
		var em := EnemyQuery.provider as EnemyManager
		if em != null:
			em.damage_in_radius(origin, word.radius * power, dmg(word.damage))
	if _left <= 0.0:
		finish()


func _draw() -> void:
	if word == null:
		return
	var r: float = word.radius * power
	for i: int in FLAMES:
		var ang: float = TAU * float(i) / FLAMES + float(_flicker) * 0.7
		var dist: float = r * (0.3 + 0.7 * float((i * 7 + _flicker) % 10) / 10.0)
		var p: Vector2 = (Vector2.RIGHT.rotated(ang) * dist).round()
		var edge: bool = dist > r * 0.8
		var c: Color = Palette.BLOOD if edge else (Palette.GOLD if i % 2 == 0 else Palette.CHALK)
		draw_rect(Rect2(p, Vector2(1, 2)), c)
