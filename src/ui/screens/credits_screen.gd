extends UiScreen
## Créditos (007 T713; ficha 30): pergaminho entre dois rolos com o texto subindo a 30 px/s;
## segurar Espaço ou ↓ acelera 3×; Esc volta; no fim, volta ao Menu. Dados em `data/ui/credits.json`.

const DATA_PATH := "res://data/ui/credits.json"
const SPEED := 30.0
const FAST := 3.0
const PAPER := Rect2(128, 36, 384, 288)
const ROLL_TOP_Y := 24
const ROLL_BOTTOM_Y := 324
const ROLL_H := 12
const LINE_STEP := 10
const SECTION_STEP := 20

var lines: Array[Dictionary] = []
var scroll: float = 0.0
var total_height: float = 0.0

var _done: bool = false


func _ready() -> void:
	super()
	var y: float = 0.0
	for s: Dictionary in read_json(DATA_PATH).get("sections", []):
		lines.append({"text": s["title"], "y": y, "title": true})
		y += LINE_STEP
		for l: String in s["lines"]:
			lines.append({"text": l, "y": y, "title": false})
			y += LINE_STEP
		y += SECTION_STEP
	total_height = y


func _process(delta: float) -> void:
	super(delta)
	var fast: bool = Input.is_action_pressed(&"cast") or Input.is_action_pressed(&"move_down")
	scroll += SPEED * (FAST if fast else 1.0) * delta
	if scroll > total_height + PAPER.size.y and not _done:
		_done = true
		request(&"menu")


func handle_input(event: InputEvent) -> bool:
	if is_back(event):
		_done = true
		request(&"menu")
		return true
	return false


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Palette.INK)
	draw_rect(PAPER, Palette.PARCHMENT)
	var top: float = PAPER.end.y - scroll
	for l: Dictionary in lines:
		var y: float = roundf(top + l["y"])
		if y < PAPER.position.y + 2 or y > PAPER.end.y - PixelFont.height() - 2:
			continue
		var color: Color = Palette.BLOOD if l["title"] else Palette.INK
		PixelFont.draw_centered(self, tr(l["text"]), 320, y, color)
	for ry: int in [ROLL_TOP_Y, ROLL_BOTTOM_Y]:
		draw_rect(Rect2(PAPER.position.x - 8, ry, PAPER.size.x + 16, ROLL_H), Palette.PARCHMENT_OLD)
		draw_rect(Rect2(PAPER.position.x - 8, ry + ROLL_H - 2, PAPER.size.x + 16, 2), Palette.INK_SOFT)
		draw_rect(Rect2(PAPER.position.x - 12, ry + 2, 4, ROLL_H - 4), Palette.GOLD)
		draw_rect(Rect2(PAPER.end.x + 8, ry + 2, 4, ROLL_H - 4), Palette.GOLD)
