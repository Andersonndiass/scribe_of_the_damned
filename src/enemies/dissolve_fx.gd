class_name DissolveFx
extends Node2D
## Morte de inimigo (art bible §6.1, placeholder desenhado em código até a arte gerada chegar):
## 6 quadros @60ms de tinta SUBINDO (nenhum pixel cai) + decal 8×4 que desbota em 4 passos em 2s.
## Pooled em &"dissolve".

const POOL_KEY := &"dissolve"
const RISE_FRAMES := 6
const FRAME_TIME := 0.06
const DECAL_TIME := 2.0
const DECAL_STEPS := 4
const DECAL_SIZE := Vector2i(8, 4)
const PARTICLES := 14

var _size: int = 12
var _time: float = 0.0
var _last_step: int = -1


func start(pos: Vector2, size: int) -> void:
	global_position = pos
	_size = size
	_time = 0.0
	_last_step = -1
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	var step: int = _visual_step()
	if step != _last_step:
		_last_step = step
		queue_redraw()
	if _time >= DECAL_TIME:
		PoolManager.release(self)


func _visual_step() -> int:
	var rise: int = mini(int(_time / FRAME_TIME), RISE_FRAMES)
	var decal: int = mini(int(_time / (DECAL_TIME / DECAL_STEPS)), DECAL_STEPS - 1)
	return rise * 10 + decal


func _draw() -> void:
	var decal_step: int = mini(int(_time / (DECAL_TIME / DECAL_STEPS)), DECAL_STEPS - 1)
	# Decal: dithering cada vez mais esparso a cada passo.
	for y: int in DECAL_SIZE.y:
		for x: int in DECAL_SIZE.x:
			if (x + y * 3) % (decal_step + 1) == 0:
				draw_rect(Rect2(x - DECAL_SIZE.x / 2, y - DECAL_SIZE.y / 2, 1, 1), Palette.INK_SOFT)
	# Tinta subindo durante os 6 primeiros quadros.
	var frame: int = int(_time / FRAME_TIME)
	if frame >= RISE_FRAMES:
		return
	var half: int = _size / 2
	for n: int in PARTICLES:
		if n % RISE_FRAMES < frame:
			continue
		var x: int = (n * 7) % _size - half
		var y: int = -half - frame * 2 - (n % 3) * 2
		draw_rect(Rect2(x, y, 1, 1), Palette.INK if n % 2 == 0 else Palette.INK_SOFT)
