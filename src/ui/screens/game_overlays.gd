class_name GameOverlays
extends CanvasLayer
## Pausa, Game Over e Vitória dentro da partida (007 FR-704–FR-706, T712; fichas 29) — substituem
## os overlays mínimos da 001. Tudo desenhado em código; escurecimento por dithering INK.
## - Pausa (Esc): a árvore para na hora; a fita desenrola em 5 quadros @50 ms. Continuar · Grimório ·
##   Opções · Abandonar (volta ao Menu). Grimório e Opções abrem por cima (embutidos) e voltam à Pausa.
## - Game Over: "a página ardeu", estatísticas da partida e os botões 3,5 s depois da morte (uma
##   tecla adianta depois de 400 ms). Tentar de novo · Menu.
## - Vitória: estatísticas + tempo do chefe, entradas novas do Grimório (uma a cada 400 ms; uma tecla
##   mostra todas), o Cap. 2 selado. Continuar → Menu.
## R (restart) reinicia da pausa e do Game Over. Fora do roteador (cena solta), "Menu" reinicia.

signal restart_requested()

const GAME_OVER_DELAY := 0.6
const BUTTONS_AT := 3.5
const SKIP_AFTER := 0.4
const ROLL_FRAMES := 5
const ROLL_FRAME := 0.05
const ENTRY_EVERY := 0.4
const MAX_ENTRIES := 6
const SCROLL := Rect2(232, 96, 176, 104)
const ROLL_H := 12
const PAUSE_TITLE_Y := 64
const PAUSE_MENU_TOP := 118
const BURNT := Rect2(200, 110, 240, 120)
const STAT_STEP := 14
const GO_TITLE_Y := 72
const GO_BUTTONS_Y := 260
const GO_BUTTON_X: Array[int] = [248, 392]
## Fitas lado a lado mais curtas que as 128 px da ficha, para os rabos não se tocarem.
const GO_BUTTON_W := 112
const VIC_TITLE_Y := 40
const VIC_STATS := Rect2(40, 80, 220, 100)
const VIC_ENTRIES := Vector2(360, 80)
const VIC_SEAL := Rect2(292, 196, 56, 72)
const VIC_BUTTON_Y := 300
const CHAPTERS_PATH := "res://data/ui/chapters.json"
const SUBSCREENS: Dictionary = {
	&"codex": "res://src/ui/screens/codex_screen.tscn",
	&"options": "res://src/ui/screens/options_screen.tscn",
}

enum Mode { NONE, PAUSED, GAME_OVER, VICTORY }

var mode: Mode = Mode.NONE
var menu := MenuList.new()
## Tempo desde que o modo atual abriu (sem escala; corre com a árvore pausada).
var age: float = 0.0
var buttons_shown: bool = false

var _canvas: Node2D
## Grimório ou Opções abertos por cima da Pausa.
var subscreen: UiScreen = null
var _death_left: float = -1.0
## Selos da Graça abertos (016): a pausa é deles também.
var _seals_open: bool = false
var _pause_menu_open: bool = false
var _record: Dictionary = {}
var _entries: Array[String] = []
var _entries_all: bool = false
## Numeral do próximo capítulo (selado) na Vitória, de `data/ui/chapters.json`.
var _next_numeral: String = ""


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Node2D.new()
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)
	menu.chosen.connect(_on_chosen)
	menu.back.connect(_on_back)
	EventBus.player_died.connect(func() -> void: _death_left = GAME_OVER_DELAY)
	EventBus.seals_shown.connect(func(_b: Array[BlessingData], _l: int) -> void: _seals_open = true)
	EventBus.seals_hidden.connect(func() -> void: _seals_open = false)
	var chapters: Array = UiScreen.read_json(CHAPTERS_PATH).get("chapters", [])
	if chapters.size() > 1:
		_next_numeral = chapters[1]["numeral"]


