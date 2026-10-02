class_name GraceSeals
extends CanvasLayer
## Os 3 selos do level-up (016 FR-1606..FR-1609; design-agent e animation-agent T1600). Desenhados
## em camadas por código sobre a página pausada: sombra, pergaminho, lacre, ícone, texto, contas do
## teto, etiqueta da tecla e foco. Entrada em degraus, trava visível, carimbo e saída lisa (sem xadrez
## no selo: D-076). Escolha por 1/2/3, clique, ou setas + Confirmar; quem decide se vale é o GraceFlow.

const CARD := Vector2(128, 132)
const CARD_Y := 96.0
const PITCH := 152.0
const CLICK_H := 160.0
const HOVER_LIFT := 4.0
const TEXT_W := 20
const ICON_POS := Vector2(40, 10)
## Selo de arma (D-099; design-agent): arma, "agora → próximo" e o nível.
const SUBTITLE_Y := 72.0
const VALUE_Y := 88.0
const LEVEL_Y := 100.0
const ARROW_GAP := 3
const SEAL_CENTER := Vector2(64, 138)
const PICK_ACTIONS: Array[StringName] = [&"grace_pick_1", &"grace_pick_2", &"grace_pick_3"]
const TITLE_Y := 47.0
const HINT_Y := 324.0
const BLINK := 0.4

var flow: GraceFlow
var tuning: GraceTuning

var offer: Array[BlessingData] = []
var level: int = 1
var focus: int = 0
var visible_now: bool = false
var _open_ms: int = 0
## Primeira oferta desta pausa (a página escurece em degraus só nela).
var _first: bool = true
var _chosen: int = -1
var _stamp_ms: int = 0
var _canvas: Node2D


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	if tuning == null:
		tuning = GameState.grace_tuning
	_canvas = Node2D.new()
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)
	EventBus.seals_shown.connect(_on_shown)
	EventBus.blessing_chosen.connect(_on_chosen)
	EventBus.seals_hidden.connect(_on_hidden)


func _on_shown(blessings: Array[BlessingData], p_level: int) -> void:
	_first = not visible_now
	offer = blessings.duplicate()
	level = p_level
	focus = 0
	_chosen = -1
	visible_now = true
	_open_ms = Time.get_ticks_msec()


func _on_chosen(b: BlessingData, _l: int) -> void:
	_chosen = maxi(0, offer.find(b))
	_stamp_ms = Time.get_ticks_msec()


func _on_hidden() -> void:
	visible_now = false
	offer.clear()
	_canvas.queue_redraw()


func _process(_delta: float) -> void:
	if visible_now:
		_canvas.queue_redraw()


# --- Entrada -------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not visible_now or flow == null or _chosen >= 0:
		return
	var handled: bool = false
	for i: int in PICK_ACTIONS.size():
		if event.is_action_pressed(PICK_ACTIONS[i], false) and i < offer.size():
			focus = i
			flow.pick(i)
			handled = true
	if event.is_action_pressed(&"move_left", false):
		focus = maxi(0, focus - 1)
		handled = true
		EventBus.ui_focus_changed.emit()
	elif event.is_action_pressed(&"move_right", false):
		focus = mini(offer.size() - 1, focus + 1)
		handled = true
		EventBus.ui_focus_changed.emit()
	elif event.is_action_pressed(&"cast", false) or event.is_action_pressed(&"ui_accept", false):
		flow.pick(focus)
		handled = true
	var motion := event as InputEventMouseMotion
	if motion != null:
		var over: int = _card_at(_canvas.get_global_transform_with_canvas().affine_inverse() * motion.position)
		if over >= 0:
			focus = over
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		var hit: int = _card_at(_canvas.get_global_transform_with_canvas().affine_inverse() * click.position)
		if hit >= 0:
			focus = hit
			flow.pick(hit)
			handled = true
	if handled:
		get_viewport().set_input_as_handled()


## Selo sob o ponto (coordenadas da página), ou -1.
func _card_at(p: Vector2) -> int:
	for i: int in offer.size():
		if Rect2(card_x(i), CARD_Y - 6, CARD.x, CLICK_H).has_point(p):
			return i
	return -1


func card_x(i: int) -> float:
	var n: int = offer.size()
	var first: float = 320.0 - (CARD.x + PITCH * (n - 1)) / 2.0
	return roundf(first + PITCH * i)


# --- Desenho -------------------------------------------------------------------------------

func _age() -> float:
	return float(Time.get_ticks_msec() - _open_ms) / 1000.0


