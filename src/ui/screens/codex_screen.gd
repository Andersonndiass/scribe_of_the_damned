extends UiScreen
## Grimório (007 FR-709, FR-710, T721; ficha 30, layout do design-agent). Livro aberto com 4 abas
## (Palavras, Combos, Inimigos, Chefes); cada entrada ocupa as duas páginas: nome, ilustração e
## índice à esquerda; significado e verbete (narrativa §11) à direita. ←/→ vira a página (8 quadros
## @50 ms; guarda 1 comando), ↑/↓ troca a aba, Esc volta. Não descoberta = "?????" e silhueta.
## Conhecimento, não poder (D-018). Dados em `data/codex/codex.json`; textos em `i18n/ui.csv`.

const DATA_PATH := "res://data/codex/codex.json"
const FLIP_FRAMES := 8
const FLIP_FRAME := 0.05
# Layout (design-agent).
const BOOK := Rect2(32, 56, 576, 256)
const PAGE_W := 280
const SPINE := Rect2(312, 56, 16, 256)
const LEFT_X := 172
const RIGHT_X := 468
const TITLE_Y := 12
const HINT_Y := 326
const TAB_X0 := 154
const TAB_STEP := 84
const TAB_W := 80
const NAME_Y := 70
const NAME_MAX_BIG := 20
const FRAME := Rect2(108, 104, 128, 128)
const PIP_Y := 246
const PIP_STEP := 8
const COUNT_Y := 292
const MEANING_Y := 70
const KIND_Y := 73
const RULE_Y := 88
const LORE_X := 344
const LORE_STEP := 10
const LORE_CHARS := 40
const LORE_LINES := 6
const FOLIO_Y := 292
const TILE := 10
const TILE_STEP := 12

var tabs: Array = []
var tab: int = 0
var index: int = 0

var _flip_left: float = 0.0
var _flip_dir: int = 1
var _queued: int = 0


func _ready() -> void:
	super()
	tabs = read_json(DATA_PATH).get("tabs", [])


func entries() -> Array:
	return tabs[tab]["entries"] if not tabs.is_empty() else []


func current() -> Dictionary:
	return entries()[index] if not entries().is_empty() else {}


func category() -> StringName:
	return StringName(tabs[tab]["id"])


func is_known(entry: Dictionary) -> bool:
	return Codex.is_discovered(category(), StringName(entry["id"]))


func found_count() -> int:
	var n: int = 0
	for e: Dictionary in entries():
		if is_known(e):
			n += 1
	return n


func _process(delta: float) -> void:
	super(delta)
	if _flip_left > 0.0:
		_flip_left = maxf(_flip_left - delta, 0.0)
		if _flip_left == 0.0 and _queued != 0:
			var q: int = _queued
			_queued = 0
			_step_entry(q)


func handle_input(event: InputEvent) -> bool:
	if tabs.is_empty() or not event.is_pressed() or event.is_echo():
		return false
	# Mouse (D-084): clique na aba troca a aba; na página esquerda volta, na direita avança.
	var tab_hit: int = pointer_at(event, _tab_rects())
	if tab_hit >= 0 and clicked:
		if tab_hit != tab:
			_flip_dir = 1 if tab_hit > tab else -1
			tab = tab_hit
			index = 0
			_flip_left = FLIP_FRAMES * FLIP_FRAME
		return true
	var page_hit: int = pointer_at(event, [Rect2(BOOK.position, Vector2(PAGE_W, BOOK.size.y)),
		Rect2(Vector2(SPINE.end.x, BOOK.position.y), Vector2(PAGE_W, BOOK.size.y))] as Array[Rect2])
	if page_hit >= 0 and clicked:
		var dir: int = -1 if page_hit == 0 else 1
		if _flip_left > 0.0:
			_queued = dir
		else:
			_step_entry(dir)
		return true
	if event.is_action(&"move_right") or event.is_action(&"move_left"):
		var dir: int = 1 if event.is_action(&"move_right") else -1
		if _flip_left > 0.0:
			_queued = dir
		else:
			_step_entry(dir)
	elif event.is_action(&"move_down") or event.is_action(&"move_up"):
		var dir: int = 1 if event.is_action(&"move_down") else -1
		var t: int = (tab + dir + tabs.size()) % tabs.size()
		if t != tab:
			_flip_dir = 1 if t > tab else -1
			tab = t
			index = 0
			_flip_left = FLIP_FRAMES * FLIP_FRAME
	elif is_back(event):
		leave()
	else:
		return false
	return true