func _process(delta: float) -> void:
	var real: float = delta / maxf(Engine.time_scale, 0.001)
	if _death_left > 0.0:
		_death_left -= real
		if _death_left <= 0.0:
			_set_mode(Mode.GAME_OVER)
	if mode == Mode.NONE:
		return
	age += real
	if not buttons_shown and mode != Mode.PAUSED and age >= _buttons_at():
		_show_buttons()
	_canvas.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if subscreen != null:
		return
	if event is InputEventMouse:
		if mode != Mode.NONE and _mouse_input(_canvas.make_input_local(event) as InputEventMouse):
			get_viewport().set_input_as_handled()
			UiScreen.ui_sound(event)
		return
	if not event.is_pressed() or event.is_echo():
		return
	var handled: bool = true
	if mode == Mode.NONE:
		handled = event.is_action(&"pause")
		if handled:
			toggle_pause()
	elif event.is_action(&"restart") and mode in [Mode.PAUSED, Mode.GAME_OVER]:
		restart()
	elif mode == Mode.PAUSED:
		handled = menu.handle_input(event)
	elif not buttons_shown:
		if age >= SKIP_AFTER:
			_show_buttons()
	elif mode == Mode.GAME_OVER:
		handled = _row_input(event)
	else:
		handled = menu.handle_input(event)
	if handled:
		get_viewport().set_input_as_handled()
		if not event.is_action(&"pause"):  # pausar já tem o próprio som
			UiScreen.ui_sound(event)


func toggle_pause() -> void:
	if mode == Mode.NONE:
		_set_mode(Mode.PAUSED)
	elif mode == Mode.PAUSED:
		_set_mode(Mode.NONE)


func show_victory() -> void:
	if mode != Mode.GAME_OVER:
		_set_mode(Mode.VICTORY)


func restart() -> void:
	get_tree().paused = false
	TimeScale.reset()
	restart_requested.emit()


func _to_menu() -> void:
	if get_parent() != null and get_parent().has_meta(&"app"):
		get_tree().paused = false
		TimeScale.reset()
		EventBus.screen_requested.emit(&"menu")
	else:
		restart()


func _set_mode(m: Mode) -> void:
	mode = m
	age = 0.0
	buttons_shown = false
	_entries_all = false
	menu = MenuList.new()
	menu.chosen.connect(_on_chosen)
	menu.back.connect(_on_back)
	# Os selos da Graça (016) seguram a pausa: sair da Pausa por cima deles não despausa o jogo.
	get_tree().paused = m != Mode.NONE or _seals_open
	var paused_menu: bool = m == Mode.PAUSED
	if paused_menu != _pause_menu_open:
		_pause_menu_open = paused_menu
		EventBus.pause_menu_toggled.emit(paused_menu)
	match m:
		Mode.PAUSED:
			menu.add(&"resume", "PAUSE_RESUME")
			menu.add(&"codex", "MENU_CODEX")
			menu.add(&"options", "MENU_OPTIONS")
			menu.add(&"abandon", "PAUSE_ABANDON")
		Mode.GAME_OVER:
			_record = GameState.run_record()
			menu.add(&"retry", "GAMEOVER_RETRY")
			menu.add(&"menu", "GAMEOVER_MENU")
		Mode.VICTORY:
			_record = GameState.run_record()
			_entries.clear()
			var codex: Node = get_node_or_null(^"/root/Codex")
			if codex != null:
				for e: Array in codex.new_this_run():
					_entries.append(_entry_label(e[0], e[1]))
			for cid: String in Progress.new_this_run():  # 010: o escriba liberado nesta partida
				_entries.insert(0, tr(&"CHAR_UNLOCKED_LINE").format({"name": Progress.ROSTER.by_id(StringName(cid)).display_name}))
			menu.add(&"menu", "VICTORY_CONTINUE")
	_canvas.queue_redraw()


