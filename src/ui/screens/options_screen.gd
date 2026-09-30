extends UiScreen
## Opções (007 FR-707, FR-708, T720; D-066, D-067; ficha 30, layout do design-agent). ↑/↓ escolhem a
## linha; ←/→ mudam o valor; Espaço/Enter ativa; Esc volta. Cada mudança vale na hora e fica salva
## (Settings.commit). As fitas Restaurar · Voltar ficam lado a lado (←/→ alternam); Restaurar pede
## confirmação. Remapear abre a lista das ações: escolher uma espera a próxima tecla (Esc cancela);
## se a tecla já era de outra ação, as duas trocam e aparece o aviso. Abre do Menu ou por cima da
## Pausa (embedded).

const ROWS: Array[StringName] = [
	&"vol_master", &"vol_music", &"vol_sfx", &"shake", &"language", &"aim", &"contrast",
	&"keys", &"reset", &"back",
]
## Linhas da lista (as duas últimas de ROWS são as fitas).
const LIST_ROWS := 8
const LABELS: Dictionary = {
	&"vol_master": "OPT_VOL_MASTER", &"vol_music": "OPT_VOL_MUSIC", &"vol_sfx": "OPT_VOL_SFX",
	&"shake": "OPT_SHAKE", &"language": "OPT_LANGUAGE", &"aim": "OPT_AIM_MOUSE",
	&"contrast": "OPT_HIGH_CONTRAST", &"keys": "OPT_KEYS", &"reset": "OPT_RESET", &"back": "OPT_BACK",
}
const BUS_OF: Dictionary = {&"vol_master": &"Master", &"vol_music": &"Music", &"vol_sfx": &"SFX"}
const TOGGLES: Array[StringName] = [&"shake", &"aim", &"contrast"]
const VOLUME_STEP := 0.1
const SWAP_NOTICE := 2.0
const WAX_FRAME := 0.05
const STEP_FLASH := 0.05
const BLINK := 0.4
# Layout (design-agent).
const PANEL := Rect2(104, 44, 432, 264)
const TITLE_Y := 16
const ROW_Y0 := 60
const ROW_STEP := 24
const ROW_X := 124
const ROW_W := 392
const ROW_H := 16
const LABEL_X := 140
const VALUE_X := 304
const VALUE_END := 504
const SEPARATE_AFTER: Array[int] = [2, 6]
const BUTTONS_Y := 284
const BUTTON_X: Array[int] = [248, 392]
const BUTTON_W := 112
const HINT_Y := 324
## Subpágina de teclas: 17 linhas desde a 017 (+ armas 1 e 2; antes 15, design-agent T1600).
const KEY_Y0 := 54
const KEY_STEP := 13
const KEY_ROW_H := 11
const KEY_SUBTITLE_Y := 45
const KEY_BACK := Vector2(320, 298)
const NOTICE := Rect2(124, 276, 392, 12)
const SLIDER_W := 101
const LANG_X: Array[int] = [310, 358]

var rows: Array[StringName] = ROWS.duplicate()
var focus: int = 0
var in_keys: bool = false
var key_focus: int = 0
var waiting_key: bool = false
## Ações que receberam a tecla antiga na última troca (aviso na tela por SWAP_NOTICE s). Pode ser
## mais de uma: Reiniciar e Loja: trocar dividem o R de fábrica (contextos diferentes).
var swapped_with: Array[StringName] = []
var confirm_reset: bool = false

var _swap_left: float = 0.0
## Selo de cera animando: linha → [tempo desde a troca, ligou?].
var _wax: Dictionary = {}
var _step_left: float = 0.0
var _step_dir: int = 0


func focused_row() -> StringName:
	return rows[focus]


func _process(delta: float) -> void:
	super(delta)
	_swap_left = maxf(_swap_left - delta, 0.0)
	_step_left = maxf(_step_left - delta, 0.0)
	for row: StringName in _wax.keys():
		_wax[row][0] += delta


