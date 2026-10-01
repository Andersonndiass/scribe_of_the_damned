class_name ShopScreen
extends CanvasLayer
## Tela do Scriptorium Noturno (003 FR-313, FR-314; ficha 28). Placeholder desenhado em código
## com as medidas do design-agent e os tempos do animation-agent (2026-09-28).
## Só teclado: ←/→ escolhe, Espaço compra, L trava, R rerola, Enter vai para a próxima onda.
## Roda com a árvore pausada (PROCESS_MODE_ALWAYS); toda a lógica fica no Shop.

const CARD_SIZE := Vector2(100, 140)
const CARD_Y := 64.0
const CARD_X: Array[float] = [192.0, 300.0, 408.0, 524.0]
const ICON_RECT := Rect2(26, 8, 48, 48)
const NAME_Y: Array[float] = [62.0, 70.0]
const NAME_CHARS := 15
const DESC_Y: Array[float] = [84.0, 92.0, 100.0]
const PRICE_Y := 116.0
const HOVER_LIFT := 4.0
const INK_PLATE := Rect2(520, 16, 104, 24)
const REROLL_PLATE := Rect2(192, 228, 96, 24)
const RIBBON := Rect2(448, 230, 176, 20)
const LEGEND_POS := Vector2(16, 336)
const DROP_ICON := preload("res://assets/placeholders/itm_gota_dourada.tres")
## Prateleira de poções (018; design-agent T1801): na mesa, entre o Rerolar e a fita.
const SHELF := Rect2(298, 221, 138, 46)
const SHELF_CELL := Vector2(32, 42)
const SHELF_X0 := 300.0
const SHELF_STEP := 34.0
const SHELF_Y := 223.0
const SHELF_INFO := Rect2(298, 280, 138, 16)
const PIP := 4.0
const PIP_STEP := 5.0

## Tempos (animation-agent): entrada 5 q @80 ms com 100 ms entre cartas; compra 200 + 400 ms;
## sem tinta treme 4 × 50 ms e o preço fica BLOOD por 400 ms; trava 100 ms; reroll 400 ms por
## carta com 100 ms entre cartas; tinta sobe 20 ms por unidade (no máximo 700 ms); saída 4 × 100 ms.
const ENTER_TIME := 0.4
const ENTER_STAGGER := 0.1
const BUY_HIT := 0.2
const BUY_SETTLE := 0.4
const SHAKE_TIME := 0.2
const SHAKE_STEP := 0.05
const ALERT_TIME := 0.4
const REROLL_TIME := 0.4
const REROLL_STAGGER := 0.1
const INK_STEP := 0.02
const INK_ROLL_MAX := 0.7
const INK_POP := 0.1
const EXIT_TIME := 0.4
const EXIT_STEPS := 4

@export var shop_path: NodePath = ^"../Shop"

var selected: int = 0
## Poção em foco na prateleira (-1 = foco nas cartas). ↓/↑ alternam entre cartas e prateleira.
var shelf_focus: int = -1

var _shop: Shop
var _canvas: Node2D
var _t: float = 0.0
var _anim_start := PackedFloat32Array()
var _anim_kind: Array[StringName] = []
var _shake_left := PackedFloat32Array()
var _alert_left := PackedFloat32Array()
var _ink_shown: float = 0.0
var _ink_rate: float = 0.0
var _pop_left: float = 0.0
var _exit_left: float = -1.0
## 017 (D-087 item 9): carta de arma que troca a ativa esperando o 2º Comprar (-1 = nenhuma).
var confirm_replace: int = -1


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_shop = get_node_or_null(shop_path) as Shop
	# A cena (parede, janela, estante, escrivaninha, vela, escriba) em camadas, atrás das cartas.
	var scene := ShopScene.new()
	scene.name = "Cena"
	add_child(scene)
	_canvas = Node2D.new()
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)
	EventBus.shop_opened.connect(_on_opened)
	EventBus.shop_closed.connect(_on_closed)


func _on_opened(_wave: int) -> void:
	var n: int = _shop.offer.cards.size()
	_anim_start.resize(n)
	_anim_kind.resize(n)
	_shake_left.resize(n)
	_alert_left.resize(n)
	_shake_left.fill(0.0)
	_alert_left.fill(0.0)
	for i: int in n:
		_start_anim(i, &"enter", i * ENTER_STAGGER)
	selected = 0
	_ink_shown = GameState.gold_ink
	_exit_left = -1.0
	visible = true
	_canvas.queue_redraw()