## Nome de uma entrada nova: o latim das palavras e combos não traduz; inimigos e chefes, sim.
func _entry_label(category: StringName, id: StringName) -> String:
	match category:
		&"enemies":
			return tr("ENEMY_" + String(id).to_upper())
		&"bosses":
			return tr("BOSS_" + String(id).to_upper())
	return String(id).to_upper()


func _buttons_at() -> float:
	return BUTTONS_AT - GAME_OVER_DELAY if mode == Mode.GAME_OVER else BUTTONS_AT


func _show_buttons() -> void:
	buttons_shown = true
	_entries_all = true


## Mouse (D-084): as fitas registram a área ao desenhar; antes dos botões, um clique os mostra.
func _mouse_input(m: InputEventMouse) -> bool:
	var b := m as InputEventMouseButton
	if b != null and b.pressed and not buttons_shown and mode != Mode.PAUSED:
		if age >= SKIP_AFTER:
			_show_buttons()
		return true
	return menu.handle_input(m)


## Game Over: dois botões lado a lado (←/→ e ↑/↓ trocam).
func _row_input(event: InputEvent) -> bool:
	if event.is_action(&"move_left") or event.is_action(&"move_right"):
		menu.focus = 1 - menu.focus
		return true
	return menu.handle_input(event)


func _on_chosen(id: StringName) -> void:
	match id:
		&"resume":
			_set_mode(Mode.NONE)
		&"codex", &"options":
			open_subscreen(id)
		&"abandon", &"menu":
			_to_menu()
		&"retry":
			restart()


## Abre o Grimório ou as Opções por cima da Pausa; ao fechar, a Pausa volta.
func open_subscreen(id: StringName) -> void:
	var scene: PackedScene = load(SUBSCREENS[id])
	subscreen = scene.instantiate()
	subscreen.embedded = true
	subscreen.process_mode = Node.PROCESS_MODE_ALWAYS
	subscreen.closed.connect(close_subscreen)
	add_child(subscreen)
	_canvas.visible = false


func close_subscreen() -> void:
	if subscreen == null:
		return
	subscreen.queue_free()
	subscreen = null
	_canvas.visible = true


func _on_back() -> void:
	if mode == Mode.PAUSED:
		_set_mode(Mode.NONE)


func _on_draw() -> void:
	match mode:
		Mode.PAUSED:
			_draw_pause()
		Mode.GAME_OVER:
			_draw_game_over()
		Mode.VICTORY:
			_draw_victory()


func _draw_dim() -> void:
	UiStyle.dim_screen(_canvas, UiStyle.dim_level())


func _draw_pause() -> void:
	_draw_dim()
	_draw_plate_text(tr(&"PAUSE_TITLE"), PAUSE_TITLE_Y, Palette.CHALK, 2)
	var t: float = clampf(ceilf(age / ROLL_FRAME) / ROLL_FRAMES, 0.2, 1.0)
	var h: float = roundf(SCROLL.size.y * t)
	var paper := Rect2(SCROLL.position.x + 8, SCROLL.position.y, SCROLL.size.x - 16, h)
	_canvas.draw_rect(paper, Palette.PARCHMENT)
	_draw_roll(SCROLL.position.y - ROLL_H / 2.0)
	_draw_roll(SCROLL.position.y + h - ROLL_H / 2.0)
	if t < 1.0:
		return
	_draw_menu_column(320, PAUSE_MENU_TOP)
	_draw_plate_text(tr(&"PAUSE_HINT").format({"pause": Settings.key_label(&"pause"), "restart": Settings.key_label(&"restart")}), 300, Palette.CHALK)


## Texto centrado sobre uma faixa lisa (legível por cima do jogo escurecido).
func _draw_plate_text(text: String, y: float, color: Color, scale: int = 1, plate: Color = Palette.INK) -> void:
	var w: float = PixelFont.width(text, scale) + 12
	var h: float = PixelFont.height(scale) + 6
	_canvas.draw_rect(Rect2(320 - w / 2.0, y - 3, w, h), plate)
	PixelFont.draw_centered(_canvas, text, 320, y, color, scale)