func handle_input(event: InputEvent) -> bool:
	if waiting_key:
		return _capture_key(event)
	if event is InputEventMouse:
		return _mouse_input(local(event) as InputEventMouse)
	if not event.is_pressed() or event.is_echo():
		return false
	if in_keys:
		return _keys_input(event)
	var on_buttons: bool = focus >= LIST_ROWS
	if event.is_action(&"move_down"):
		focus = 0 if on_buttons else focus + 1
		confirm_reset = false
	elif event.is_action(&"move_up"):
		if on_buttons:
			focus = LIST_ROWS - 1
		else:
			focus = LIST_ROWS if focus == 0 else focus - 1
		confirm_reset = false
	elif event.is_action(&"move_right") or event.is_action(&"move_left"):
		if on_buttons:
			focus = LIST_ROWS + (1 - (focus - LIST_ROWS))
			confirm_reset = false
		else:
			_change(1 if event.is_action(&"move_right") else -1)
	elif is_confirm(event):
		_activate()
	elif is_back(event):
		leave()
	else:
		return false
	return true


## Mouse (D-084): passar por cima foca a linha/botão; o clique faz o que o Confirmar faria (volume:
## vai para o ponto clicado na barra; sim/não e idioma alternam); clique direito volta.
func _mouse_input(m: InputEventMouse) -> bool:
	var b := m as InputEventMouseButton
	if b != null and not b.pressed:
		return false
	if b != null and b.button_index == MOUSE_BUTTON_RIGHT:
		if in_keys:
			in_keys = false
		else:
			leave()
		return true
	var click: bool = b != null and b.button_index == MOUSE_BUTTON_LEFT
	if b != null and not click:
		return false
	var p: Vector2 = m.position
	if in_keys:
		if UiStyle.ribbon_rect(KEY_BACK, tr(&"OPT_BACK"), BUTTON_W).has_point(p):
			if click:
				in_keys = false
			return click
		for i: int in Settings.REBINDABLE.size():
			if Rect2(ROW_X, KEY_Y0 + i * KEY_STEP, ROW_W, KEY_ROW_H).has_point(p):
				key_focus = i
				if click:
					waiting_key = true
					swapped_with.clear()
				return click
		return false
	var hit: int = -1
	for i: int in LIST_ROWS:
		if Rect2(ROW_X, ROW_Y0 + i * ROW_STEP, ROW_W, ROW_H).has_point(p):
			hit = i
	for k: int in 2:
		var idx: int = LIST_ROWS + k
		if UiStyle.ribbon_rect(Vector2(BUTTON_X[k], BUTTONS_Y), tr(LABELS[rows[idx]]), BUTTON_W).has_point(p):
			hit = idx
	if hit < 0:
		return false
	if hit != focus:
		focus = hit
		confirm_reset = false
	if not click:
		return false
	var row: StringName = focused_row()
	if BUS_OF.has(row):
		if p.x >= VALUE_X - 4 and p.x <= VALUE_X + SLIDER_W + 4:
			Settings.set_volume(BUS_OF[row], clampf(roundf((p.x - VALUE_X) / 10.0) / 10.0, 0.0, 1.0))
			Settings.commit()
	elif row in TOGGLES or row == &"language":
		_toggle(row)
	else:
		_activate()
	return true


## ←/→ numa linha: volume ±10%; sim/não e idioma alternam.
func _change(dir: int) -> void:
	var row: StringName = focused_row()
	if BUS_OF.has(row):
		var bus: StringName = BUS_OF[row]
		var before: float = Settings.volume(bus)
		Settings.set_volume(bus, snappedf(before + dir * VOLUME_STEP, VOLUME_STEP))
		if not is_equal_approx(before, Settings.volume(bus)):
			_step_left = STEP_FLASH
			_step_dir = dir
		Settings.commit()
	elif row in TOGGLES or row == &"language":
		_toggle(row)


func _activate() -> void:
	var row: StringName = focused_row()
	match row:
		&"shake", &"aim", &"contrast", &"language":
			_toggle(row)
		&"keys":
			in_keys = true
			key_focus = 0
		&"reset":
			if confirm_reset:
				Settings.reset_defaults()
				Settings.commit()
				confirm_reset = false
			else:
				confirm_reset = true
		&"back":
			leave()


func _toggle(row: StringName) -> void:
	match row:
		&"shake":
			Settings.shake_enabled = not Settings.shake_enabled
		&"aim":
			Settings.aim_with_mouse = not Settings.aim_with_mouse
		&"contrast":
			Settings.high_contrast = not Settings.high_contrast
		&"language":
			var langs: PackedStringArray = Settings.LANGUAGES
			Settings.language = langs[(langs.find(Settings.language) + 1) % langs.size()]
	if row in TOGGLES:
		_wax[row] = [0.0, _toggle_on(row)]
	Settings.commit()


func _toggle_on(row: StringName) -> bool:
	match row:
		&"shake":
			return Settings.shake_enabled
		&"aim":
			return Settings.aim_with_mouse
	return Settings.high_contrast


