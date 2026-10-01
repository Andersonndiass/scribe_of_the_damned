class_name RefugeCircle
extends Node2D
## Desenho do círculo da Água Benta (018 T1815; design-agent e animation-agent T1801): anel de 4 px
## (INK por fora, CHALK de 2 px, INK_SOFT de 1 px), sem preenchimento, abaixo dos inimigos; abre em
## 4×50 ms (25/50/75/100% do raio), pulso de 700 ms (CHALK 2↔1 px), aviso no último segundo
## (alterna CHALK/INK_SOFT), fecha em 4×50 ms; 4 marcadores nos pontos N/L/S/O. Sem alpha.

const MARKER := preload("res://assets/placeholders/vfx_holy_marker.png")
const STEP := 0.05
const STEPS := 4
const PULSE := 0.35
const WARN := 1.0
const WARN_FAST := 0.3

var _t: float = 0.0
var _closing: float = -1.0
var _was_active: bool = false
var _center: Vector2 = Vector2.ZERO
var _radius: float = 0.0


func _process(delta: float) -> void:
	var on: bool = RefugeZones.active
	if on:
		if not _was_active or _center != RefugeZones.center:
			_t = 0.0
		_center = RefugeZones.center
		_radius = RefugeZones.radius
		_closing = -1.0
		_t += delta
	elif _was_active:
		_closing = 0.0
	if _closing >= 0.0:
		_closing += delta
		if _closing >= STEP * STEPS:
			_closing = -1.0
	_was_active = on
	visible = on or _closing >= 0.0
	if visible:
		queue_redraw()


func _draw() -> void:
	var k: int = STEPS
	if _closing >= 0.0:
		k = STEPS - int(_closing / STEP)
	elif _t < STEP * STEPS:
		k = int(_t / STEP) + 1
	var r: int = roundi(_radius * float(clampi(k, 1, STEPS)) / float(STEPS))
	if r < 4:
		return
	var left: float = GameState.potions.left.get(&"holy_water", 0.0) if GameState.potions != null else 0.0
	var mid: Color = Palette.CHALK
	if left > 0.0 and left <= WARN:
		var period: float = STEP if left <= WARN_FAST else 0.1
		if int(left / period) % 2 == 1:
			mid = Palette.INK_SOFT
	var thick: int = 2 if int(_t / PULSE) % 2 == 0 else 1
	UiStyle.ring(self, _center, r, Palette.INK, 1)
	UiStyle.ring(self, _center, r - 1, mid, thick)
	UiStyle.ring(self, _center, r - 1 - thick, Palette.INK_SOFT, 1)
	if _closing < 0.0 and k >= STEPS:
		var half: Vector2 = MARKER.get_size() / 2.0
		for d: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
			draw_texture(MARKER, (_center + d * r - half).round())
