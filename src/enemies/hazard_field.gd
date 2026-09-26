class_name HazardField
extends Node2D
## Poças de lentidão do Borrão (005 FR-507): arrays + um único _draw, teto fixo (sem nós).
## Visual distinto da poça de heresia (vermelha e tracejada): tinta INK_SOFT em dithering
## com brilho CHALK molhado (art bible §6.3; parecer do game-design-agent).

const CAPACITY := 24

var count: int = 0

var _rect: Array[Rect2] = []
var _left := PackedFloat32Array()
var _slow := PackedFloat32Array()


func _init() -> void:
	_rect.resize(CAPACITY)
	_left.resize(CAPACITY)
	_slow.resize(CAPACITY)


func _ready() -> void:
	add_to_group(&"hazards")


## Cria uma poça centrada em `center`. Retorna false se o teto foi atingido.
func add_puddle(data: PuddleData, center: Vector2) -> bool:
	if count >= CAPACITY:
		return false
	_rect[count] = Rect2(center - data.size / 2.0, data.size)
	_left[count] = data.duration
	_slow[count] = data.player_slow_factor
	count += 1
	queue_redraw()
	return true


## Multiplicador de velocidade em `pos` (1.0 = normal). Poças sobrepostas não se somam.
func slow_at(pos: Vector2) -> float:
	var f: float = 1.0
	for i: int in count:
		if _rect[i].has_point(pos):
			f = minf(f, _slow[i])
	return f


func clear() -> void:
	count = 0
	queue_redraw()


func _process(delta: float) -> void:
	if count == 0:
		return
	var i: int = 0
	var changed: bool = false
	while i < count:
		_left[i] -= delta
		if _left[i] <= 0.0:
			var last: int = count - 1
			_rect[i] = _rect[last]
			_left[i] = _left[last]
			_slow[i] = _slow[last]
			count -= 1
			changed = true
		else:
			i += 1
	if changed:
		queue_redraw()


func _draw() -> void:
	for i: int in count:
		var r: Rect2 = _rect[i]
		var x0: int = int(r.position.x)
		var y0: int = int(r.position.y)
		var cx: float = r.get_center().x
		var cy: float = r.get_center().y
		var rx: float = r.size.x / 2.0
		var ry: float = r.size.y / 2.0
		for y: int in range(y0, y0 + int(r.size.y)):
			for x: int in range(x0 + (y % 2), x0 + int(r.size.x), 2):
				var nx: float = (x - cx) / rx
				var ny: float = (y - cy) / ry
				if nx * nx + ny * ny <= 1.0:
					draw_rect(Rect2(x, y, 1, 1), Palette.INK_SOFT)
		draw_rect(Rect2(roundf(cx - 3), y0 + 2, 3, 1), Palette.CHALK)
