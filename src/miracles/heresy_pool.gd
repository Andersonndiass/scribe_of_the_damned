class_name HeresyPool
extends Node2D
## Poça de aggro da heresia (FR-019): marca visual no ponto do erro enquanto atrai os inimigos.
## Uma só instância reutilizada (só existe uma heresia ativa por vez). BLOOD: heresia é dano.

var _radius: float = 0.0
var _left: float = 0.0
var _total: float = 0.0
## MISERERE: dissolve em dither CHALK por ABSOLVE_TIME s (design-agent).
const ABSOLVE_TIME := 0.2
var _absolve_left: float = 0.0


func _ready() -> void:
	visible = false
	set_process(false)


func start(pos: Vector2, radius: float, duration: float) -> void:
	global_position = pos
	_radius = radius
	_total = maxf(duration, 0.001)
	_left = _total
	visible = true
	set_process(true)
	queue_redraw()


func stop() -> void:
	_left = 0.0
	_absolve_left = 0.0
	visible = false
	set_process(false)


## MISERERE: a poça se dissolve em CHALK e some.
func absolve() -> void:
	if not visible:
		return
	_absolve_left = ABSOLVE_TIME
	set_process(true)
	queue_redraw()


func is_active() -> bool:
	return visible


func _process(delta: float) -> void:
	if _absolve_left > 0.0:
		_absolve_left -= delta
		queue_redraw()
		if _absolve_left <= 0.0:
			stop()
		return
	_left -= delta
	queue_redraw()
	if _left <= 0.0:
		visible = false
		set_process(false)


func _draw() -> void:
	if _absolve_left > 0.0:
		var ri: int = ceili(_radius)
		var step: int = 2 if _absolve_left > ABSOLVE_TIME / 2.0 else 4
		for y: int in range(-ri, ri + 1, 2):
			for x: int in range(-ri + (y / 2 % 2), ri + 1, step):
				if Vector2(x, y).length() <= _radius:
					draw_rect(Rect2(x, y, 1, 1), Palette.CHALK)
		return
	# Borda tracejada que encolhe com o tempo; miolo em dithering esparso.
	var k: float = clampf(_left / _total, 0.0, 1.0)
	var r: float = _radius * (0.5 + 0.5 * k)
	var dashes: int = 20
	for i: int in dashes:
		if i % 2 == 0:
			var a0: float = TAU * float(i) / dashes
			draw_arc(Vector2.ZERO, r, a0, a0 + TAU / dashes, 3, Palette.BLOOD, 1.0, false)
	var ri: int = ceili(r * 0.6)
	for y: int in range(-ri, ri + 1, 3):
		for x: int in range(-ri, ri + 1, 3):
			if Vector2(x, y).length() <= r * 0.6:
				draw_rect(Rect2(x, y, 1, 1), Palette.BLOOD_DARK)