func _on_closed() -> void:
	confirm_replace = -1
	# A onda já recomeçou por baixo; a tela sai em dithering (4 × 100 ms).
	_exit_left = EXIT_TIME


func is_closing() -> bool:
	return _exit_left >= 0.0


func _unhandled_input(event: InputEvent) -> void:
	if visible and _shop != null and _shop.is_open and handle_input(event):
		get_viewport().set_input_as_handled()


## Trata uma tecla da loja. Retorna true se era da loja (e consome a entrada).
func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouse:
		return _mouse_input(_canvas.make_input_local(event) as InputEventMouse)
	if not event.is_pressed() or event.is_echo():
		return false
	var n: int = _shop.offer.cards.size()
	if event.is_action(&"move_down") and shelf_focus < 0:
		shelf_focus = 0
	elif event.is_action(&"move_up") and shelf_focus >= 0:
		shelf_focus = -1
	elif shelf_focus >= 0 and (event.is_action(&"move_left") or event.is_action(&"move_right")):
		var k: int = _shop.potion_count()
		shelf_focus = (shelf_focus + (1 if event.is_action(&"move_right") else -1) + k) % k
	elif shelf_focus >= 0 and event.is_action(&"cast"):
		_try_buy_potion(shelf_focus)
	elif event.is_action(&"move_left"):
		_finish_entry()
		selected = (selected - 1 + n) % n
	elif event.is_action(&"move_right"):
		_finish_entry()
		selected = (selected + 1) % n
	elif event.is_action(&"cast"):
		_finish_entry()
		_try_buy(selected)
	elif event.is_action(&"shop_lock"):
		_finish_entry()
		if _shop.toggle_lock(selected) or _shop.offer.locked_slot() == -1:
			_start_anim(selected, &"lock", 0.0)
	elif event.is_action(&"shop_reroll"):
		_finish_entry()
		_try_reroll()
	elif event.is_action(&"shop_next"):
		_shop.close()
	elif event.is_action(&"pause"):
		pass  # o jogo já está parado na loja: Esc não faz nada aqui
	else:
		return false
	_canvas.queue_redraw()
	return true


## Mouse (D-084): passar sobre a carta seleciona; clique compra, clique direito trava; clique em
## Rerolar e em Próxima onda faz o mesmo que as teclas.
func _mouse_input(m: InputEventMouse) -> bool:
	var b := m as InputEventMouseButton
	var p: Vector2 = m.position
	for i: int in _shop.potion_count():
		if shelf_rect(i).has_point(p):
			shelf_focus = i
			if b != null and b.pressed and b.button_index == MOUSE_BUTTON_LEFT:
				_try_buy_potion(i)
				_canvas.queue_redraw()
				return true
			_canvas.queue_redraw()
			return b != null
	var over: int = -1
	for i: int in _shop.offer.cards.size():
		if i < CARD_X.size() and Rect2(CARD_X[i], CARD_Y - HOVER_LIFT, CARD_SIZE.x, CARD_SIZE.y + HOVER_LIFT).has_point(p):
			over = i
	if b == null:
		if over >= 0 and over != selected:
			selected = over
			_canvas.queue_redraw()
		return false
	if not b.pressed:
		return false
	if over >= 0:
		_finish_entry()
		selected = over
		if b.button_index == MOUSE_BUTTON_LEFT:
			_try_buy(over)
		elif b.button_index == MOUSE_BUTTON_RIGHT:
			if _shop.toggle_lock(over) or _shop.offer.locked_slot() == -1:
				_start_anim(over, &"lock", 0.0)
		_canvas.queue_redraw()
		return true
	if b.button_index != MOUSE_BUTTON_LEFT:
		return false
	if REROLL_PLATE.has_point(p):
		_finish_entry()
		_try_reroll()
		_canvas.queue_redraw()
		return true
	if RIBBON.has_point(p):
		_shop.close()
		return true
	return false


## Estado visível da carta `i` (testes e desenho).
func card_state(i: int) -> StringName:
	if _shop.offer.cards[i] == null:
		return &"empty"
	var kind: StringName = _anim_kind[i] if i < _anim_kind.size() else &""
	if kind != &"" and _anim_age(i) >= 0.0 and _anim_age(i) < _anim_length(kind):
		return kind
	if _shop.offer.is_sold(i):
		return &"sold"
	if not _shop.can_afford(i):
		return &"no_money"
	if _shop.offer.locked_slot() == i:
		return &"locked"
	return &"idle"


