class_name HelpKeys
extends Node2D
## Ajuda de teclas à esquerda (D-098; design-agent, ficha UI_HELP_KEYS): 10 linhas em 4 grupos,
## tecla numa caixinha INK (segue o remap das Opções) + a ação. Cheia nas ondas 1 e 2; ao começar
## a onda 3 recolhe até a aba "H AJUDA"; a tecla H alterna. Recolhe/abre em 4 degraus de 50 ms
## (o miolo é cortado na altura de cada grupo, sem alpha). Some na hora com a lista de palavras
## (TAB), a pausa ou uma cutscene. Marca as linhas da letra com o menu da letra aberto.

const PLATE := Rect2(7, 46, 132, 135)
const TAB := Rect2(7, 46, 48, 15)
## Altura do miolo em cada degrau: 0 = aba; 4 = cheio.
const HEIGHTS: Array[float] = [15.0, 39.0, 67.0, 107.0, 135.0]
const STEP_TIME := 0.05
const AUTO_HIDE_WAVE := 3
const KEY_END_X := 49.0
const KEY_MIN_W := 9
const KEY_MAX_W := 39
const KEY_H := 9
const MAX_GLYPHS := 6
const TEXT_X := 53.0
const DIVIDER_X := 10.0
const DIVIDER_W := 126.0
## [topo y, grupo (1..4), ação ou rótulo especial, chave do texto]; "" = divisória.
const ROWS: Array = [
	[49, 1, "move", "HUD_HELP_MOVE"],
	[61, 1, "weapons", "HUD_HELP_WEAPON"],
	[73, 1, "potions", "HUD_HELP_POTION"],
	[85, 2, "", ""],
	[89, 2, "letter_browse", "HUD_HELP_LETTER_BROWSE"],
	[101, 2, "letter_pick", "HUD_HELP_LETTER_PICK"],
	[113, 3, "", ""],
	[117, 3, "cast", "HUD_HELP_CAST"],
	[129, 3, "purge", "HUD_HELP_PURGE"],
	[141, 3, "word_list", "HUD_HELP_WORDS"],
	[153, 4, "", ""],
	[157, 4, "pause", "HUD_HELP_PAUSE"],
	[169, 4, "help_toggle", "HUD_HELP_HIDE"],
]
const LETTER_MARK := Rect2(7, 89, 2, 21)
const ARROW_KEYS: Array[Key] = [KEY_UP, KEY_LEFT, KEY_DOWN, KEY_RIGHT]

## Degrau atual (0 = aba, 4 = cheio) e o alvo.
var stage: int = 4
var target: int = 4
## A lista de palavras (TAB) aberta esconde a ajuda (ela fica em cima).
var word_list: CanvasItem
var _t: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if word_list == null and get_parent() != null:
		word_list = get_parent().get_node_or_null(^"WordList") as CanvasItem  # irmão no mesmo HUD
	EventBus.wave_started.connect(func(index: int, _d: float) -> void:
		if index == AUTO_HIDE_WAVE:
			target = 0
		elif index < AUTO_HIDE_WAVE:
			target = 4)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"help_toggle", false) and not get_tree().paused:
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	target = 0 if target > 0 else 4


func is_hidden_now() -> bool:
	if get_tree().paused and not GameState.letter_menu_open:
		return true  # pausa, selos, loja (o menu da letra pausa, mas a ajuda das letras serve)
	return word_list != null and word_list.visible


func _process(delta: float) -> void:
	if stage != target:
		_t += delta
		if _t >= STEP_TIME:
			_t = 0.0
			stage += 1 if target > stage else -1
	visible = not is_hidden_now()
	queue_redraw()


## Área ocupada na tela (balões e ambientes desviam dela).
func hud_rect() -> Rect2:
	return UiStyle.plate_area(Rect2(PLATE.position, Vector2(TAB.size.x if stage == 0 else PLATE.size.x, HEIGHTS[stage])))


func _draw() -> void:
	if stage == 0:
		UiStyle.draw_plate(self, TAB)
		_draw_key("H" if Settings.key_label(&"help_toggle") == "" else Settings.key_label(&"help_toggle"), 49.0, 10.0)
		PixelFont.draw(self, tr(&"HUD_HELP_SHOW"), Vector2(22, 51), Palette.INK)
		return
	var core := Rect2(PLATE.position, Vector2(PLATE.size.x, HEIGHTS[stage]))
	UiStyle.draw_plate(self, core)
	for row: Array in ROWS:
		var group: int = row[1]
		if group > stage:
			continue
		var y: float = float(row[0])
		if row[2] == "":
			draw_rect(Rect2(DIVIDER_X, y, DIVIDER_W, 1), Palette.INK_SOFT)
			continue
		_draw_key(label_of(String(row[2])), y, -1.0)
		PixelFont.draw(self, tr(StringName(row[3])), Vector2(TEXT_X, y + 2), Palette.INK)
	if GameState.letter_menu_open and stage >= 2:
		draw_rect(LETTER_MARK, Palette.INK)


## Caixinha da tecla: fundo INK, texto CHALK, alinhada à direita em X49 (ou em `left`, se ≥ 0).
func _draw_key(label: String, y: float, left: float) -> void:
	var w: int = clampi(PixelFont.width(label) + 4, KEY_MIN_W, KEY_MAX_W)
	var x: float = left if left >= 0.0 else KEY_END_X - w
	draw_rect(Rect2(x, y, w, KEY_H), Palette.INK)
	PixelFont.draw(self, label, Vector2(x + 2, y + 2), Palette.CHALK)


## O rótulo da tecla de cada linha, das teclas atuais (segue o remap).
static func label_of(row: String) -> String:
	match row:
		"move":
			return move_label()
		"weapons":
			return _cut(Settings.key_label(&"weapon_1") + "/" + Settings.key_label(&"weapon_2"))
		"potions":
			return potions_label()
		"letter_browse":
			return "<>"
		"letter_pick":
			return _cut(TranslationServer.translate(&"KEY_SPACE"))
	return _cut(Settings.key_label(StringName(row)))


static func move_label() -> String:
	var actions: Array[StringName] = [&"move_up", &"move_left", &"move_down", &"move_right"]
	var labels: PackedStringArray = []
	var arrows: bool = true
	for k: int in actions.size():
		labels.append(Settings.key_label(actions[k]))
		arrows = arrows and Settings.binding(actions[k]) == ARROW_KEYS[k]
	if arrows:
		return _cut(TranslationServer.translate(&"HUD_HELP_ARROWS"))
	var out: String = ""
	for l: String in labels:
		out += l.left(1)
	return out


static func potions_label() -> String:
	var labels: PackedStringArray = []
	for i: int in 4:
		labels.append(Settings.key_label(StringName("potion_%d" % (i + 1))))
	var digits: bool = true
	for i: int in 4:
		digits = digits and labels[i].length() == 1 and labels[i].is_valid_int() \
			and int(labels[i]) == int(labels[0]) + i
	if digits:
		return "%s-%s" % [labels[0], labels[3]]
	return _cut("".join(labels))


static func _cut(s: String) -> String:
	return s.left(MAX_GLYPHS)