## Entrada anterior/seguinte; nas pontas da aba não faz nada.
func _step_entry(dir: int) -> void:
	var i: int = index + dir
	if i < 0 or i >= entries().size():
		return
	index = i
	_flip_dir = dir
	_flip_left = FLIP_FRAMES * FLIP_FRAME


## Quebra por palavra em linhas de até `width` caracteres.
static func wrap_words(text: String, width: int) -> PackedStringArray:
	return UiStyle.wrap_words(text, width)


# --- Desenho ---------------------------------------------------------------------------------

func _draw() -> void:
	if embedded:
		UiStyle.dim_screen(self, UiStyle.dim_level())
		var tw: float = PixelFont.width(tr(&"CODEX_TITLE"), 2) + 12
		draw_rect(Rect2(320 - tw / 2.0, TITLE_Y - 3, tw, PixelFont.height(2) + 6), Palette.INK)
	else:
		draw_rect(Rect2(0, 0, 640, 360), Palette.INK)
	PixelFont.draw_centered(self, tr(&"CODEX_TITLE"), 320, TITLE_Y, UiStyle.text_on_dark(), 2)
	if tabs.is_empty():
		return
	_draw_tabs()
	draw_rect(BOOK.grow(3), Palette.BLOOD_DARK)
	draw_rect(Rect2(BOOK.position, Vector2(PAGE_W, BOOK.size.y)), Palette.PARCHMENT)
	draw_rect(Rect2(SPINE.end.x, BOOK.position.y, PAGE_W, BOOK.size.y), Palette.PARCHMENT)
	draw_rect(SPINE, Palette.PARCHMENT_OLD)
	draw_rect(Rect2(SPINE.get_center().x - 1, SPINE.position.y, 2, SPINE.size.y), Palette.INK_SOFT)
	var e: Dictionary = current()
	var known: bool = is_known(e)
	_draw_left(e, known)
	_draw_right(e, known)
	if _flip_left > 0.0:
		_draw_flip()
	var hint: String = tr(&"CODEX_HINT").format({
		"prev": Settings.key_label(&"move_left"), "next": Settings.key_label(&"move_right"),
		"up": Settings.key_label(&"move_up"), "down": Settings.key_label(&"move_down"),
		"back": Settings.key_label(&"pause")})
	if embedded:
		var hw: float = PixelFont.width(hint) + 12
		draw_rect(Rect2(320 - hw / 2.0, HINT_Y - 3, hw, PixelFont.height() + 6), Palette.INK)
	PixelFont.draw_centered(self, hint, 320, HINT_Y, UiStyle.text_on_dark(true))


func _tab_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for i: int in tabs.size():
		out.append(Rect2(TAB_X0 + i * TAB_STEP, 36, TAB_W, 20))
	return out


func _draw_tabs() -> void:
	for i: int in tabs.size():
		var x: float = TAB_X0 + i * TAB_STEP
		var active: bool = i == tab
		var r := Rect2(x, 36, TAB_W, 20) if active else Rect2(x, 42, TAB_W, 14)
		if UiStyle.high():
			draw_rect(r.grow(1), Palette.CHALK)
		draw_rect(r.grow_individual(UiStyle.outline_w() if active else 1.0, 1, UiStyle.outline_w() if active else 1.0, 0), Palette.INK_SOFT)
		draw_rect(r, Palette.PARCHMENT if active else Palette.PARCHMENT_OLD)
		if active:
			draw_rect(Rect2(x, 36, TAB_W, 2), Palette.GOLD)
		else:
			draw_rect(Rect2(x, 55, TAB_W, 1), Palette.INK_SOFT)
		var color: Color = Palette.INK if active else UiStyle.text_on_light(true)
		PixelFont.draw_centered(self, tr(tabs[i]["label"]), x + TAB_W / 2.0, 44 if active else 46, color)


func _entry_name(e: Dictionary) -> String:
	return e["name"] if e.has("name") else tr(e["name_key"])


