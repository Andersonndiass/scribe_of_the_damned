class_name CloseRaster
extends RefCounted
## Pincel de pixel para os closes 128×128 (placeholders por script, D-024): pinta numa Image uma vez
## (o close vira textura em cache). Só cores da paleta; "desbotado" por xadrez em quartos (1 = 25%,
## 2 = 50%, 3 = 75%); sombra por hachura (art bible: 45° e 135°, cruzada nos closes, luz da direita).
## A máscara marca a silhueta, para o contorno de 2 px no fim.

const SIZE := 128

var img: Image
var mask := PackedByteArray()


func _init(bg: Color) -> void:
	img = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(bg)
	mask.resize(SIZE * SIZE)


static func on_pattern(x: int, y: int, quarters: int) -> bool:
	match quarters:
		1:
			return (x + 2 * y) % 4 == 0
		2:
			return (x + y) % 2 == 0
		3:
			return (x + y) % 2 == 0 or y % 2 == 0
	return true


## Um pixel (fora da tela é ignorado). `quarters` 0 = sólido.
func px(x: int, y: int, c: Color, quarters: int = 0, solid: bool = false) -> void:
	if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
		return
	# A silhueta conta inteira, mesmo onde o xadrez deixa o fundo aparecer.
	if solid:
		mask[y * SIZE + x] = 1
	if quarters != 0 and not on_pattern(x, y, quarters):
		return
	img.set_pixel(x, y, c)


func rect(x: int, y: int, w: int, h: int, c: Color, quarters: int = 0, solid: bool = false) -> void:
	for yy: int in range(y, y + h):
		for xx: int in range(x, x + w):
			px(xx, yy, c, quarters, solid)


func ellipse(cx: float, cy: float, rx: float, ry: float, c: Color, quarters: int = 0, solid: bool = false) -> void:
	for y: int in range(int(cy - ry), int(cy + ry) + 1):
		var k: float = 1.0 - pow((y - cy) / ry, 2)
		if k < 0.0:
			continue
		var half: float = rx * sqrt(k)
		for x: int in range(int(roundf(cx - half)), int(roundf(cx + half)) + 1):
			px(x, y, c, quarters, solid)


func polygon(points: PackedVector2Array, c: Color, quarters: int = 0, solid: bool = false) -> void:
	var box := Rect2(points[0], Vector2.ZERO)
	for p: Vector2 in points:
		box = box.expand(p)
	for y: int in range(int(box.position.y), int(box.end.y) + 1):
		for x: int in range(int(box.position.x), int(box.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				px(x, y, c, quarters, solid)


## Linha (Bresenham) com espessura `t` (quadrado t×t em cada ponto).
func line(a: Vector2, b: Vector2, c: Color, t: int = 1) -> void:
	var x0: int = int(a.x)
	var y0: int = int(a.y)
	var x1: int = int(b.x)
	var y1: int = int(b.y)
	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	while true:
		rect(x0, y0, t, t, c)
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


## Polilinha (curvas feitas de segmentos).
func path(points: PackedVector2Array, c: Color, t: int = 1) -> void:
	for i: int in range(points.size() - 1):
		line(points[i], points[i + 1], c, t)


## Hachura dentro de `inside` (Callable(x, y) -> bool): 45° (sobe para a direita) ou 135°.
func hatch(area: Rect2i, inside: Callable, angle: int, spacing: int, c: Color, phase: int = 0) -> void:
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var k: int = (x + y) if angle == 45 else (x - y + SIZE)
			if (k + phase) % spacing == 0 and inside.call(x, y):
				px(x, y, c)


## Contorno de `w` px na cor `c` ao redor de tudo o que foi marcado como sólido.
func outline(c: Color, w: int = 2) -> void:
	var out := PackedByteArray()
	out.resize(SIZE * SIZE)
	for y: int in SIZE:
		for x: int in SIZE:
			if mask[y * SIZE + x] == 1:
				continue
			var near: bool = false
			for dy: int in range(-w, w + 1):
				for dx: int in range(-w, w + 1):
					var nx: int = x + dx
					var ny: int = y + dy
					if nx >= 0 and ny >= 0 and nx < SIZE and ny < SIZE and mask[ny * SIZE + nx] == 1:
						near = true
						break
				if near:
					break
			if near:
				out[y * SIZE + x] = 1
	for i: int in out.size():
		if out[i] == 1:
			img.set_pixel(i % SIZE, i / SIZE, c)


func texture() -> ImageTexture:
	return ImageTexture.create_from_image(img)
