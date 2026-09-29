class_name HudCandles
extends Node2D
## Velas = vida (T071, ficha 26). Canto superior esquerdo. Acesas: cera CHALK e chama GOLD;
## apagadas: cera INK_SOFT. Com 1 vela, a chama alterna GOLD/BLOOD a cada 100ms (LAST_CANDLE).

const ORIGIN := Vector2(8, 8)
const SPACING := 9
const WAX := Rect2(0, 5, 5, 10)
const LAST_CANDLE_PULSE := 0.1

var _candles: int = -1
var _max: int = -1
var _pulse: float = 0.0


func hud_rect() -> Rect2:
	return Rect2(ORIGIN, Vector2(SPACING * PlayerVitals.new().cap, 16))


func _process(delta: float) -> void:
	var changed: bool = _candles != GameState.candles or _max != GameState.max_candles
	_candles = GameState.candles
	_max = GameState.max_candles
	if _candles == 1:
		_pulse += delta
		changed = true
	if changed:
		queue_redraw()


func _draw() -> void:
	for i: int in _max:
		var base: Vector2 = ORIGIN + Vector2(i * SPACING, 0)
		var lit: bool = i < _candles
		var wax := Rect2(base + WAX.position, WAX.size)
		draw_rect(wax.grow(1.0), Palette.INK)
		draw_rect(wax, Palette.CHALK if lit else Palette.INK_SOFT)
		draw_rect(Rect2(base + Vector2(2, 3), Vector2(1, 2)), Palette.INK)
		if lit:
			var last: bool = _candles == 1 and int(_pulse / LAST_CANDLE_PULSE) % 2 == 1
			# Chama com ponta (não um quadrado) e o brilho no lado da luz, à direita (D-076).
			var flame: Color = Palette.BLOOD if last else Palette.GOLD
			draw_rect(Rect2(base + Vector2(1, 0), Vector2(3, 3)), flame)
			draw_rect(Rect2(base + Vector2(2, -1), Vector2(1, 1)), flame)
			draw_rect(Rect2(base + Vector2(3, 0), Vector2(1, 1)), Palette.GOLD_LIGHT)
