extends Node2D
## Explosão de letras douradas na morte do chefe (006 FR-611; design-agent, animation-agent):
## `count` letras em GOLD (1 em cada 4 em GOLD_LIGHT) saem do olho em direções iguais, voam por
## FLY_TIME com QUAD_OUT e somem piscando (sem fade).

const FLY_TIME := 0.7
const DISTANCE := 90.0
const BLINK_TIME := 0.3
const LETTERS := "LUXPACRVIGNSMO"

var _origin: Vector2
var _count: int = 0
var _t: float = -1.0


func _ready() -> void:
	z_index = 3
	EventBus.boss_letters_burst.connect(func(pos: Vector2, count: int) -> void:
		_origin = pos
		_count = count
		_t = 0.0)


func _process(delta: float) -> void:
	if _t < 0.0:
		return
	_t += delta
	if _t > FLY_TIME + BLINK_TIME:
		_t = -1.0
	queue_redraw()


func _draw() -> void:
	if _t < 0.0:
		return
	if _t > FLY_TIME and int((_t - FLY_TIME) / 0.05) % 2 == 1:
		return
	var k: float = clampf(_t / FLY_TIME, 0.0, 1.0)
	var ease_out: float = 1.0 - (1.0 - k) * (1.0 - k)
	for i: int in _count:
		var dir: Vector2 = Vector2.RIGHT.rotated(TAU * i / maxf(1.0, _count))
		var p: Vector2 = (_origin + dir * DISTANCE * ease_out).round()
		var color: Color = Palette.GOLD_LIGHT if i % 4 == 0 else Palette.GOLD
		PixelFont.draw(self, LETTERS[i % LETTERS.length()], p - Vector2(2, 3), color)