func _stamp_age() -> float:
	return float(Time.get_ticks_msec() - _stamp_ms) / 1000.0 if _chosen >= 0 else -1.0


func _on_draw() -> void:
	if not visible_now:
		return
	var c: Node2D = _canvas
	var age: float = _age()
	var st: float = _stamp_age()
	# Escurecimento: 25% → 50% (75% no alto contraste) na 1ª oferta; some em degraus na saída.
	var dim: float = UiStyle.dim_level()
	if _first and age < tuning.dim_step:
		dim = 0.25
	if st >= 0.0 and flow != null and GameState.grace.pending == 0:
		var exit_t: float = tuning.stamp_lift + tuning.stamp_impact + tuning.stamp_hold
		if st >= exit_t + tuning.stamp_exit_step:
			dim = 0.0
		elif st >= exit_t:
			dim = 0.25
	if dim > 0.0:
		UiStyle.dim_screen(c, dim)
	_draw_title(c)
	for i: int in offer.size():
		_draw_seal(c, i, age, st)
	_draw_hint(c)


func _draw_title(c: CanvasItem) -> void:
	var text: String = tr(&"GRACE_LEVELUP_TITLE").format({"n": level})
	var w: float = PixelFont.width(text, 2)
	var plate := Rect2(roundf(320 - (w + 16) / 2.0), 44, w + 16, 18)
	c.draw_rect(plate, Palette.INK)
	PixelFont.draw_centered(c, text, 320, TITLE_Y, Palette.CHALK, 2)
	var pending: int = GameState.grace.pending if GameState.grace != null else 0
	if pending > 1:
		var tag: String = "+%d" % (pending - 1)
		UiStyle.draw_tag(c, tag, plate.end.x + 8 + PixelFont.width(tag) / 2.0 + 4, TITLE_Y)


func _draw_hint(c: CanvasItem) -> void:
	var text: String = tr(&"GRACE_HINT").format({
		"p1": Settings.key_label(&"grace_pick_1"), "p2": Settings.key_label(&"grace_pick_2"),
		"p3": Settings.key_label(&"grace_pick_3"), "prev": Settings.key_label(&"move_left"),
		"next": Settings.key_label(&"move_right"), "cast": Settings.key_label(&"cast")})
	var w: float = PixelFont.width(text) + 12
	c.draw_rect(Rect2(roundf(320 - w / 2.0), 321, w, 12), Palette.INK)
	PixelFont.draw_centered(c, text, 320, HINT_Y, UiStyle.text_on_dark(true))


## Degrau da entrada do selo `i` (0..3), ou 4 = em repouso.
func _enter_step(i: int, age: float) -> int:
	var start: float = tuning.seal_enter_start + tuning.seal_stagger * i
	if age < start:
		return -1
	return mini(4, int((age - start) / tuning.seal_enter_step))