func _draw_roll(y: float) -> void:
	_canvas.draw_rect(Rect2(SCROLL.position.x, y, SCROLL.size.x, ROLL_H), Palette.PARCHMENT_OLD)
	_canvas.draw_rect(Rect2(SCROLL.position.x, y + ROLL_H - 2, SCROLL.size.x, 2), Palette.INK_SOFT)
	_canvas.draw_rect(Rect2(SCROLL.position.x - 4, y + 2, 4, ROLL_H - 4), Palette.GOLD)
	_canvas.draw_rect(Rect2(SCROLL.end.x, y + 2, 4, ROLL_H - 4), Palette.GOLD)


func _draw_menu_column(center_x: float, top: float) -> void:
	for i: int in menu.items.size():
		var it: Dictionary = menu.items[i]
		var state: StringName = &"focus" if i == menu.focus else (&"idle" if it["enabled"] else &"disabled")
		UiStyle.draw_ribbon(_canvas, Vector2(center_x, top + i * 22), tr(it["label"]), state)
		menu.set_rect(i, UiStyle.ribbon_rect(Vector2(center_x, top + i * 22), tr(it["label"])))


func _stat_lines(with_boss: bool) -> Array[Array]:
	var secs: int = int(_record.get("time", 0.0))
	var out: Array[Array] = [
		[tr(&"STAT_WAVE"), str(_record.get("wave", 0))],
		[tr(&"STAT_TIME"), "%d:%02d" % [secs / 60, secs % 60]],
		[tr(&"STAT_WORDS"), str(_record.get("words", 0))],
		[tr(&"STAT_KILLS"), str(_record.get("kills", 0))],
		[tr(&"STAT_INK"), str(_record.get("ink", 0))],
	]
	if with_boss:
		var b: int = int(_record.get("boss_time", 0.0))
		out.append([tr(&"STAT_BOSS_TIME"), "%d:%02d" % [b / 60, b % 60]])
	return out


func _draw_stats(box: Rect2, with_boss: bool) -> void:
	var y: float = box.position.y + 12
	for line: Array in _stat_lines(with_boss):
		PixelFont.draw(_canvas, line[0], Vector2(box.position.x + 12, y), UiStyle.text_on_light(true))
		var value: String = line[1]
		PixelFont.draw(_canvas, value, Vector2(box.end.x - 12 - PixelFont.width(value), y), Palette.INK)
		y += STAT_STEP


func _draw_game_over() -> void:
	UiStyle.dim_screen(_canvas, 0.75)
	_draw_plate_text(tr(&"GAMEOVER_TITLE"), GO_TITLE_Y, Palette.BLOOD if not UiStyle.high() else Palette.CHALK, 2, Palette.PARCHMENT)
	_canvas.draw_rect(BURNT, Palette.PARCHMENT)
	# Borda queimada: dentes BLOOD_DARK/INK irregulares.
	for x: int in range(int(BURNT.position.x), int(BURNT.end.x), 4):
		var d: int = 2 + (x * 7) % 5
		_canvas.draw_rect(Rect2(x, BURNT.position.y, 4, d), Palette.BLOOD_DARK)
		_canvas.draw_rect(Rect2(x, BURNT.end.y - d, 4, d), Palette.INK)
	_draw_stats(BURNT.grow_individual(0, 4, 0, 0), false)
	if not buttons_shown:
		return
	for i: int in menu.items.size():
		var state: StringName = &"focus" if i == menu.focus else &"idle"
		UiStyle.draw_ribbon(_canvas, Vector2(GO_BUTTON_X[i], GO_BUTTONS_Y), tr(menu.items[i]["label"]), state, GO_BUTTON_W)
		menu.set_rect(i, UiStyle.ribbon_rect(Vector2(GO_BUTTON_X[i], GO_BUTTONS_Y), tr(menu.items[i]["label"]), GO_BUTTON_W))
	_draw_plate_text(tr(&"GAMEOVER_HINT").format({"restart": Settings.key_label(&"restart")}), 300, Palette.CHALK)
	# 010: liberou um escriba mesmo perdendo (as heresias contam na partida perdida).
	var freed: PackedStringArray = Progress.new_this_run()
	if not freed.is_empty():
		_draw_plate_text(tr(&"CHAR_UNLOCKED_LINE").format({"name": Progress.ROSTER.by_id(StringName(freed[0])).display_name}), 316, Palette.GOLD_LIGHT)


