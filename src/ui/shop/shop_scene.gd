class_name ShopScene
extends Node2D
## Cena do Scriptorium Noturno atrás das cartas da loja (003 ficha 28; refeita pela D-076 a pedido do
## autor: "essa tela dá para melhorar"), em CAMADAS (sprites separados, juntados na cena): fundo de
## tijolos e mesa, janela gótica com lua, estante, escrivaninha com livro aberto e tinteiro, vela
## (chama em 2 quadros) e o escriba sentado com o braço que escreve (6 quadros, os da ficha 28).
## Regras de pixel art (D-075/D-076): blocos lisos, luz da direita (e da vela), contorno INK, sem
## pixel solto; xadrez nenhum. Placeholder por script (D-024).

const WALL_BOTTOM := 216.0
const TABLE := Rect2(0, 216, 640, 56)
const CLEAR := Color(0, 0, 0, 0)
const FLAME_FRAME := 0.24
const ARM_FRAME := 0.2
## Posições das camadas na tela (canto de cima à esquerda de cada textura).
const WINDOW_AT := Vector2(14, 26)
const SHELF_AT := Vector2(100, 34)
const DESK_AT := Vector2(96, 144)
const CANDLE_AT := Vector2(160, 176)
const SCRIBE_AT := Vector2(22, 120)
## Pontas da pena nos 6 quadros do braço (coordenadas do escriba).
const ARM_TIPS: Array[Vector2] = [Vector2(84, 76), Vector2(90, 74), Vector2(95, 77), Vector2(88, 79), Vector2(82, 78), Vector2(93, 75)]
const SHOULDER := Vector2(52, 58)
## Raio da luz da vela na parede (tijolos acesos).
const LIGHT_R := 40.0

var _t: float = 0.0
var _flames: Array[Texture2D] = []
var _arms: Array[Texture2D] = []
var _candle: Sprite2D
var _arm: Sprite2D

static var _cache: Dictionary = {}


func _ready() -> void:
	var back := Node2D.new()
	back.name = "Fundo"
	back.draw.connect(func() -> void: _draw_back(back))
	add_child(back)
	_add_layer("Janela", _window(), WINDOW_AT)
	_add_layer("Estante", _shelf(), SHELF_AT)
	_add_layer("Escrivaninha", _desk(), DESK_AT)
	_flames = [_candle_tex(0), _candle_tex(1)]
	_candle = _add_layer("Vela", _flames[0], CANDLE_AT)
	_add_layer("Escriba", _scribe(), SCRIBE_AT)
	for i: int in ARM_TIPS.size():
		_arms.append(_arm_tex(i))
	_arm = _add_layer("Braco", _arms[0], SCRIBE_AT)


func _process(delta: float) -> void:
	_t += delta
	_candle.texture = _flames[int(_t / FLAME_FRAME) % _flames.size()]
	_arm.texture = _arms[int(_t / ARM_FRAME) % _arms.size()]


