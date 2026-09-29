extends UiScreen
## Splash (007 FR-701; ficha 27; animation-agent): sino que balança 6 quadros @90 ms uma vez, o
## título e "aperte qualquer tecla" piscando a cada 700 ms. Aceita tecla depois de 400 ms (a tecla
## também libera o áudio no web); sai sozinho para o Menu em 2,5 s.

const KEY_DELAY := 0.4
const AUTO_EXIT := 2.5
const BLINK := 0.7
const BELL_FRAME := 0.09
const BELL_SWING: Array[int] = [0, -2, -3, -2, 2, 0]
const BELL_POS := Vector2(320, 84)
const BELL_SIZE := 24
const TITLE_Y := 120
const PROMPT_Y := 260

var _left: bool = false


func _process(delta: float) -> void:
	super(delta)
	if age >= AUTO_EXIT:
		_leave()


func handle_input(event: InputEvent) -> bool:
	var pressed: bool = (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.is_pressed()
	if not pressed or event.is_echo():
		return false
	if age >= KEY_DELAY:
		_leave()
	return true


func _leave() -> void:
	if _left:
		return
	_left = true
	request(&"menu")


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Palette.INK)
	var frame: int = int(age / BELL_FRAME)
	var swing: int = BELL_SWING[frame] if frame < BELL_SWING.size() else 0
	_draw_bell(BELL_POS + Vector2(swing, 0))
	var title: String = tr(&"GAME_TITLE")
	PixelFont.draw_centered(self, title, 320, TITLE_Y, UiStyle.text_on_dark(), 2)
	var seat_w: float = PixelFont.width(title, 2) + 8
	draw_rect(Rect2(320 - seat_w / 2.0, TITLE_Y + PixelFont.height(2) + 3, seat_w, 1), Palette.GOLD)
	var blink_on: bool = int(age / BLINK) % 2 == 0
	var prompt_color: Color = UiStyle.text_on_dark(true) if blink_on else Palette.CHALK
	PixelFont.draw_centered(self, tr(&"SPLASH_PRESS_ANY"), 320, PROMPT_Y, prompt_color)


## Sino placeholder (UI_SPLASH_BELL): 24×24, bronze GOLD com sombra GOLD_LIGHT e badalo INK_SOFT.
func _draw_bell(center: Vector2) -> void:
	var top := Vector2(roundf(center.x), roundf(center.y - BELL_SIZE / 2.0))
	draw_rect(Rect2(top.x - 1, top.y, 3, 3), Palette.GOLD)
	for row: int in range(3, BELL_SIZE - 4):
		var half: int = 4 + (row * 7) / (BELL_SIZE - 4)
		draw_rect(Rect2(top.x - half, top.y + row, half * 2 + 1, 1), Palette.GOLD)
		# Luz da direita (art bible §3): o brilho fica no lado direito do bronze.
		draw_rect(Rect2(top.x + half - 2, top.y + row, 2, 1), Palette.GOLD_LIGHT)
	draw_rect(Rect2(top.x - 12, top.y + BELL_SIZE - 4, 25, 2), Palette.GOLD)
	draw_rect(Rect2(top.x - 1, top.y + BELL_SIZE - 2, 3, 2), Palette.INK_SOFT)