func _draw_left(e: Dictionary, known: bool) -> void:
	var title: String = _entry_name(e) if known else tr(&"CODEX_UNKNOWN")
	var scale: int = 2 if PixelFont.normalize(title).length() <= NAME_MAX_BIG else 1
	PixelFont.draw_centered(self, title, LEFT_X, NAME_Y + (0 if scale == 2 else 3), Palette.INK if known else UiStyle.text_on_light(true), scale)
	UiStyle.frame(self, FRAME, Palette.INK_SOFT)
	for c: Vector2 in [FRAME.position, Vector2(FRAME.end.x, FRAME.position.y), Vector2(FRAME.position.x, FRAME.end.y), FRAME.end]:
		draw_rect(Rect2(c - Vector2(1, 1), Vector2(3, 3)), Palette.INK_SOFT)
	if e.has("name"):
		_draw_tiles(e["name"], known)
	elif known:
		_draw_sprite(e)
	else:
		_draw_blob()
	# Índice: um losango por entrada.
	var n: int = entries().size()
	var x0: float = LEFT_X - (n * PIP_STEP) / 2.0
	for i: int in n:
		var c := Vector2(x0 + i * PIP_STEP + 3, PIP_Y + 3)
		if i == index:
			if UiStyle.high():
				_diamond(c, 4, Palette.GOLD)
				_diamond(c, 3, Palette.INK)
			else:
				_diamond(c, 4, Palette.INK)
				_diamond(c, 3, Palette.GOLD)
		elif is_known(entries()[i]):
			_diamond(c, 3, Palette.INK_SOFT)
		else:
			_diamond(c, 3, Palette.INK_SOFT)
			_diamond(c, 2, Palette.PARCHMENT)
	var count: String = tr(&"CODEX_FOUND").format({"n": found_count(), "total": n})
	PixelFont.draw_centered(self, count, LEFT_X, COUNT_Y, UiStyle.text_on_light(true))


## Losango "cheio" de raio `r` (em pixels) centrado em `c`.
func _diamond(c: Vector2, r: int, color: Color) -> void:
	for dy: int in range(-r, r + 1):
		var half: int = r - absi(dy)
		draw_rect(Rect2(c.x - half, c.y + dy, half * 2 + 1, 1), color)


## Palavras e combos: a fileira de letras (LTR) da palavra; não descoberta = casas vazias com "?".
func _draw_tiles(latin: String, known: bool) -> void:
	var n: int = latin.length()
	var x0: float = FRAME.get_center().x - (n * TILE_STEP - (TILE_STEP - TILE)) / 2.0
	var y: float = FRAME.get_center().y - TILE / 2.0
	for i: int in n:
		var r := Rect2(x0 + i * TILE_STEP, y, TILE, TILE)
		draw_rect(r.grow(1), Palette.INK_SOFT)
		draw_rect(r, Palette.PARCHMENT_OLD if known else Palette.PARCHMENT)
		var glyph: String = latin[i] if known else tr(&"CODEX_UNKNOWN").left(1)
		PixelFont.draw_centered(self, glyph, r.get_center().x + 1, y + 2, Palette.INK if known else Palette.INK_SOFT)


## Inimigo (2×, pés em y=200) ou chefe (1×, cabendo na moldura): o primeiro quadro do sprite.
func _draw_sprite(e: Dictionary) -> void:
	var frames: SpriteFrames = _frames_of(e)
	if frames == null:
		_draw_blob()
		return
	var anim: StringName = frames.get_animation_names()[0]
	var tex: Texture2D = frames.get_frame_texture(anim, 0)
	if tex == null:
		_draw_blob()
		return
	var size: Vector2 = tex.get_size()
	var scale: float = 2.0 if category() == &"enemies" else minf(1.0, 120.0 / maxf(size.x, size.y))
	var s: Vector2 = (size * scale).round()
	var pos := Vector2(roundf(FRAME.get_center().x - s.x / 2.0), FRAME.end.y - 18 - s.y if category() == &"enemies" else roundf(FRAME.get_center().y - s.y / 2.0))
	draw_texture_rect(tex, Rect2(pos, s), false)


func _frames_of(e: Dictionary) -> SpriteFrames:
	var id: String = e["id"]
	var path: String = ("res://data/enemies/%s.tres" if category() == &"enemies" else "res://data/bosses/%s.tres") % id
	if id == String(Codex.CHAMPION_ID):
		path = "res://data/enemies/imp.tres"
	if not ResourceLoader.exists(path):
		return null
	var data: Resource = load(path)
	return data.get(&"sprite_frames") as SpriteFrames


## Silhueta genérica: octógono INK_SOFT 40×40 liso com contorno INK de 1 px e "?" no centro (D-076).
func _draw_blob() -> void:
	var c: Vector2 = FRAME.get_center()
	for dy: int in range(-21, 21):
		var cut: int = maxi(0, absi(dy) - 12)
		draw_rect(Rect2(c.x - 21 + cut, c.y + dy, 42 - cut * 2, 1), Palette.INK)
	for dy: int in range(-20, 20):
		var cut: int = maxi(0, absi(dy) - 12)
		draw_rect(Rect2(c.x - 20 + cut, c.y + dy, 40 - cut * 2, 1), Palette.INK_SOFT)
	PixelFont.draw_centered(self, tr(&"CODEX_UNKNOWN").left(1), c.x, c.y - 6, Palette.PARCHMENT_OLD, 2)