func _try_buy(i: int) -> void:
	if _shop.offer.is_sold(i):
		return
	if _shop.replaces_weapon(i) and _shop.can_afford(i) and confirm_replace != i:
		confirm_replace = i  # 1º Comprar só avisa qual arma sai
		return
	confirm_replace = -1
	if _shop.buy(i):
		_start_anim(i, &"buy", 0.0)
		_pop_left = INK_POP
		_ink_rate = maxf(absf(_ink_shown - GameState.gold_ink) / INK_ROLL_MAX, 1.0 / INK_STEP)
	else:
		_shake_left[i] = SHAKE_TIME
		_alert_left[i] = ALERT_TIME


func shelf_rect(i: int) -> Rect2:
	return Rect2(SHELF_X0 + SHELF_STEP * i, SHELF_Y, SHELF_CELL.x, SHELF_CELL.y)


func _try_buy_potion(i: int) -> void:
	if _shop.buy_potion(i):
		_pop_left = INK_POP
		_ink_rate = maxf(absf(_ink_shown - GameState.gold_ink) / INK_ROLL_MAX, 1.0 / INK_STEP)


func _try_reroll() -> void:
	if not _shop.reroll():
		return
	_ink_rate = maxf(absf(_ink_shown - GameState.gold_ink) / INK_ROLL_MAX, 1.0 / INK_STEP)
	var k: int = 0
	for i: int in _shop.offer.cards.size():
		if not _shop.offer.is_sold(i) and i != _shop.offer.locked_slot():
			_start_anim(i, &"reroll", k * REROLL_STAGGER)
			k += 1


func _start_anim(i: int, kind: StringName, delay: float) -> void:
	_anim_kind[i] = kind
	_anim_start[i] = _t + delay


func _anim_age(i: int) -> float:
	return _t - _anim_start[i]


func _anim_length(kind: StringName) -> float:
	match kind:
		&"enter":
			return ENTER_TIME
		&"buy":
			return BUY_HIT + BUY_SETTLE
		&"reroll":
			return REROLL_TIME
		&"lock":
			return 0.1
	return 0.0


## Qualquer tecla termina a entrada na hora (animation-agent).
func _finish_entry() -> void:
	for i: int in _anim_kind.size():
		if _anim_kind[i] == &"enter":
			_anim_kind[i] = &""


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	for i: int in _shake_left.size():
		_shake_left[i] = maxf(0.0, _shake_left[i] - delta)
		_alert_left[i] = maxf(0.0, _alert_left[i] - delta)
	_pop_left = maxf(0.0, _pop_left - delta)
	var target: float = GameState.gold_ink
	if not is_equal_approx(_ink_shown, target):
		_ink_shown = move_toward(_ink_shown, target, maxf(_ink_rate, 1.0 / INK_STEP) * delta)
	if _exit_left >= 0.0:
		_exit_left -= delta
		if _exit_left < 0.0:
			visible = false
	_canvas.queue_redraw()


# --- desenho ------------------------------------------------------------------------------

func _on_draw() -> void:
	if _shop == null or _shop.offer == null:
		return
	for i: int in _shop.offer.cards.size():
		_draw_card(i)
	_draw_ui()
	if _exit_left >= 0.0:
		_draw_exit_dither()


