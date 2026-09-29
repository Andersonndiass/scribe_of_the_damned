extends UiScreen
## Menu (007 FR-702; ficha 27): códice aberto com vela na página da esquerda e as fitas na da
## direita — Jogar · Grimório · Opções · Créditos (no web não há "Sair"). Grimório e Opções entram
## na Fase 3 (desabilitados até lá). Confirmar em Jogar folheia o livro (10 quadros @60 ms).

const TITLE_Y := 40
const BOOK := Rect2(180, 96, 280, 170)
const PAGE_W := 136
const SPINE_W := 8
const MENU_TOP := 130
## Fita mais curta que a da ficha (128) para caber na página de 136 px com o deslocamento do foco.
const MENU_RIBBON_W := 100
const FLAME_FRAME := 0.12
const FLIP_FRAMES := 10
const FLIP_FRAME := 0.06

var _flip_left: float = -1.0


func _ready() -> void:
	super()
	menu.add(&"play", "MENU_PLAY")
	menu.add(&"codex", "MENU_CODEX", false)
	menu.add(&"options", "MENU_OPTIONS", false)
	menu.add(&"credits", "MENU_CREDITS")


func _process(delta: float) -> void:
	super(delta)
	if _flip_left > 0.0:
		_flip_left -= delta
		if _flip_left <= 0.0:
			request(&"character")


func handle_input(event: InputEvent) -> bool:
	if _flip_left > 0.0:
		return true
	return super(event)


func _on_chosen(id: StringName) -> void:
	match id:
		&"play":
			_flip_left = FLIP_FRAMES * FLIP_FRAME
		&"credits":
			request(&"credits")


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Palette.INK)
	PixelFont.draw_centered(self, tr(&"GAME_TITLE"), 320, TITLE_Y, UiStyle.text_on_dark(), 2)
	_draw_book()
	if _flip_left > 0.0:
		_draw_flip()
		return
	draw_menu(BOOK.position.x + PAGE_W + SPINE_W + PAGE_W / 2.0 - UiStyle.RIBBON_FOCUS_SHIFT / 2.0, MENU_TOP, 22.0, MENU_RIBBON_W)


func _draw_book() -> void:
	draw_rect(BOOK.grow(3), Palette.BLOOD_DARK)
	var left := Rect2(BOOK.position, Vector2(PAGE_W, BOOK.size.y))
	var right := Rect2(BOOK.position + Vector2(PAGE_W + SPINE_W, 0), Vector2(PAGE_W, BOOK.size.y))
	draw_rect(left, Palette.PARCHMENT)
	draw_rect(right, Palette.PARCHMENT)
	draw_rect(Rect2(left.end.x, BOOK.position.y, SPINE_W, BOOK.size.y), Palette.PARCHMENT_OLD)
	draw_rect(Rect2(left.end.x + SPINE_W / 2.0 - 1, BOOK.position.y, 2, BOOK.size.y), Palette.INK_SOFT)
	# Linhas de texto-fantasma na página da esquerda, acima da vela.
	for i: int in 6:
		draw_rect(Rect2(left.position.x + 14, left.position.y + 16 + i * 8, PAGE_W - 28 - (i % 3) * 12, 1), Palette.PARCHMENT_OLD)
	_draw_candle(Vector2(left.position.x + PAGE_W / 2.0, left.end.y - 20))


## Vela placeholder: toco CHALK, pavio INK, chama GOLD/GOLD_LIGHT que tremula.
func _draw_candle(base: Vector2) -> void:
	var b := base.round()
	draw_rect(Rect2(b.x - 4, b.y - 28, 9, 28), Palette.CHALK)
	draw_rect(Rect2(b.x - 4, b.y - 28, 2, 28), Palette.PARCHMENT_OLD)
	draw_rect(Rect2(b.x - 7, b.y, 15, 3), Palette.GOLD)
	draw_rect(Rect2(b.x, b.y - 31, 1, 3), Palette.INK)
	var sway: int = [0, 1, 0, -1][int(age / FLAME_FRAME) % 4]
	draw_rect(Rect2(b.x - 2 + sway, b.y - 38, 5, 6), Palette.GOLD)
	draw_rect(Rect2(b.x - 1 + sway, b.y - 41, 3, 6), Palette.GOLD_LIGHT)


## Página da direita virando sobre a lombada (quadro a quadro).
func _draw_flip() -> void:
	var frame: int = clampi(FLIP_FRAMES - int(ceilf(_flip_left / FLIP_FRAME)), 0, FLIP_FRAMES - 1)
	var t: float = float(frame + 1) / FLIP_FRAMES
	var spine_x: float = BOOK.position.x + PAGE_W + SPINE_W / 2.0
	var w: float = roundf(PAGE_W * absf(1.0 - 2.0 * t))
	var x: float = spine_x if t < 0.5 else spine_x - w
	draw_rect(Rect2(x, BOOK.position.y - 2, w, BOOK.size.y + 4), Palette.PARCHMENT_OLD if t < 0.5 else Palette.PARCHMENT)
	draw_rect(Rect2(x if t >= 0.5 else x + w - 1, BOOK.position.y - 2, 1, BOOK.size.y + 4), Palette.INK_SOFT)