func _draw_seal(c: CanvasItem, i: int, age: float, st: float) -> void:
	var step: int = _enter_step(i, age)
	if step < 0:
		return
	var x: float = card_x(i)
	var y: float = CARD_Y
	var size: Vector2 = CARD
	var plain: bool = false  # carta lisa (entrada/saída; D-076: sem xadrez)
	var flash: bool = false
	var focused: bool = i == focus and _chosen < 0
	match step:
		0:
			y -= 8
			plain = true
		1:
			y -= 3
		2:
			y += 1
			size += Vector2(4, -4)
	if st >= 0.0:
		var lift_end: float = tuning.stamp_lift
		var impact_end: float = lift_end + tuning.stamp_impact
		var hold_end: float = impact_end + tuning.stamp_hold
		if i == _chosen:
			if st < lift_end:
				y -= HOVER_LIFT + 2
			elif st < impact_end:
				y += 1
				size += Vector2(6, -4)
				flash = true
				_draw_splashes(c, x + CARD.x / 2.0, y + CARD.y / 2.0, st - lift_end)
			elif st < hold_end:
				y += 1
				_draw_splashes(c, x + CARD.x / 2.0, y + CARD.y / 2.0, st - lift_end)
			elif st < hold_end + tuning.stamp_exit_step:
				plain = true
			else:
				return
		else:
			if st >= impact_end:
				return
			if st >= lift_end:
				plain = true
	elif focused and step >= 4:
		y -= HOVER_LIFT
	# Squash centrado.
	var pos := Vector2(roundf(x - (size.x - CARD.x) / 2.0), roundf(y + (CARD.y - size.y)))
	var body := Rect2(pos, size)
	if step == 0:
		c.draw_rect(body, Palette.INK_SOFT)  # só a silhueta
		return
	# L0 sombra.
	c.draw_rect(Rect2(body.position + (Vector2(3, 6) if focused else Vector2(2, 2)), body.size), Palette.INK_SOFT)
	if plain:
		c.draw_rect(body, Palette.INK_SOFT)
		c.draw_rect(body.grow(-1), Palette.PARCHMENT_OLD)
		return
	# L1 pergaminho.
	var edge: Color = Palette.GOLD if focused else Palette.INK
	var ew: float = 2.0 if focused else UiStyle.outline_w()
	if focused and UiStyle.high():
		UiStyle.frame(c, body.grow(ew + 1), Palette.CHALK)
	c.draw_rect(body.grow(ew), edge)
	c.draw_rect(body, Palette.CHALK if flash else Palette.PARCHMENT)
	if flash:
		return
	UiStyle.frame(c, body.grow(-2), Palette.PARCHMENT_OLD)
	var b: BlessingData = offer[i]
	var o := body.position
	# L2 lacre (fitas e cera sobre a borda de baixo).
	for fx: float in [57.0, 68.0]:
		c.draw_rect(Rect2(o.x + fx - 1, o.y + 140, 5, 13), Palette.INK)
		c.draw_rect(Rect2(o.x + fx, o.y + 140, 3, 12), Palette.PARCHMENT_OLD)
		c.draw_rect(Rect2(o.x + fx + 1, o.y + 150, 1, 2), Palette.INK)
	var sc: Vector2 = o + SEAL_CENTER
	UiStyle.ring(c, sc, 10, Palette.INK)
	UiStyle.disc(c, sc, 9, Palette.BLOOD_DARK)
	c.draw_rect(Rect2(sc.x - 1, sc.y - 3, 2, 6), Palette.CHALK)
	c.draw_rect(Rect2(sc.x - 3, sc.y - 1, 6, 2), Palette.CHALK)
	c.draw_rect(Rect2(o.x + 68, o.y + 132, 1, 1), Palette.GOLD_LIGHT)
	# L3 ícone 2×.
	if b.icon != null:
		c.draw_texture_rect(b.icon, Rect2(o + ICON_POS, Vector2(48, 48)), false)
	# L4 nome, divisor e frase.
	var weapon_card: bool = b.kind == &"weapon_level" and b.value_now != ""
	var name_lines: PackedStringArray = UiStyle.wrap_words(tr(b.display_name), TEXT_W)
	for n: int in mini(1 if weapon_card else 2, name_lines.size()):
		PixelFont.draw_centered(c, name_lines[n], o.x + CARD.x / 2.0, o.y + 64 + n * 8, Palette.INK)
	if weapon_card:
		PixelFont.draw_centered(c, tr(b.subtitle), o.x + CARD.x / 2.0, o.y + SUBTITLE_Y, UiStyle.text_on_light(true))
	c.draw_rect(Rect2(o.x + 12, o.y + 82, 104, 1), Palette.PARCHMENT_OLD)
	if weapon_card:
		_draw_weapon_lines(c, b, o)
	else:
		var desc_lines: PackedStringArray = UiStyle.wrap_words(tr(b.short_desc), TEXT_W)
		for n: int in mini(3, desc_lines.size()):
			PixelFont.draw_centered(c, desc_lines[n], o.x + CARD.x / 2.0, o.y + 88 + n * 8, UiStyle.text_on_light(true))
	# L4b contas do teto.
	_draw_beads(c, b, o)
	# L5 etiqueta da tecla (travada até poder escolher e enquanto a tecla segue apertada).
	var key: String = Settings.key_label(PICK_ACTIONS[i]) if i < PICK_ACTIONS.size() else ""
	var locked: bool = flow == null or not flow.can_pick() or Input.is_action_pressed(PICK_ACTIONS[i])
	if locked:
		var w: float = PixelFont.width(key)
		var r := Rect2(roundf(o.x + 64 - w / 2.0 - 4), o.y - 5, w + 8, 12)
		c.draw_rect(r.grow(1), Palette.INK_SOFT)
		c.draw_rect(r, Palette.PARCHMENT_OLD)
		PixelFont.draw_centered(c, key, o.x + 64, o.y - 2, Palette.INK_SOFT)
	else:
		UiStyle.draw_tag(c, key, o.x + 64, o.y - 2)
	# L6 pena-cursor no foco, só depois da trava.
	if focused and not locked:
		var bob: float = -1.0 if int(_age() / BLINK) % 2 == 0 else 0.0
		UiStyle.draw_quill(c, Vector2(o.x - 6, o.y + 66 + bob), true)