func _keys_input(event: InputEvent) -> bool:
	var count: int = Settings.REBINDABLE.size()
	if event.is_action(&"move_down"):
		key_focus = (key_focus + 1) % count
	elif event.is_action(&"move_up"):
		key_focus = (key_focus - 1 + count) % count
	elif is_confirm(event):
		waiting_key = true
		swapped_with.clear()
	elif is_back(event):
		in_keys = false
	else:
		return false
	return true


## Esperando tecla: a próxima tecla vira a da ação; Esc cancela (e não é remapeável).
func _capture_key(event: InputEvent) -> bool:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
		waiting_key = false  # clique direito cancela, como o Esc
		return true
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return true
	var key: InputEventKey = event
	var code: int = key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	waiting_key = false
	if code == KEY_ESCAPE:
		return true
	var action: StringName = Settings.REBINDABLE[key_focus]
	swapped_with.clear()
	swapped_with.append_array(Settings.conflicts(action, code))  # só no mesmo contexto (017)
	Settings.set_binding(action, code)
	Settings.commit()
	_swap_left = SWAP_NOTICE if not swapped_with.is_empty() else 0.0
	return true


func action_label(action: StringName) -> String:
	return tr("ACTION_" + String(action).to_upper())


# --- Desenho ---------------------------------------------------------------------------------

func _draw() -> void:
	if embedded:
		UiStyle.dim_screen(self, UiStyle.dim_level())
	else:
		draw_rect(Rect2(0, 0, 640, 360), Palette.INK)
	_plate_title(tr(&"OPTIONS_TITLE"))
	UiStyle.draw_panel(self, PANEL)
	if in_keys:
		_draw_keys()
	else:
		_draw_rows()
	var hint: String = tr(&"OPT_HINT").format({
		"prev": Settings.key_label(&"move_left"), "next": Settings.key_label(&"move_right"),
		"up": Settings.key_label(&"move_up"), "down": Settings.key_label(&"move_down"),
		"back": Settings.key_label(&"pause")})
	if embedded:
		var hw: float = PixelFont.width(hint) + 12
		draw_rect(Rect2(320 - hw / 2.0, HINT_Y - 3, hw, PixelFont.height() + 6), Palette.INK)
	PixelFont.draw_centered(self, hint, 320, HINT_Y, UiStyle.text_on_dark(true))


func _plate_title(text: String) -> void:
	if embedded:
		var w: float = PixelFont.width(text, 2) + 12
		draw_rect(Rect2(320 - w / 2.0, TITLE_Y - 3, w, PixelFont.height(2) + 6), Palette.INK)
	PixelFont.draw_centered(self, text, 320, TITLE_Y, UiStyle.text_on_dark(), 2)


func _draw_focus_band(y: float, h: float = ROW_H) -> void:
	var band := Rect2(ROW_X, y, ROW_W, h)
	if UiStyle.high():
		# Nas linhas baixas das teclas, grow(3) invadiria a vizinha.
		draw_rect(band.grow(3 if h >= ROW_H else 2), Palette.INK)
		draw_rect(band.grow(1), Palette.GOLD)
	else:
		draw_rect(band.grow(1), Palette.GOLD)
	draw_rect(band, Palette.PARCHMENT_OLD)
	var bob: float = -1.0 if int(age / BLINK) % 2 == 0 else 0.0
	UiStyle.draw_quill(self, Vector2(ROW_X - 4, y + h / 2.0 + bob), true)


func _draw_rows() -> void:
	for i: int in LIST_ROWS:
		var row: StringName = rows[i]
		var y: float = ROW_Y0 + i * ROW_STEP
		var focused: bool = i == focus
		if focused:
			_draw_focus_band(y)
		var shift: float = UiStyle.RIBBON_FOCUS_SHIFT if focused else 0.0
		var color: Color = Palette.INK if focused else UiStyle.text_on_light(true)
		PixelFont.draw(self, tr(LABELS[row]), Vector2(LABEL_X + shift, y + 5), color)
		if BUS_OF.has(row):
			_draw_slider(y, Settings.volume(BUS_OF[row]), focused)
		elif row in TOGGLES:
			_draw_wax(y, row)
		elif row == &"language":
			_draw_language(y, focused)
		elif row == &"keys":
			PixelFont.draw(self, tr(&"UI_NEXT"), Vector2(VALUE_END - 6, y + 5), color)
		if i in SEPARATE_AFTER:
			draw_rect(Rect2(ROW_X, y + 20, ROW_W, 1), Palette.PARCHMENT_OLD)
	for b: int in 2:
		var idx: int = LIST_ROWS + b
		var label: String = tr(LABELS[rows[idx]])
		if rows[idx] == &"reset" and confirm_reset:
			label = tr(&"OPT_CONFIRM")
		UiStyle.draw_ribbon(self, Vector2(BUTTON_X[b], BUTTONS_Y), label, &"focus" if focus == idx else &"idle", BUTTON_W)


