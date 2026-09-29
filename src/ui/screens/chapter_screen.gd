extends UiScreen
## Capítulo (007 FR-703; ficha 27): 5 páginas; só o Cap. 1 aberto, os demais acorrentados com
## cadeado e "em breve". ←/→ navegam; confirmar no Cap. 1 começa a partida; Esc volta ao
## Personagem. Dados em `data/ui/chapters.json`.

const DATA_PATH := "res://data/ui/chapters.json"
const PAGE_SIZE := Vector2(88, 120)
const PAGE_Y := 90
const PAGE_X0 := 44
const PAGE_STEP := 116
const TITLE_Y := 50
const NAME_Y := 236
const FOCUS_LIFT := 2

var chapters: Array = []
var index: int = 0


func _ready() -> void:
	super()
	chapters = read_json(DATA_PATH).get("chapters", [])


func handle_input(event: InputEvent) -> bool:
	if chapters.is_empty():
		return false
	var step: int = row_step(event, index, chapters.size())
	if step >= 0:
		index = step
		return true
	if is_confirm(event):
		var ch: Dictionary = chapters[index]
		if ch["unlocked"] and ch["data"] != "":
			GameState.picked_chapter = load(ch["data"])
			request(&"game")
		return true
	if is_back(event):
		request(&"character")
		return true
	return false


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Palette.INK)
	PixelFont.draw_centered(self, tr(&"CHAPTER_SELECT_TITLE"), 320, TITLE_Y, UiStyle.text_on_dark(), 2)
	for i: int in chapters.size():
		var lift: int = FOCUS_LIFT if i == index else 0
		_draw_page(Rect2(Vector2(PAGE_X0 + i * PAGE_STEP, PAGE_Y - lift), PAGE_SIZE), chapters[i], i == index)
	if chapters.is_empty():
		return
	var cur: Dictionary = chapters[index]
	var title: String = tr(cur["title"]) if cur["unlocked"] else tr(&"COMING_SOON")
	PixelFont.draw_centered(self, title, 320, NAME_Y, UiStyle.text_on_dark(not cur["unlocked"]), 2)
	PixelFont.draw_centered(self, tr(&"SCREEN_HINT_ROW").format({"cast": Settings.key_label(&"cast"), "back": Settings.key_label(&"pause")}), 320, 330, UiStyle.text_on_dark(true))


func _draw_page(r: Rect2, ch: Dictionary, focused: bool) -> void:
	var unlocked: bool = ch["unlocked"]
	if focused:
		draw_rect(r.grow(UiStyle.outline_w() + 1), Palette.CHALK if UiStyle.high() else Palette.GOLD)
		draw_rect(r.grow(1), Palette.GOLD)
	draw_rect(r, Palette.PARCHMENT if unlocked else Palette.PARCHMENT_OLD)
	PixelFont.draw_centered(self, ch["numeral"], r.get_center().x, r.position.y + 16, Palette.INK, 2)
	for i: int in 7:
		draw_rect(Rect2(r.position.x + 10, r.position.y + 42 + i * 9, r.size.x - 20 - (i % 3) * 10, 1), Palette.INK_SOFT if unlocked else Palette.PARCHMENT)
	if unlocked:
		return
	if not UiStyle.high():
		UiStyle.dither(self, r, Palette.INK)
	# Correntes em X e cadeado no centro.
	for t: int in int(r.size.x / 4):
		var x: float = r.position.x + t * 4
		var y1: float = r.position.y + t * 4 * r.size.y / r.size.x
		draw_rect(Rect2(x, y1, 3, 2), Palette.INK_SOFT)
		draw_rect(Rect2(x, r.end.y - (y1 - r.position.y) - 2, 3, 2), Palette.INK_SOFT)
	draw_padlock(r.get_center() + Vector2(-3, -4), Palette.GOLD)
	PixelFont.draw_centered(self, ch["numeral"], r.get_center().x, r.position.y + 16, Palette.PARCHMENT, 2)