## Contas do teto: quantas escolhas a bênção tem, as feitas, esta e as que faltam.
func _draw_beads(c: CanvasItem, b: BlessingData, o: Vector2) -> void:
	var total: int = _choices_to_cap(b)
	if total <= 0:
		return
	var done: int = _done(b)
	# Arma e ímã: a conta desta escolha em CHALK (o dourado é das palavras e da Graça; T1700).
	var tinted: bool = b.kind != &"stat"
	var w: float = 10.0 * total - 3.0
	var x0: float = roundf(o.x + CARD.x / 2.0 - w / 2.0)
	for k: int in total:
		var r := Rect2(x0 + 10 * k, o.y + 113, 7, 7)
		if k < done:
			c.draw_rect(r, Palette.INK)
		elif k == done:
			c.draw_rect(r, Palette.INK)
			if tinted:
				c.draw_rect(r.grow(-1), Palette.CHALK)
			else:
				c.draw_rect(r.grow(-1), Palette.GOLD)
				c.draw_rect(Rect2(r.end.x - 2, r.position.y + 1, 1, 1), Palette.GOLD_LIGHT)
		else:
			c.draw_rect(r, Palette.INK if UiStyle.high() else Palette.INK_SOFT)
			c.draw_rect(r.grow(-1), Palette.PARCHMENT_OLD)


## Selo de arma (D-099; design-agent): "agora → próximo" e "NV n → n+1/7", centrados.
func _draw_weapon_lines(c: CanvasItem, b: BlessingData, o: Vector2) -> void:
	_draw_change(c, b.value_now, b.value_next, o.x + CARD.x / 2.0, o.y + VALUE_Y)
	var lo: Loadout = GameState.loadout
	if lo != null and lo.slots[b.slot] != null:
		var s: WeaponSlot = lo.slots[b.slot]
		_draw_change(c, "%s %d" % [tr(&"SEAL_LEVEL_SHORT"), s.level],
			"%d/%d" % [s.level + 1, s.weapon.max_level()], o.x + CARD.x / 2.0, o.y + LEVEL_Y)


func _draw_change(c: CanvasItem, now: String, next: String, cx: float, y: float) -> void:
	var w: float = PixelFont.width(now) + ARROW_GAP + 5 + ARROW_GAP + PixelFont.width(next)
	var x: float = roundf(cx - w / 2.0)
	PixelFont.draw(c, now, Vector2(x, y), UiStyle.text_on_light(true))
	UiStyle.draw_arrow(c, Vector2(x + PixelFont.width(now) + ARROW_GAP, y), Palette.INK)
	PixelFont.draw(c, next, Vector2(x + PixelFont.width(now) + ARROW_GAP * 2 + 5, y), Palette.INK)


## Escolhas já feitas: compras da bênção, ou níveis acima do 1 da arma/do ímã.
func _done(b: BlessingData) -> int:
	match b.kind:
		&"weapon_level":
			var lo: Loadout = GameState.loadout
			return lo.slots[b.slot].rank(b.target) if lo != null and lo.slots[b.slot] != null else 0
		&"passive_level":
			return GameState.repulse_level - 1
		&"potion_level":
			return GameState.potions.level(b.target) - 1 if GameState.potions != null else 0
	return GameState.run_stats.buys_of(b.id)


## Quantas escolhas levam a bênção do valor-base até o teto (para as contas).
func _choices_to_cap(b: BlessingData) -> int:
	match b.kind:
		&"weapon_level":
			var lo: Loadout = GameState.loadout
			var u: WeaponUpgradeData = lo.weapon(b.slot).upgrade(b.target) if lo != null and lo.weapon(b.slot) != null else null
			return u.max_rank() if u != null else 0
		&"passive_level":
			return GameState.repulse.max_level() - 1
		&"potion_level":
			return GameState.potion_tuning.by_id(b.target).max_level() - 1
	if b.stat == &"" or GameState.run_stats == null:
		return 0
	var probe := RunStats.new(GameState.run_stats.base)
	var n: int = 0
	while not probe.is_capped(b) and n < 12:
		probe.apply(b)
		n += 1
	return n


func _draw_splashes(c: CanvasItem, cx: float, cy: float, t: float) -> void:
	if t >= tuning.stamp_impact + tuning.stamp_hold:
		return
	var d: float = 4.0 if t < tuning.stamp_impact else 8.0
	for s: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		c.draw_rect(Rect2(roundf(cx + s.x * (CARD.x / 2.0 + d)), roundf(cy + s.y * (CARD.y / 2.0 + d)), 2, 2), Palette.BLOOD_DARK)