## Slider de volume (6 estados da ficha 30: repouso, foco, passo ←, passo →, 0%, 100%).
func _draw_slider(y: float, v: float, focused: bool) -> void:
	var steps: int = roundi(v * 10.0)
	var x_v: float = VALUE_X + 10 * steps
	var track := Rect2(VALUE_X, y + 6, SLIDER_W, 4)
	draw_rect(track.grow(1), Palette.INK_SOFT)
	draw_rect(track, Palette.PARCHMENT_OLD)
	var fill: Color = Palette.INK if focused or UiStyle.high() else Palette.INK_SOFT
	draw_rect(Rect2(VALUE_X, y + 6, 10 * steps, 4), fill)
	for t: int in 11:
		draw_rect(Rect2(VALUE_X + t * 10, y + 11, 1, 2), Palette.INK_SOFT)
	var flash: bool = focused and _step_left > 0.0
	var knob_x: float = x_v - (float(_step_dir) if flash else 0.0)
	if focused:
		draw_rect(Rect2(knob_x - 3, y + 2, 7, 12), Palette.INK)
		draw_rect(Rect2(knob_x - 2, y + 3, 5, 10), Palette.GOLD)
	elif steps == 0:
		draw_rect(Rect2(knob_x - 2, y + 3, 5, 10), Palette.INK)
		draw_rect(Rect2(knob_x - 1, y + 4, 3, 8), Palette.PARCHMENT)
	else:
		draw_rect(Rect2(knob_x - 2, y + 3, 5, 10), Palette.INK_SOFT)
	if focused:
		var left_c: Color = Palette.GOLD if flash and _step_dir < 0 else Palette.INK_SOFT
		var right_c: Color = Palette.GOLD if flash and _step_dir > 0 else Palette.INK_SOFT
		# No limite, a seta fica apagada em PARCHMENT_OLD liso (D-076: sem xadrez).
		PixelFont.draw(self, tr(&"UI_PREV"), Vector2(VALUE_X - 8, y + 5), Palette.PARCHMENT_OLD if steps == 0 else left_c)
		PixelFont.draw(self, tr(&"UI_NEXT"), Vector2(VALUE_X + SLIDER_W + 5, y + 5), Palette.PARCHMENT_OLD if steps == 10 else right_c)
	var pct: String = "%d%%" % (steps * 10)
	PixelFont.draw(self, pct, Vector2(448 - PixelFont.width(pct), y + 5), Palette.INK)


## Selo de cera (WaxToggle, 3 quadros @50 ms) + SIM/NÃO ao lado (a cor nunca é a única pista).
func _draw_wax(y: float, row: StringName) -> void:
	var on: bool = _toggle_on(row)
	var frame: int = 2
	if _wax.has(row) and _wax[row][0] < WAX_FRAME * 2:
		frame = 1 if _wax[row][0] < WAX_FRAME else 2
	var seal := Rect2(VALUE_X, y + 2, 12, 12)
	if frame == 1:
		draw_rect(Rect2(VALUE_X - 1, y + 3, 14, 10), Palette.INK)
	elif on:
		draw_rect(seal.grow_individual(-2, 0, -2, 0), Palette.BLOOD_DARK)
		draw_rect(seal.grow_individual(0, -2, 0, -2), Palette.BLOOD_DARK)
		var c: Vector2 = seal.get_center()
		draw_rect(Rect2(c.x - 1, c.y - 3, 2, 6), Palette.CHALK)
		draw_rect(Rect2(c.x - 3, c.y - 1, 6, 2), Palette.CHALK)
		draw_rect(Rect2(seal.position + Vector2(2, 1), Vector2.ONE), Palette.GOLD_LIGHT)
	else:
		var ring: float = UiStyle.outline_w()
		draw_rect(seal.grow_individual(-2, 0, -2, 0), Palette.INK_SOFT if not UiStyle.high() else Palette.INK)
		draw_rect(seal.grow_individual(0, -2, 0, -2), Palette.INK_SOFT if not UiStyle.high() else Palette.INK)
		draw_rect(seal.grow(-ring), Palette.PARCHMENT_OLD)
	PixelFont.draw(self, tr(&"OPT_ON") if on else tr(&"OPT_OFF"), Vector2(VALUE_X + 18, y + 5), Palette.INK)


