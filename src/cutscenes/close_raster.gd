class_name CloseRaster
extends RefCounted
## Pincel de pixel para os closes das cutscenes (placeholders por script, D-024; 192×192 pela D-074):
## pinta numa Image uma vez (o close vira textura em cache). As coordenadas de desenho são as do
## "papel" de 128 (DESIGN), multiplicadas por K na hora de pintar — formas maiores, linhas finas
## continuam de 1 px (mais detalhe). Só cores da paleta; "desbotado" por xadrez em quartos (1 = 25%,
## 2 = 50%, 3 = 75%); sombra por hachura (art bible: 45° e 135°, cruzada nos closes, luz da direita).
## A máscara marca a silhueta, para o contorno no fim.

const DESIGN := 128
const SIZE := 192
const K := float(SIZE) / DESIGN

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


## Um pixel da imagem final (coordenadas de pixel, não de desenho).
func dot(x: int, y: int, c: Color, quarters: int = 0, solid: bool = false) -> void:
	if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
		return
	# A silhueta conta inteira, mesmo onde o xadrez deixa o fundo aparecer.
	if solid:
		mask[y * SIZE + x] = 1
	if quarters != 0 and not on_pattern(x, y, quarters):
		return
	img.set_pixel(x, y, c)


## Um "pixel" do desenho (vira um bloco K×K na imagem).
func px(x: float, y: float, c: Color, quarters: int = 0, solid: bool = false) -> void:
	rect(x, y, 1, 1, c, quarters, solid)


func rect(x: float, y: float, w: float, h: float, c: Color, quarters: int = 0, solid: bool = false) -> void:
	for yy: int in range(roundi(y * K), roundi((y + h) * K)):
		for xx: int in range(roundi(x * K), roundi((x + w) * K)):
			dot(xx, yy, c, quarters, solid)


func ellipse(cx: float, cy: float, rx: float, ry: float, c: Color, quarters: int = 0, solid: bool = false) -> void:
	var pcx: float = cx * K
	var pcy: float = cy * K
	var prx: float = rx * K
	var pry: float = ry * K
	for y: int in range(int(pcy - pry), int(pcy + pry) + 1):
		var k: float = 1.0 - pow((y + 0.5 - pcy) / pry, 2)
		if k < 0.0:
			continue
		var half: float = prx * sqrt(k)
		for x: int in range(int(roundf(pcx - half)), int(roundf(pcx + half))):
			dot(x, y, c, quarters, solid)


func polygon(points: PackedVector2Array, c: Color, quarters: int = 0, solid: bool = false) -> void:
	var scaled := PackedVector2Array()
	for p: Vector2 in points:
		scaled.append(p * K)
	var box := Rect2(scaled[0], Vector2.ZERO)
	for p: Vector2 in scaled:
		box = box.expand(p)
	for y: int in range(int(box.position.y), int(box.end.y) + 1):
		for x: int in range(int(box.position.x), int(box.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), scaled):
				dot(x, y, c, quarters, solid)


## Linha (Bresenham, em pixels da imagem) com espessura `t` px.
func line(a: Vector2, b: Vector2, c: Color, t: int = 1) -> void:
	var x0: int = roundi(a.x * K)
	var y0: int = roundi(a.y * K)
	var x1: int = roundi(b.x * K)
	var y1: int = roundi(b.y * K)
	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	while true:
		for oy: int in t:
			for ox: int in t:
				dot(x0 + ox, y0 + oy, c)
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


## Hachura dentro de `inside` (Callable(x, y) -> bool, em coordenadas de desenho), com o traço de
## 1 px a cada `spacing` px da imagem: 45° (sobe para a direita), 135° ou 90° (vertical: fios).
func hatch(area: Rect2i, inside: Callable, angle: int, spacing: int, c: Color, phase: int = 0) -> void:
	for y: int in range(roundi(area.position.y * K), roundi(area.end.y * K)):
		for x: int in range(roundi(area.position.x * K), roundi(area.end.x * K)):
			var k: int = x if angle == 90 else ((x + y) if angle == 45 else (x - y + SIZE))
			if (k + phase) % spacing == 0 and inside.call(x / K, y / K):
				dot(x, y, c)


## A cor do pixel da imagem que fica sob o ponto de desenho (x, y).
func color_at(x: float, y: float) -> Color:
	return img.get_pixel(clampi(roundi(x * K), 0, SIZE - 1), clampi(roundi(y * K), 0, SIZE - 1))


## Contorno de `w` px na cor `c` ao redor de tudo o que foi marcado como sólido.
func outline(c: Color, w: int = 3) -> void:
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