func _draw_card(i: int) -> void:
	var card: ShopItemData = _shop.offer.cards[i]
	if card == null:
		return
	var c := _canvas
	var state: StringName = card_state(i)
	var pos := Vector2(CARD_X[i], CARD_Y)
	var width: float = CARD_SIZE.x
	var show_back: bool = false
	match state:
		&"enter":
			var f: int = clampi(int(_anim_age(i) / (ENTER_TIME / 5.0)), 0, 4)
			width = [100.0, 50.0, 50.0, 100.0, 100.0][f]
			show_back = f < 2
			pos.y += 8.0 - 2.0 * f
		&"reroll":
			var f: int = clampi(int(_anim_age(i) / (REROLL_TIME / 6.0)), 0, 5)
			width = [100.0, 66.0, 2.0, 2.0, 66.0, 100.0][f]
			show_back = f in [1, 2, 3, 4]
		&"buy":
			if _anim_age(i) < BUY_HIT:
				pos.y += 1.0
		_:
			if _shake_left[i] > 0.0:
				pos.x += 1.0 if int(_shake_left[i] / SHAKE_STEP) % 2 == 0 else -1.0
	var is_sel: bool = i == selected and state != &"enter" and shelf_focus < 0  # foco na prateleira: nenhuma carta
	if is_sel:
		pos.y -= HOVER_LIFT
	pos = pos.round()
	var rect := Rect2(pos + Vector2((CARD_SIZE.x - width) / 2.0, 0), Vector2(width, CARD_SIZE.y)).abs()
	var shadow := Vector2(3, 6) if is_sel else Vector2(2, 2)
	c.draw_rect(Rect2(rect.position + shadow, rect.size), Palette.INK_SOFT)
	if show_back or width < CARD_SIZE.x:
		c.draw_rect(rect.grow(1), Palette.PARCHMENT_OLD)
		c.draw_rect(rect, Palette.INK_SOFT)
		if state == &"reroll":
			for k: int in 6:
				c.draw_rect(Rect2(rect.position.x + k * rect.size.x / 6.0, rect.end.y - 2, 1, 2), Palette.BLOOD)
		return
	var apo: bool = card.kind == &"apocrypha"
	c.draw_rect(rect.grow(2 if is_sel else 1), Palette.GOLD if is_sel else Palette.INK)
	var dim: bool = state == &"no_money"
	c.draw_rect(rect, Palette.PARCHMENT_OLD if (apo or dim) else Palette.PARCHMENT)
	if apo:
		for y: float in [rect.position.y - 3.0, rect.end.y - 3.0]:
			c.draw_rect(Rect2(rect.position.x - 2, y, rect.size.x + 4, 6), Palette.PARCHMENT)
			c.draw_rect(Rect2(rect.position.x - 2, y + 2, rect.size.x + 4, 1), Palette.INK)
		PixelFont.draw_centered(c, tr(&"SHOP_APOCRYPHA"), rect.get_center().x, pos.y + 4, Palette.INK_SOFT)
	else:
		UiStyle.frame(c, Rect2(rect.position + Vector2(2, 2), rect.size - Vector2(4, 4)), Palette.INK_SOFT if dim else Palette.PARCHMENT_OLD)
	if is_sel:
		c.draw_rect(Rect2(pos + Vector2(CARD_SIZE.x / 2 - 3, -8), Vector2(7, 4)), Palette.GOLD)
	if card.icon != null:
		c.draw_texture_rect(card.icon, Rect2(pos + ICON_RECT.position, ICON_RECT.size), false)
	# Vendida: só o ícone apagado, o selo e "VENDIDO" (o texto da carta sai).
	var sold_look: bool = state == &"sold" or (state == &"buy" and _anim_age(i) >= BUY_HIT)
	if sold_look or state == &"buy":
		# Vendida (D-076): carta lisa PARCHMENT_OLD com borda INK_SOFT, selo GOLD e "VENDIDO" (sem xadrez).
		c.draw_rect(Rect2(pos, CARD_SIZE), Palette.INK_SOFT)
		c.draw_rect(Rect2(pos + Vector2.ONE, CARD_SIZE - Vector2(2, 2)), Palette.PARCHMENT_OLD)
		if sold_look:
			UiStyle.disc(c, pos + ICON_RECT.get_center(), 13, Palette.INK)
			UiStyle.disc(c, pos + ICON_RECT.get_center(), 12, Palette.GOLD)
			UiStyle.disc(c, pos + ICON_RECT.get_center() + Vector2(3, -3), 3, Palette.GOLD_LIGHT)
			PixelFont.draw_centered(c, tr(&"SHOP_SOLD"), pos.x + CARD_SIZE.x / 2, pos.y + 84, Palette.INK)
		elif _anim_age(i) < 0.034:
			c.draw_rect(rect, Palette.CHALK)
		return
	var lines: PackedStringArray = _wrap(tr(card.display_name), NAME_CHARS)
	var name_scale: int = 2 if apo and lines.size() == 1 and PixelFont.width(lines[0], 2) <= CARD_SIZE.x - 8 else 1
	for k: int in mini(lines.size(), NAME_Y.size()):
		PixelFont.draw_centered(c, lines[k], pos.x + CARD_SIZE.x / 2, pos.y + NAME_Y[k] - (3 if name_scale == 2 else 0), Palette.INK_SOFT if dim else Palette.INK, name_scale)
	c.draw_rect(Rect2(pos + Vector2(8, 78), Vector2(84, 1)), Palette.PARCHMENT_OLD)
	var desc: PackedStringArray = _wrap(tr(card.short_desc), NAME_CHARS)
	for k: int in mini(desc.size(), DESC_Y.size()):
		PixelFont.draw_centered(c, desc[k], pos.x + CARD_SIZE.x / 2, pos.y + DESC_Y[k], Palette.INK_SOFT)
	_draw_price(i, pos, state)
	if _shop.offer.locked_slot() == i:
		c.draw_rect(Rect2(pos + Vector2(CARD_SIZE.x / 2 - 2, -2), Vector2(4, 4)), Palette.GOLD)
		c.draw_rect(Rect2(pos + Vector2(86, 4), Vector2(8, 9)), Palette.PARCHMENT_OLD)
		c.draw_rect(Rect2(pos + Vector2(89, 8), Vector2(2, 3)), Palette.INK)


