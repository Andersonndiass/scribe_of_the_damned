extends UiScreen
## Personagem (007 FR-703; ficha 27): 5 medalhões; só o Anselmo livre, os demais com cadeado (010).
## ←/→ navegam; confirmar num livre carimba o selo de cera (5 quadros @50 ms) e vai ao Capítulo;
## Esc volta ao Menu. Dados em `data/ui/characters.json`.

const DATA_PATH := "res://data/ui/characters.json"
const MEDAL_X: Array[int] = [128, 224, 320, 416, 512]
const MEDAL_Y := 150
const MEDAL_R := 34
const NAME_Y := 212
const PASSIVE_Y := 232
const TITLE_Y := 60
const STAMP_FRAMES := 5
const STAMP_FRAME := 0.05
const FOCUS_LIFT := 2

var characters: Array = []
var index: int = 0

var _stamp_left: float = -1.0
## Um busto por medalhão, em camadas (CloseView), e a camada de cima com o selo de cera.
var _busts: Array[CloseView] = []
var _overlay: Node2D


func _ready() -> void:
	super()
	characters = read_json(DATA_PATH).get("characters", [])
	for i: int in characters.size():
		var view := CloseView.new()
		view.show_layers(CharacterBusts.layers(str(characters[i]["id"]), not characters[i]["unlocked"]))
		add_child(view)
		_busts.append(view)
	_overlay = Node2D.new()
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


func _process(delta: float) -> void:
	super(delta)
	for i: int in _busts.size():
		var lift: int = FOCUS_LIFT if i == index else 0
		_busts[i].position = Vector2(MEDAL_X[i] - CharacterBusts.SIZE / 2.0, MEDAL_Y - lift - CharacterBusts.SIZE / 2.0).round()
	_overlay.queue_redraw()
	if _stamp_left > 0.0:
		_stamp_left -= delta
		if _stamp_left <= 0.0:
			request(&"chapter")


func handle_input(event: InputEvent) -> bool:
	if _stamp_left > 0.0 or characters.is_empty():
		return true
	var step: int = row_step(event, index, characters.size())
	if step >= 0:
		index = step
		return true
	var over: int = pointer_at(event, _medal_rects())
	if over >= 0:
		index = over
		if not clicked:
			return false
	if is_confirm(event) or (over >= 0 and clicked):
		if characters[index]["unlocked"]:
			GameState.picked_character = StringName(characters[index]["id"])
			_stamp_left = STAMP_FRAMES * STAMP_FRAME
		return true
	if is_back(event):
		request(&"menu")
		return true
	return false


func _medal_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for i: int in mini(characters.size(), MEDAL_X.size()):
		out.append(Rect2(MEDAL_X[i] - MEDAL_R, MEDAL_Y - MEDAL_R - FOCUS_LIFT, MEDAL_R * 2, MEDAL_R * 2 + FOCUS_LIFT))
	return out


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Palette.INK)
	PixelFont.draw_centered(self, tr(&"CHARACTER_TITLE"), 320, TITLE_Y, UiStyle.text_on_dark(), 2)
	for i: int in characters.size():
		var c: Dictionary = characters[i]
		var lift: int = FOCUS_LIFT if i == index else 0
		_draw_medallion(Vector2(MEDAL_X[i], MEDAL_Y - lift), c, i == index)
	if characters.is_empty():
		return
	var cur: Dictionary = characters[index]
	PixelFont.draw_centered(self, cur["name"], 320, NAME_Y, UiStyle.text_on_dark(), 2)
	var passive: String = tr(cur["passive"]) if cur["unlocked"] else tr(&"CHARACTER_LOCKED")
	PixelFont.draw_centered(self, passive, 320, PASSIVE_Y, UiStyle.text_on_dark(not cur["unlocked"]))
	PixelFont.draw_centered(self, tr(&"SCREEN_HINT_ROW").format({"cast": Settings.key_label(&"cast"), "back": Settings.key_label(&"pause")}), 320, 330, UiStyle.text_on_dark(true))


func _draw_medallion(center: Vector2, c: Dictionary, focused: bool) -> void:
	var unlocked: bool = c["unlocked"]
	var ring: Color = Palette.GOLD if unlocked else Palette.INK_SOFT
	# Círculos pelo ponto médio (D-076); o busto em camadas (silhueta + cadeado se bloqueado) é um nó por cima.
	if focused:
		UiStyle.disc(self, center, MEDAL_R + 3, Palette.GOLD_LIGHT)
		if UiStyle.high():
			UiStyle.ring(self, center, MEDAL_R + 4, Palette.CHALK)
	UiStyle.disc(self, center, MEDAL_R, Palette.INK)
	UiStyle.disc(self, center, MEDAL_R - 1, ring)
	UiStyle.disc(self, center, MEDAL_R - 3, Palette.PARCHMENT if unlocked else Palette.INK)


## Selo de cera ao confirmar, por cima do busto.
func _draw_overlay() -> void:
	if _stamp_left <= 0.0 or characters.is_empty():
		return
	var center := Vector2(MEDAL_X[index], MEDAL_Y - FOCUS_LIFT)
	var frame: int = STAMP_FRAMES - int(ceilf(_stamp_left / STAMP_FRAME))
	var seal_c: Vector2 = center + Vector2(MEDAL_R - 4, MEDAL_R - 4)
	var seal_r: int = 4 + (STAMP_FRAMES - frame)
	UiStyle.disc(_overlay, seal_c, seal_r + 1, Palette.INK)
	UiStyle.disc(_overlay, seal_c, seal_r, Palette.GOLD)