func _add_layer(layer_name: String, tex: Texture2D, at: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = layer_name
	s.centered = false
	s.texture = tex
	s.position = at
	add_child(s)
	return s


## Fundo: parede de tijolos (INK com juntas INK_SOFT); perto da vela os tijolos acendem (face INK_SOFT,
## juntas INK) — luz em blocos, sem pontos soltos; e a mesa comprida.
func _draw_back(c: CanvasItem) -> void:
	c.draw_rect(Rect2(0, 0, 640, 360), Palette.INK)
	var light := CANDLE_AT + Vector2(6, 4)
	for row: int in int(WALL_BOTTOM / 16):
		var y: float = row * 16.0
		var off: float = 16.0 if row % 2 == 1 else 0.0
		for k: int in range(-1, 640 / 32 + 1):
			var brick := Rect2(k * 32 + off + 1, y + 1, 31, 15)
			if brick.get_center().distance_to(light) <= LIGHT_R:
				c.draw_rect(brick, Palette.INK_SOFT)
		c.draw_rect(Rect2(0, y, 640, 1), Palette.INK_SOFT)
		for k: int in range(0, 640 / 32 + 1):
			c.draw_rect(Rect2(k * 32 + off, y, 1, 16), Palette.INK_SOFT)
		# Nos tijolos acesos, a junta fica escura (o contraste inverte perto da luz).
		for k: int in range(-1, 640 / 32 + 1):
			var brick2 := Rect2(k * 32 + off + 1, y + 1, 31, 15)
			if brick2.get_center().distance_to(light) <= LIGHT_R:
				c.draw_rect(Rect2(brick2.position.x - 1, y, 33, 1), Palette.INK)
				c.draw_rect(Rect2(brick2.position.x - 1, y, 1, 16), Palette.INK)
	c.draw_rect(TABLE, Palette.INK_SOFT)
	c.draw_rect(Rect2(TABLE.position, Vector2(TABLE.size.x, 2)), Palette.PARCHMENT_OLD)
	c.draw_rect(Rect2(0, TABLE.end.y - 4, 640, 4), Palette.INK)


static func _v(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i: int in range(0, points.size(), 2):
		out.append(Vector2(points[i], points[i + 1]))
	return out


static func _raster(side: int) -> CloseRaster:
	return CloseRaster.new(CLEAR, side, side)


## Janela gótica 64×64: moldura de pedra, céu noturno, lua (luz da direita), 3 estrelas em cruz.
static func _window() -> Texture2D:
	if _cache.has("window"):
		return _cache["window"]
	var r := _raster(64)
	var arch := func(x: float, y: float, grow: float) -> bool:
		return (y >= 22 and x >= 12 - grow and x < 52 + grow and y < 62) or Vector2(x, y).distance_to(Vector2(32, 22)) <= 20.0 + grow
	for y: int in 64:
		for x: int in 64:
			if arch.call(x + 0.5, y + 0.5, 3.0):
				r.px(x, y, Palette.PARCHMENT_OLD, 0, true)
	for y: int in 64:
		for x: int in 64:
			if arch.call(x + 0.5, y + 0.5, 0.0):
				r.px(x, y, Palette.INK_SOFT)
	# Pedra: luz na borda direita da moldura.
	for y: int in range(4, 62):
		for x: int in range(52, 56):
			if arch.call(x + 0.5, y + 0.5, 3.0) and not arch.call(x + 0.5, y + 0.5, 1.0):
				r.px(x, y, Palette.PARCHMENT)
	r.ellipse(40, 14, 5, 5, Palette.CHALK)
	r.rect(35, 12, 2, 5, Palette.PARCHMENT_OLD)
	for s: Vector2 in [Vector2(20, 14), Vector2(24, 34), Vector2(44, 48)]:
		r.rect(s.x - 1, s.y, 3, 1, Palette.CHALK)
		r.rect(s.x, s.y - 1, 1, 3, Palette.CHALK)
	r.rect(31, 4, 2, 58, Palette.INK)
	r.rect(12, 38, 40, 2, Palette.INK)
	r.rect(8, 62, 48, 2, Palette.PARCHMENT_OLD, 0, true)
	r.outline(Palette.INK, 1)
	_cache["window"] = r.texture()
	return _cache["window"]


## Estante 80×80 com três prateleiras de livros de alturas e cores variadas.
static func _shelf() -> Texture2D:
	if _cache.has("shelf"):
		return _cache["shelf"]
	var r := _raster(80)
	r.rect(4, 2, 72, 76, Palette.INK_SOFT, 0, true)
	r.rect(8, 6, 64, 68, Palette.INK)
	r.rect(74, 2, 2, 76, Palette.PARCHMENT_OLD)
	var colors: Array[Color] = [Palette.PARCHMENT_OLD, Palette.INK_SOFT, Palette.PARCHMENT, Palette.PARCHMENT_OLD, Palette.INK_SOFT]
	var widths: Array[int] = [5, 4, 6, 4, 5, 3, 6, 5, 4]
	var heights: Array[int] = [16, 18, 14, 19, 15, 17, 13, 18, 16]
	for shelf: int in 3:
		var base: int = 26 + shelf * 23
		var x: int = 10 + shelf * 2
		var i: int = shelf * 3
		while x < 68:
			var w: int = widths[i % widths.size()]
			var h: int = heights[(i + shelf) % heights.size()]
			if x + w > 71:
				break
			var col: Color = colors[i % colors.size()]
			r.rect(x, base - h, w, h, col)
			r.rect(x, base - h, 1, h, Palette.INK)
			if i % 4 == 1:
				r.rect(x + 1, base - h + 3, w - 1, 1, Palette.GOLD)
			x += w + (1 if i % 3 == 0 else 0)
			i += 1
		r.rect(6, base, 68, 3, Palette.INK_SOFT)
		r.rect(6, base, 68, 1, Palette.PARCHMENT_OLD)
	r.outline(Palette.INK, 1)
	_cache["shelf"] = r.texture()
	return _cache["shelf"]


## Escrivaninha 80×80: atril inclinado com livro aberto (texto em blocos), tinteiro e pena.
static func _desk() -> Texture2D:
	if _cache.has("desk"):
		return _cache["desk"]
	var r := _raster(80)
	r.polygon(_v([4, 62, 60, 52, 60, 58, 4, 68]), Palette.INK_SOFT, 0, true)
	r.polygon(_v([4, 66, 60, 56, 60, 58, 4, 68]), Palette.INK)
	r.rect(28, 64, 6, 8, Palette.INK_SOFT, 0, true)
	r.rect(28, 64, 2, 8, Palette.INK)
	# Livro aberto sobre o atril: página da esquerda na sombra, texto em blocos curtos.
	r.polygon(_v([8, 58, 31, 54, 31, 45, 8, 49]), Palette.PARCHMENT_OLD, 0, true)
	r.polygon(_v([31, 54, 56, 50, 56, 41, 31, 45]), Palette.PARCHMENT, 0, true)
	r.rect(31, 45, 1, 9, Palette.INK_SOFT)
	for line: int in 3:
		r.line(Vector2(11, 51 - line * 2), Vector2(27, 48 - line * 2), Palette.INK_SOFT)
		r.line(Vector2(35, 50 - line * 2), Vector2(52, 47 - line * 2), Palette.INK_SOFT)
	# Tinteiro com a pena.
	r.rect(64, 64, 8, 8, Palette.INK, 0, true)
	r.rect(65, 62, 6, 2, Palette.INK_SOFT, 0, true)
	r.rect(70, 65, 1, 2, Palette.INK_SOFT)
	r.line(Vector2(68, 62), Vector2(76, 50), Palette.CHALK, 2)
	r.outline(Palette.INK, 1)
	_cache["desk"] = r.texture()
	return _cache["desk"]


## Vela 16×40 no castiçal; `frame` alterna a chama (a luz é da própria vela).
static func _candle_tex(frame: int) -> Texture2D:
	var key: String = "candle%d" % frame
	if _cache.has(key):
		return _cache[key]
	var r := _raster(40)
	r.rect(6, 12, 5, 24, Palette.CHALK, 0, true)
	r.rect(6, 12, 2, 24, Palette.PARCHMENT_OLD)
	r.rect(10, 16, 1, 5, Palette.PARCHMENT)
	r.rect(2, 36, 13, 3, Palette.GOLD, 0, true)
	r.rect(11, 36, 4, 1, Palette.GOLD_LIGHT)
	r.rect(8, 9, 1, 3, Palette.INK)
	var sway: int = 1 if frame == 1 else 0
	r.polygon(_v([8 + sway, 1, 11 + sway, 5, 11, 9, 6, 9, 6, 5]), Palette.GOLD)
	r.rect(8 + sway, 5, 2, 3, Palette.GOLD_LIGHT)
	r.outline(Palette.INK, 1)
	_cache[key] = r.texture()
	return _cache[key]


## Cabeça de perfil 16×18 (virada para a direita), pixel a pixel: coroa careca com brilho da vela,
## anel de cabelo da tonsura (k), orelha, olho, sobrancelha, nariz, boca e a sombra da nuca e do queixo.
## K INK · k INK_SOFT · P PARCHMENT · O PARCHMENT_OLD · C CHALK.
const HEAD: Array[String] = [
	"....KKKKKK......",
	"...KPPPPCCK.....",
	"..KOPPPPPCCK....",
	".KkOPPPPPPPPK...",
	".KkkkkPPPPPPPK..",
	"KkkkkkkPPkkkPK..",
	"KkkOOkkPPPPPPK..",
	"KkOPOOkPPPKCPK..",
	"KkOOOkkPPPPPPPK.",
	"KkkOkkOPPPPPPPPK",
	".KkkkOOPPPPPCOK.",
	".KkkOOOPPPPPK...",
	"..KkOOPPPPKKK...",
	"..KOOOPPPPPK....",
	"...KOOPPPPK.....",
	"...KOOOOOK......",
	"....KOOOK.......",
	"....KOOOK.......",
]
const HEAD_AT := Vector2i(46, 25)


## Escriba sentado 96×96, de lado, curvado sobre o livro: banco, hábito com cordão e pregas, a luz
## da vela no contorno direito, capuz dobrado nas costas, a outra mão apoiada no livro e a cabeça.
static func _scribe() -> Texture2D:
	if _cache.has("scribe"):
		return _cache["scribe"]
	var r := _raster(96)
	# Banco.
	r.rect(24, 84, 36, 4, Palette.INK_SOFT, 0, true)
	r.rect(24, 84, 36, 1, Palette.PARCHMENT_OLD)
	r.rect(28, 88, 4, 8, Palette.INK_SOFT, 0, true)
	r.rect(52, 88, 4, 8, Palette.INK_SOFT, 0, true)
	# Braço de trás (na sombra) com a mão apoiada na página esquerda do livro.
	r.polygon(_v([56, 50, 64, 54, 78, 68, 76, 72, 60, 62]), Palette.INK, 0, true)
	r.rect(77, 68, 5, 3, Palette.PARCHMENT_OLD, 0, true)
	r.rect(81, 69, 1, 2, Palette.PARCHMENT)
	# Hábito curvado: costas na sombra (bloco INK), frente INK_SOFT, luz da vela no contorno direito.
	r.polygon(_v([24, 86, 22, 70, 24, 58, 30, 48, 40, 42, 50, 42, 58, 46, 64, 54, 68, 64, 70, 86]), Palette.INK_SOFT, 0, true)
	r.polygon(_v([24, 86, 22, 70, 24, 58, 30, 48, 36, 45, 32, 60, 31, 86]), Palette.INK)
	r.path(_v([59, 47, 64, 54, 68, 63, 70, 84]), Palette.PARCHMENT_OLD)
	# Pregas longas e o cordão na cintura com o nó pendurado.
	r.path(_v([44, 72, 45, 86]), Palette.INK)
	r.path(_v([56, 72, 58, 86]), Palette.INK)
	r.line(Vector2(30, 70), Vector2(68, 67), Palette.PARCHMENT_OLD, 2)
	r.rect(60, 69, 2, 9, Palette.PARCHMENT_OLD)
	r.rect(59, 78, 4, 2, Palette.PARCHMENT_OLD)
	# Capuz dobrado nas costas: rolo INK_SOFT com o lado de baixo INK e um fio de luz em cima.
	r.polygon(_v([32, 46, 38, 38, 48, 35, 52, 38, 47, 44, 39, 49]), Palette.INK_SOFT, 0, true)
	r.polygon(_v([32, 46, 36, 41, 40, 45, 39, 49]), Palette.INK)
	r.path(_v([40, 37, 47, 35, 51, 37]), Palette.PARCHMENT_OLD)
	# Cabeça (mapa pixel a pixel).
	for y: int in HEAD.size():
		for x: int in HEAD[y].length():
			var ch: String = HEAD[y][x]
			if ch == ".":
				continue
			var c: Color = Palette.INK
			match ch:
				"k":
					c = Palette.INK_SOFT
				"P":
					c = Palette.PARCHMENT
				"O":
					c = Palette.PARCHMENT_OLD
				"C":
					c = Palette.CHALK
			r.px(HEAD_AT.x + x, HEAD_AT.y + y, c, 0, true)
	r.outline(Palette.INK, 1)
	_cache["scribe"] = r.texture()
	return _cache["scribe"]


## Braço que escreve, 96×96 (mesma origem do escriba): manga larga dobrada no cotovelo (INK_SOFT com a
## parte de baixo INK e a de cima iluminada), a boca da manga aberta, a mão e a pena (bico GOLD) na
## ponta do quadro `i`.
static func _arm_tex(i: int) -> Texture2D:
	var key: String = "arm%d" % i
	if _cache.has(key):
		return _cache[key]
	var r := _raster(96)
	var tip: Vector2 = ARM_TIPS[i]
	var hand: Vector2 = tip + Vector2(-5, 3)
	var elbow: Vector2 = Vector2(SHOULDER.x + 6, SHOULDER.y + 12)
	var cuff: Vector2 = hand + Vector2(-5, 0)
	# Manga: do ombro ao cotovelo e do cotovelo à boca da manga, larga.
	r.polygon(PackedVector2Array([SHOULDER + Vector2(-3, -3), SHOULDER + Vector2(4, -2), elbow + Vector2(4, 0),
		cuff + Vector2(0, -3), cuff + Vector2(1, 4), elbow + Vector2(-2, 5), SHOULDER + Vector2(-4, 4)]), Palette.INK_SOFT, 0, true)
	r.path(PackedVector2Array([elbow + Vector2(-2, 5), cuff + Vector2(1, 4)]), Palette.INK)
	r.path(PackedVector2Array([SHOULDER + Vector2(4, -2), elbow + Vector2(4, 0), cuff + Vector2(0, -3)]), Palette.PARCHMENT_OLD)
	r.rect(cuff.x - 1, cuff.y - 3, 2, 8, Palette.INK)
	# Mão: bloco de pele com a sombra embaixo; a pena sai entre os dedos.
	r.rect(hand.x - 2, hand.y - 2, 5, 4, Palette.PARCHMENT, 0, true)
	r.rect(hand.x - 2, hand.y + 1, 5, 1, Palette.PARCHMENT_OLD)
	# Pena: haste CHALK de 2 px, barbas mais largas em cima, bico GOLD encostando na página.
	r.line(tip, tip + Vector2(5, -10), Palette.CHALK, 2)
	r.polygon(PackedVector2Array([tip + Vector2(4, -8), tip + Vector2(9, -15), tip + Vector2(10, -13), tip + Vector2(6, -7)]), Palette.CHALK, 0, true)
	r.rect(tip.x, tip.y, 1, 1, Palette.GOLD)
	r.outline(Palette.INK, 1)
	_cache[key] = r.texture()
	return _cache[key]