func _draw_price(i: int, pos: Vector2, state: StringName) -> void:
	var text: String = str(_shop.offer.prices[i])
	var color: Color = Palette.BLOOD if (state == &"no_money" or _alert_left[i] > 0.0) else Palette.INK
	var w: float = 6 + 3 + PixelFont.width(text, 2)
	var x: float = roundf(pos.x + CARD_SIZE.x / 2 - w / 2)
	_canvas.draw_texture(DROP_ICON, Vector2(x, pos.y + PRICE_Y - 1))
	PixelFont.draw(_canvas, text, Vector2(x + 9, pos.y + PRICE_Y - 3), color, 2)
	if state == &"no_money":
		# Sem tinta: preço em alerta com um traço de 2 px (sem xadrez, D-076).
		_canvas.draw_rect(Rect2(x + 9, pos.y + PRICE_Y + 2, PixelFont.width(text, 2), 2), Palette.INK_SOFT)


func _draw_ui() -> void:
	var c := _canvas
	PixelFont.draw(c, tr(&"SHOP_TITLE"), Vector2(192, 22), Palette.PARCHMENT_OLD, 2)
	UiStyle.draw_panel(c, INK_PLATE)
	var lift: float = -1.0 if _pop_left > 0.0 else 0.0
	c.draw_texture(DROP_ICON, Vector2(528, 24))
	var ink_text: String = str(roundi(_ink_shown))
	if _pop_left > 0.0:
		for o: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			PixelFont.draw(c, ink_text, Vector2(540, 22 + lift) + o, Palette.GOLD, 2)
	PixelFont.draw(c, ink_text, Vector2(540, 22 + lift), Palette.INK, 2)
	# Reroll: dado de osso, custo; BLOOD só sem tinta.
	UiStyle.draw_panel(c, REROLL_PLATE)
	var die := Rect2(REROLL_PLATE.position + Vector2(4, 5), Vector2(14, 14))
	c.draw_rect(die, Palette.PARCHMENT_OLD)
	for p: Vector2 in [Vector2(3, 3), Vector2(7, 7), Vector2(11, 11)]:
		c.draw_rect(Rect2(die.position + p - Vector2.ONE, Vector2(2, 2)), Palette.INK)
	PixelFont.draw(c, tr(&"SHOP_REROLL"), REROLL_PLATE.position + Vector2(22, 9), Palette.INK)
	var cost: int = _shop.offer.reroll_cost()
	var cost_color: Color = Palette.BLOOD if GameState.gold_ink < cost else Palette.INK
	c.draw_texture(DROP_ICON, REROLL_PLATE.position + Vector2(68, 8))
	PixelFont.draw(c, str(cost), REROLL_PLATE.position + Vector2(77, 9), cost_color)
	# Fita da próxima onda, com rabo de andorinha.
	c.draw_rect(RIBBON, Palette.BLOOD_DARK)
	for side: float in [RIBBON.position.x - 6.0, RIBBON.end.x]:
		c.draw_rect(Rect2(side, RIBBON.position.y, 6, 6), Palette.BLOOD_DARK)
		c.draw_rect(Rect2(side, RIBBON.end.y - 6, 6, 6), Palette.BLOOD_DARK)
	PixelFont.draw_centered(c, tr(&"SHOP_NEXT").format({"next": Settings.key_label(&"shop_next")}), RIBBON.get_center().x, 237, Palette.CHALK)
	_draw_shelf()
	if confirm_replace >= 0 and GameState.loadout != null:
		var leaving: WeaponData = GameState.loadout.weapon(GameState.loadout.active)
		var ask: String = tr(&"SHOP_REPLACE_CONFIRM").format({"weapon": tr(leaving.display_name) if leaving != null else ""})
		UiStyle.draw_tag(c, ask, 320.0, LEGEND_POS.y - 14.0)
	PixelFont.draw(c, tr(&"SHOP_LEGEND").format({
		"cast": Settings.key_label(&"cast"), "lock": Settings.key_label(&"shop_lock"),
		"reroll": Settings.key_label(&"shop_reroll"), "next": Settings.key_label(&"shop_next")}), LEGEND_POS, Palette.PARCHMENT_OLD)


