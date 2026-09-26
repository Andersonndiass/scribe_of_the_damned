extends Miracle
## AQUA — poça de lentidão (FR-021). Usa: radius, slow_factor, duration.
## Reaplica a lentidão a cada frame em quem está dentro; quem sai volta ao normal em 0.2s.
## Visual placeholder: superfície em dithering INK_SOFT + ondulação CHALK.

const LINGER := 0.2

var _left: float = 0.0
var _ripple: float = 0.0


func _on_start() -> void:
	_left = word.duration
	_ripple = 0.0
	queue_redraw()


func _physics_process(delta: float) -> void:
	_left -= delta
	_ripple += delta
	var em := EnemyQuery.provider as EnemyManager
	if em != null:
		em.slow_in_radius(origin, word.radius * power, word.slow_factor, LINGER)
	queue_redraw()
	if _left <= 0.0:
		finish()


func _draw() -> void:
	if word == null:
		return
	var r: float = word.radius * power
	var ri: int = ceili(r)
	for y: int in range(-ri, ri + 1, 2):
		for x: int in range(-ri + absi(y / 2) % 2, ri + 1, 2):
			if Vector2(x, y).length() <= r:
				draw_rect(Rect2(x, y, 1, 1), Palette.INK_SOFT)
	var wave: float = fmod(_ripple * 30.0, r)
	draw_arc(Vector2.ZERO, wave, 0.0, TAU, 24, Palette.CHALK, 1.0, false)