func _draw_right(e: Dictionary, known: bool) -> void:
	if e.has("meaning"):
		var meaning: String = tr(e["meaning"]) if known else tr(&"CODEX_UNKNOWN")
		PixelFont.draw_centered(self, meaning, RIGHT_X, MEANING_Y, UiStyle.text_on_light(true), 2)
	else:
		var kind: StringName = &"CODEX_KIND_BOSS" if category() == &"bosses" else (&"CODEX_KIND_CHAMPION" if e["id"] == String(Codex.CHAMPION_ID) else &"CODEX_KIND_ENEMY")
		PixelFont.draw_centered(self, tr(kind), RIGHT_X, KIND_Y, UiStyle.text_on_light(true))
	draw_rect(Rect2(LORE_X, RULE_Y, 248, 1), Palette.PARCHMENT_OLD)
	_diamond(Vector2(RIGHT_X, RULE_Y), 1, Palette.INK_SOFT)
	if known:
		var text: String = tr(e["lore"]) if e["lore"] != "" else tr(&"CODEX_NO_LORE")
		var lines: PackedStringArray = wrap_words(PixelFont.normalize(text), LORE_CHARS)
		var n: int = mini(lines.size(), LORE_LINES)
		var top: float = _lore_top(n)
		for i: int in n:
			# Cada linha centrada na página (o verbete é curto, como uma inscrição).
			PixelFont.draw_centered(self, lines[i], RIGHT_X, top + i * LORE_STEP, Palette.INK if e["lore"] != "" else UiStyle.text_on_light(true))
	else:
		# Texto ilegível: blocos lisos de 2 px em segmentos (D-076: sem xadrez).
		var widths: Array[int] = [30, 18, 24, 12, 26, 20, 16, 28, 14, 22]
		var top: float = _lore_top(3)
		for i: int in 3:
			var span: float = 240 - i * 40
			var x: float = RIGHT_X - span / 2.0
			var k: int = i * 3
			while x < RIGHT_X + span / 2.0:
				var w: float = minf(widths[k % widths.size()], RIGHT_X + span / 2.0 - x)
				draw_rect(Rect2(x, top + 2 + i * LORE_STEP, w, 2), Palette.INK_SOFT)
				x += w + 4
				k += 1
	PixelFont.draw_centered(self, tr(&"CODEX_FOLIO").format({"n": index + 1}), RIGHT_X, FOLIO_Y, UiStyle.text_on_light(true))


## Topo do bloco de `n` linhas de verbete, centrado entre o fio e o fólio.
func _lore_top(n: int) -> float:
	var h: float = n * LORE_STEP
	return roundf((RULE_Y + FOLIO_Y) / 2.0 - h / 2.0)


## Virada de página: a folha gira sobre a lombada (8 quadros; largura = 280·|1−2t|).
func _draw_flip() -> void:
	var q: int = clampi(FLIP_FRAMES - int(ceilf(_flip_left / FLIP_FRAME)) + 1, 1, FLIP_FRAMES)
	var t: float = float(q) / FLIP_FRAMES
	var w: float = maxf(2.0, roundf(PAGE_W * absf(1.0 - 2.0 * t)))
	var spine_x: float = SPINE.get_center().x
	var first_half: bool = q <= 4
	# Para frente: começa sobre a página direita e termina sobre a esquerda.
	var on_right: bool = first_half == (_flip_dir > 0)
	var x: float = spine_x if on_right else spine_x - w
	var bulge: float = 4.0 if q == 4 else (2.0 if q >= 2 and q <= 6 else 0.0)
	var sheet := Rect2(x, BOOK.position.y - bulge, w, BOOK.size.y + bulge * 2)
	if q == 4:
		draw_rect(Rect2(spine_x - 1, sheet.position.y, 2, sheet.size.y), Palette.INK_SOFT)
		return
	draw_rect(sheet, Palette.PARCHMENT_OLD if first_half else Palette.PARCHMENT)
	var edge_x: float = sheet.end.x - 1 if on_right else sheet.position.x
	draw_rect(Rect2(edge_x, sheet.position.y, 1, sheet.size.y), Palette.INK_SOFT)
	if q >= 2 and q <= 6:
		var shadow_x: float = sheet.end.x if on_right else sheet.position.x - 4
		var solid_x: float = shadow_x if on_right else shadow_x + 2
		draw_rect(Rect2(solid_x, BOOK.position.y, 2, BOOK.size.y), Palette.INK_SOFT)