## Prateleira (design-agent T1801): 4 células com o ícone, as cargas em quadradinhos, o preço
## (BLOOD sem tinta) ou "MAX", e o nível a partir do 2; a selecionada sobe 2 px com borda INK de 2 px.
func _draw_shelf() -> void:
	if GameState.potions == null:
		return
	var c := _canvas
	UiStyle.draw_panel(c, SHELF)
	var belt: PotionBelt = GameState.potions
	for i: int in _shop.potion_count():
		var p: PotionData = _shop.potion_at(i)
		var r: Rect2 = shelf_rect(i)
		var sel: bool = i == shelf_focus
		var full: bool = belt.is_full(p.id)
		if sel:
			r.position.y -= 2.0
			c.draw_rect(r, Palette.INK)
			c.draw_rect(r.grow(-2), Palette.PARCHMENT)
		else:
			c.draw_rect(r, Palette.INK_SOFT)
			c.draw_rect(r.grow(-1), Palette.PARCHMENT_OLD if full else Palette.PARCHMENT)
		if p.shop_icon != null:
			c.draw_texture(p.shop_icon, r.position + Vector2(4, 2))
		for k: int in belt.max_charges(p.id):
			var pip := Rect2(r.position.x + 4 + PIP_STEP * k, r.position.y + 28, PIP, PIP)
			c.draw_rect(pip, Palette.INK)
			if k >= belt.charges(p.id):
				c.draw_rect(pip.grow(-1), Palette.PARCHMENT_OLD)
		if belt.level(p.id) >= 2:
			var lv := Rect2(r.position.x + 23, r.position.y + 1, 8, 9)
			c.draw_rect(lv, Palette.INK)
			c.draw_rect(lv.grow(-1), Palette.PARCHMENT)
			PixelFont.draw_centered(c, str(belt.level(p.id)), lv.get_center().x, lv.position.y + 2, Palette.INK)
		if full:
			PixelFont.draw(c, tr(&"SHOP_FULL"), r.position + Vector2(5, 33), Palette.INK_SOFT)
		else:
			var price: int = _shop.potion_price(i)
			c.draw_texture(DROP_ICON, r.position + Vector2(3, 32))
			PixelFont.draw(c, str(price), r.position + Vector2(13, 33), Palette.BLOOD if GameState.gold_ink < price else Palette.INK)
	if shelf_focus >= 0:
		var p: PotionData = _shop.potion_at(shelf_focus)
		var w: float = maxf(SHELF_INFO.size.x, maxf(PixelFont.width(tr(p.display_name)), PixelFont.width(tr(p.short_desc))) + 8.0)
		var info := Rect2(SHELF_INFO.position, Vector2(w, SHELF_INFO.size.y))
		UiStyle.draw_panel(c, info)
		PixelFont.draw(c, tr(p.display_name), info.position + Vector2(4, 1), Palette.INK)
		PixelFont.draw(c, tr(p.short_desc), info.position + Vector2(4, 8), Palette.INK_SOFT)


## Saída: dithering Bayer em 4 passos cobrindo a tela da loja cada vez menos.
func _draw_exit_dither() -> void:
	var step: int = clampi(EXIT_STEPS - 1 - int(_exit_left / (EXIT_TIME / EXIT_STEPS)), 0, EXIT_STEPS - 1)
	var bayer: Array[int] = [0, 2, 3, 1]
	for y: int in range(0, 360, 2):
		for x: int in range(0, 640, 2):
			if bayer[(x / 2 % 2) + (y / 2 % 2) * 2] <= step:
				_canvas.draw_rect(Rect2(x, y, 2, 2), Palette.INK)


func _wrap(text: String, max_chars: int) -> PackedStringArray:
	var out := PackedStringArray()
	var line: String = ""
	for word: String in PixelFont.normalize(text).split(" ", false):
		if line.is_empty():
			line = word
		elif line.length() + 1 + word.length() <= max_chars:
			line += " " + word
		else:
			out.append(line)
			line = word
	if not line.is_empty():
		out.append(line)
	return out
