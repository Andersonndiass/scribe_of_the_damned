extends Miracle
## SANCTUS — solo consagrado (002 FR-212): dano em ticks e lentidão em quem está dentro.
## Usa: radius, damage, tick_interval, slow_factor, duration. power só no dano (D-051/D-056).
## Visual (design-agent): dither 1/8 GOLD no raio, borda CHALK 1 px e 8 cruzes GOLD 3×3 girando
## (1 volta / 6 s); a cada tick que fere, uma cruz pisca CHALK por 50 ms (animation-agent);
## no último 1 s o dither cai a 1/16.

const LINGER := 0.2
const CROSSES := 8
const CROSS_PERIOD := 6.0
const TICK_FLASH := 0.05
const FADE_WINDOW := 1.0

var _left: float = 0.0
var _tick: float = 0.0
var _t: float = 0.0
var _flash_left: float = 0.0
var _flash_idx: int = 0


func _on_start() -> void:
	_left = word.duration
	_tick = 0.0
	_t = 0.0
	if word.kill_zone:
		# D-084: comum no solo consagrado morre (a lentidão e os ticks seguem para os outros).
		var z := open_zone(KillZone.Shape.CIRCLE, word.duration)
		z.origin = origin
		z.radius = word.radius
	queue_redraw()


func _physics_process(delta: float) -> void:
	_left -= delta
	_tick -= delta
	_t += delta
	_flash_left -= delta
	var em := EnemyQuery.provider as EnemyManager
	if em != null:
		em.slow_in_radius(origin, word.radius, word.slow_factor, LINGER)
		if _tick <= 0.0:
			_tick += word.tick_interval
			if em.damage_in_radius(origin, word.radius, dmg(word.damage)) > 0:
				_flash_left = TICK_FLASH
				_flash_idx = (_flash_idx + 1) % CROSSES
	queue_redraw()
	if _left <= 0.0:
		finish()


func _draw() -> void:
	if word == null:
		return
	var r: float = word.radius
	var ri: int = ceili(r)
	var step: int = 4 if _left > FADE_WINDOW else 6
	for y: int in range(-ri, ri + 1, 2):
		for x: int in range(-ri + (y / 2 % 2) * (step / 2), ri + 1, step):
			if Vector2(x, y).length() <= r:
				draw_rect(Rect2(x, y, 1, 1), Palette.GOLD)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Palette.CHALK, 1.0, false)
	for k: int in CROSSES:
		var a: float = TAU * (_t / CROSS_PERIOD + float(k) / CROSSES)
		var c: Vector2 = (Vector2.RIGHT.rotated(a) * r).round()
		var col: Color = Palette.CHALK if (_flash_left > 0.0 and k == _flash_idx) else Palette.GOLD
		draw_rect(Rect2(c + Vector2(-1, 0), Vector2(3, 1)), col)
		draw_rect(Rect2(c + Vector2(0, -1), Vector2(1, 3)), col)