func _draw_victory() -> void:
	_canvas.draw_rect(Rect2(0, 0, 640, 360), Palette.PARCHMENT)
	if not UiStyle.high():
		for i: int in 8:
			var a: float = TAU * i / 8.0 + age * 0.1
			for r: int in range(40, 380, 6):
				var p := (Vector2(320, 180) + Vector2.from_angle(a) * r).round()
				_canvas.draw_rect(Rect2(p, Vector2(2, 2)), Palette.GOLD_LIGHT)
	PixelFont.draw_centered(_canvas, tr(&"VICTORY_TITLE"), 320, VIC_TITLE_Y, Palette.GOLD if not UiStyle.high() else Palette.INK, 2)
	_canvas.draw_rect(VIC_STATS.grow(1), Palette.GOLD)
	_canvas.draw_rect(VIC_STATS, Palette.PARCHMENT)
	_draw_stats(VIC_STATS, true)
	PixelFont.draw(_canvas, tr(&"VICTORY_NEW_ENTRIES"), VIC_ENTRIES, Palette.INK)
	var shown: int = _entries.size() if _entries_all else mini(_entries.size(), int(age / ENTRY_EVERY))
	for i: int in mini(shown, MAX_ENTRIES):
		PixelFont.draw(_canvas, _entries[i], VIC_ENTRIES + Vector2(8, 14 + i * 12), Palette.INK)
	if shown > MAX_ENTRIES:
		PixelFont.draw(_canvas, tr(&"MORE_COUNT").format({"n": shown - MAX_ENTRIES}), VIC_ENTRIES + Vector2(8, 14 + MAX_ENTRIES * 12), UiStyle.text_on_light(true))
	if _entries.is_empty():
		PixelFont.draw(_canvas, tr(&"VICTORY_NO_ENTRIES"), VIC_ENTRIES + Vector2(8, 14), UiStyle.text_on_light(true))
	# Cap. 2 selado: página acorrentada com selo BLOOD.
	_canvas.draw_rect(VIC_SEAL, Palette.PARCHMENT_OLD)
	PixelFont.draw_centered(_canvas, _next_numeral, VIC_SEAL.get_center().x, VIC_SEAL.position.y + 10, Palette.INK, 2)
	_canvas.draw_rect(Rect2(VIC_SEAL.position.x, VIC_SEAL.get_center().y - 1, VIC_SEAL.size.x, 3), Palette.INK_SOFT)
	UiStyle.disc(_canvas, VIC_SEAL.get_center() + Vector2(0, 12), 8, Palette.INK)
	UiStyle.disc(_canvas, VIC_SEAL.get_center() + Vector2(0, 12), 7, Palette.BLOOD)
	PixelFont.draw_centered(_canvas, tr(&"COMING_SOON"), VIC_SEAL.get_center().x, VIC_SEAL.end.y + 6, UiStyle.text_on_light(true))
	if buttons_shown:
		UiStyle.draw_ribbon(_canvas, Vector2(320, VIC_BUTTON_Y), tr(menu.items[0]["label"]), &"focus")
		menu.set_rect(0, UiStyle.ribbon_rect(Vector2(320, VIC_BUTTON_Y), tr(menu.items[0]["label"])))