func _draw_language(y: float, focused: bool) -> void:
	var end_x: float = 0.0
	for i: int in Settings.LANGUAGES.size():
		var tag: String = tr("LANG_TAG_" + Settings.LANGUAGES[i].to_upper())
		var x: float = LANG_X[i]
		var w: float = PixelFont.width(tag)
		var selected: bool = Settings.LANGUAGES[i] == Settings.language
		if selected:
			var plate := Rect2(x - 4, y + 2, w + 8, 12)
			draw_rect(plate.grow(1), Palette.INK)
			draw_rect(plate, Palette.PARCHMENT_OLD)
			draw_rect(Rect2(x, y + 13, w, 1), Palette.INK)
		PixelFont.draw(self, tag, Vector2(x, y + 5), Palette.INK if selected else UiStyle.text_on_light(true))
		end_x = x + w
	if focused:
		PixelFont.draw(self, tr(&"UI_PREV"), Vector2(VALUE_X - 8, y + 5), Palette.INK_SOFT)
		PixelFont.draw(self, tr(&"UI_NEXT"), Vector2(end_x + 8, y + 5), Palette.INK_SOFT)


func _draw_keys() -> void:
	PixelFont.draw_centered(self, tr(&"OPT_KEYS"), 320, KEY_SUBTITLE_Y, UiStyle.text_on_light(true))
	for i: int in Settings.REBINDABLE.size():
		var action: StringName = Settings.REBINDABLE[i]
		var y: float = KEY_Y0 + i * KEY_STEP
		var focused: bool = i == key_focus
		if focused:
			_draw_focus_band(y, KEY_ROW_H)
			if waiting_key:
				# Esperando tecla: faixa lisa com moldura GOLD de 2 px.
				UiStyle.frame(self, Rect2(ROW_X, y, ROW_W, KEY_ROW_H).grow(2), Palette.GOLD, 2.0)
				draw_rect(Rect2(ROW_X, y, ROW_W, KEY_ROW_H), Palette.PARCHMENT)
		var label: String = action_label(action)
		var shift: float = UiStyle.RIBBON_FOCUS_SHIFT if focused else 0.0
		PixelFont.draw(self, label, Vector2(LABEL_X + shift, y + 3), Palette.INK if focused else UiStyle.text_on_light(true))
		var waiting_here: bool = focused and waiting_key
		var key_text: String = tr(&"OPT_PRESS_KEY") if waiting_here else Settings.key_label(action)
		var kw: float = PixelFont.width(key_text)
		var plate := Rect2(VALUE_END - kw - 8, y + 1, kw + 8, 10)
		var edge: Color = Palette.INK_SOFT
		if (waiting_here and UiStyle.high()) or (action in swapped_with and _swap_left > SWAP_NOTICE - 0.1):
			edge = Palette.GOLD
		draw_rect(plate.grow(1), edge)
		draw_rect(plate, Palette.PARCHMENT_OLD)
		var key_color: Color = Palette.INK
		if waiting_here and not UiStyle.high() and int(age / BLINK) % 2 == 1:
			key_color = Palette.INK_SOFT
		PixelFont.draw(self, key_text, plate.position + Vector2(4, 2), key_color)
		var dots_from: float = LABEL_X + shift + PixelFont.width(label) + 6
		var dots_to: float = plate.position.x - 6
		var x: float = dots_from
		while x < dots_to:
			draw_rect(Rect2(x, y + 8, 1, 1), Palette.INK_SOFT)
			x += 3
	if _swap_left > 0.0 and not swapped_with.is_empty():
		draw_rect(NOTICE, Palette.INK)
		draw_rect(Rect2(NOTICE.position, Vector2(2, NOTICE.size.y)), Palette.GOLD)
		PixelFont.draw_centered(self, tr(&"OPT_SWAPPED").format({"action": ", ".join(swapped_with.map(action_label))}), 320, NOTICE.position.y + 3, Palette.CHALK)
	UiStyle.draw_ribbon(self, KEY_BACK, tr(&"OPT_BACK"), &"idle", BUTTON_W)
