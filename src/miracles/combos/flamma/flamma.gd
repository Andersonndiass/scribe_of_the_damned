extends Miracle
## FLAMMA / Chama Radiante (LUX + IGNIS) — raio de LUX que deixa fogo ao longo da linha
## (002 FR-203). Usa: burst_damage (raio), damage + tick_interval (fogo), length, width, duration.
## Visual (design-agent): raio como o LUX; faixa com as partículas do IGNIS, BLOOD só na borda.

## O raio aparece por um instante, como o LUX (tempo visual, não de gameplay).
const BEAM_TIME := 0.3
const BEAM_STEPS := 3
## Uma partícula a cada CELL×CELL px da faixa.
const CELL := 4

var _left: float = 0.0
var _beam_left: float = 0.0
var _tick: float = 0.0
var _flicker: int = 0


func _on_start() -> void:
	rotation = direction.angle()
	_left = word.duration
	_beam_left = BEAM_TIME
	_tick = word.tick_interval
	var combo := word as ComboData
	EnemyQuery.damage_line(origin, direction, word.length, word.width, dmg(combo.burst_damage))
	if word.kill_zone:
		# D-084: a faixa de fogo inteira mata o comum enquanto queima.
		var z := open_zone(KillZone.Shape.LINE, word.duration)
		z.origin = origin
		z.dir = direction
		z.length = word.length
		z.width = word.width
	queue_redraw()


func _physics_process(delta: float) -> void:
	_left -= delta
	_beam_left -= delta
	_tick -= delta
	if _tick <= 0.0:
		_tick += word.tick_interval
		_flicker += 1
		EnemyQuery.damage_line(origin, direction, word.length, word.width, dmg(word.damage))
	queue_redraw()
	if _left <= 0.0:
		finish()


func _draw() -> void:
	if word == null:
		return
	var half: float = word.width / 2.0
	var cols: int = int(word.length / CELL)
	var rows: int = int(word.width / CELL)
	for cx: int in cols:
		for cy: int in rows:
			var jitter: int = (cx * 7 + cy * 3 + _flicker) % CELL
			var p := Vector2(cx * CELL + jitter, -half + cy * CELL + (jitter + 1) % CELL)
			var edge: bool = cy == 0 or cy == rows - 1
			var c: Color = Palette.BLOOD if edge else (Palette.GOLD if (cx + cy + _flicker) % 2 == 0 else Palette.CHALK)
			draw_rect(Rect2(p, Vector2(1, 2)), c)
	if _beam_left > 0.0:
		var step: int = ceili(_beam_left / BEAM_TIME * BEAM_STEPS)
		var w: float = word.width * float(step) / BEAM_STEPS
		draw_rect(Rect2(0, -w / 2.0, word.length, w), Palette.GOLD)
		var core: float = maxf(1.0, w - 4.0)
		draw_rect(Rect2(0, -core / 2.0, word.length, core), Palette.CHALK)
