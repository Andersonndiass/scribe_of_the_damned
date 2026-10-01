class_name WeaponBar
extends Node2D
## Inventário no HUD (017 FR-1701; design-agent T1700, T1800): 2 espaços no canto de baixo à
## esquerda, com ícone, tecla (1/2) em cima à esquerda, nível na etiqueta de baixo à direita e a
## recarga numa barra embaixo. Ativo: sobe 2 px, borda INK de 2 px, miolo PARCHMENT; inativo:
## PARCHMENT_OLD e ícone recolorido para tons baixos; sem GOLD (o dourado é das palavras).
## A 018 alarga o painel para as 4 poções (POTION_SLOTS).

const POTION_SLOTS := 4
## Poções (018; design-agent T1801): espaço 20×20 em x = 78 + 22i; etiquetas embaixo (tecla e
## cargas); barra de 4 px; divisória entre armas e poções.
const POTION_X0 := 78
const POTION_STEP := 22
const POTION_SLOT := 20
const POTION_ICON := 2
const POTION_TAG_Y := 335
const POTION_BAR_Y := 345
const POTION_BAR_H := 4
const DIVIDER := Rect2(74, 314, 1, 35)
const LOCK := preload("res://assets/placeholders/ui_potion_lock.png")
## Recolor do frasco apagado (o das armas some com o vidro): ink→ink_soft, chalk→parchment.
const DIM_POTION: Dictionary = {"ink": "ink_soft", "chalk": "parchment"}
## Resposta à tecla recusada (animation-agent T1801).
const DENY_SHAKE := 0.1
const BLOCKED_X := 0.1
const GAP_FLASH := 0.05
const PANEL := Rect2(7, 311, 66, 40)
const PANEL_WITH_POTIONS := Rect2(7, 311, 160, 40)
const SLOT_X0 := 10
const SLOT_STEP := 32
const SLOT_Y := 314
const SLOT := 28
const LIFT := 2
## Etiquetas 8×9 (tecla e nível).
const TAG := Vector2(8, 9)
## Barra de recarga embaixo de cada espaço (não sobe com o ativo).
const CHARGE_Y := 344
const CHARGE_H := 5
## Recolor do ícone no espaço inativo (tons baixos, só cores da paleta).
const DIM_MAP: Dictionary = {"ink": "ink_soft", "chalk": "parchment", "parchment": "parchment_old"}

var _dim_cache: Dictionary = {}
## Largura desenhada da recarga por espaço (redesenha só quando muda).
var _charge_px := PackedInt32Array([-1, -1])
## Por poção: tempo restante do tremor (sem carga), do X (bloqueada) e do flash (intervalo).
var _deny := PackedFloat32Array([0, 0, 0, 0])
var _blocked := PackedFloat32Array([0, 0, 0, 0])
var _flash := PackedFloat32Array([0, 0, 0, 0])


func _ready() -> void:
	EventBus.weapon_switched.connect(func(_s: int, _w: WeaponData) -> void: queue_redraw())
	EventBus.weapon_equipped.connect(func(_s: int, _w: WeaponData, _l: int) -> void: queue_redraw())
	EventBus.weapon_leveled.connect(func(_s: int, _w: WeaponData, _l: int) -> void: queue_redraw())
	EventBus.settings_applied.connect(queue_redraw)
	EventBus.wave_started.connect(func(_i: int, _d: float) -> void: queue_redraw())
	EventBus.potion_refused.connect(_on_potion_refused)
	queue_redraw.call_deferred()


func hud_rect() -> Rect2:
	return UiStyle.plate_area(_panel())


func _panel() -> Rect2:
	return PANEL_WITH_POTIONS if POTION_SLOTS > 0 else PANEL


func _on_potion_refused(id: StringName, reason: StringName) -> void:
	var i: int = _potion_index(id)
	if i < 0:
		return
	match reason:
		&"empty", &"full":
			_deny[i] = DENY_SHAKE
		&"gap":
			_flash[i] = GAP_FLASH
		_:
			_blocked[i] = BLOCKED_X


func _potion_index(id: StringName) -> int:
	if GameState.potions == null:
		return -1
	var order: Array[PotionData] = GameState.potions.tuning.order
	for i: int in order.size():
		if order[i].id == id:
			return i
	return -1


func _process(delta: float) -> void:
	for i: int in 4:
		_deny[i] = maxf(0.0, _deny[i] - delta)
		_blocked[i] = maxf(0.0, _blocked[i] - delta)
		_flash[i] = maxf(0.0, _flash[i] - delta)
	if GameState.potions != null:
		queue_redraw()  # barras de efeito e de intervalo andam todo quadro
	var lo: Loadout = GameState.loadout
	if lo == null:
		return
	for i: int in mini(2, lo.slots.size()):
		var px: int = -1 if lo.slots[i] == null else floori((SLOT - 2) * lo.slots[i].charge)
		if px != _charge_px[i]:
			_charge_px[i] = px
			queue_redraw()


func _draw() -> void:
	var lo: Loadout = GameState.loadout
	UiStyle.draw_plate(self, _panel())
	if lo == null:
		return
	for i: int in mini(2, lo.slots.size()):
		_draw_slot(i, lo.slots[i], i == lo.active)
	if POTION_SLOTS > 0 and GameState.potions != null:
		draw_rect(DIVIDER, Palette.INK_SOFT)
		for i: int in mini(POTION_SLOTS, GameState.potions.tuning.order.size()):
			_draw_potion(i, GameState.potions.tuning.order[i])


## Espaço da poção `i` (design-agent T1801): pronta, em efeito (sobe 2 px), em intervalo, sem carga
## e bloqueada (cadeado no lugar da tecla). Nada só por cor: muda a borda, a barra e o ícone.
func _draw_potion(i: int, p: PotionData) -> void:
	var b: PotionBelt = GameState.potions
	var user: PotionUser = _potion_user()
	var x: float = POTION_X0 + POTION_STEP * i + (1.0 if _deny[i] > 0.0 and int(_deny[i] / 0.05) % 2 == 0 else 0.0)
	var charges: int = b.charges(p.id)
	var empty: bool = charges <= 0
	var in_effect: bool = b.active(p.id)
	var in_gap: bool = user != null and user.phase == PotionUser.Phase.GAP
	var blocked: bool = user == null or user.phase == PotionUser.Phase.OFF or GameState.letter_menu_open or GameState.levelup_beam
	var lit: bool = not empty and not in_gap and not blocked
	var y: float = SLOT_Y - (LIFT if in_effect else 0)
	var r := Rect2(x, y, POTION_SLOT, POTION_SLOT)
	if in_effect:
		draw_rect(r, Palette.INK)
		draw_rect(r.grow(-2), Palette.PARCHMENT)
		draw_rect(Rect2(x - 1, SLOT_Y + POTION_SLOT, POTION_SLOT + 2, 2), Palette.INK_SOFT)
	elif lit:
		draw_rect(r, Palette.INK)
		draw_rect(r.grow(-1), Palette.PARCHMENT)
	else:
		draw_rect(r, Palette.INK_SOFT)
		draw_rect(r.grow(-1), Palette.PARCHMENT_OLD)
	if _flash[i] > 0.0:
		draw_rect(r.grow(-1), Palette.CHALK)
	if p.icon != null:
		var tex: Texture2D = p.icon if (lit or in_effect) else _dimmed_potion(p)
		draw_texture(tex, Vector2(x + POTION_ICON, y + POTION_ICON))
	# Tecla (ou cadeado) e cargas embaixo do espaço.
	var tag := Rect2(x, POTION_TAG_Y, TAG.x, TAG.y)
	var edge: Color = Palette.INK if lit or in_effect else Palette.INK_SOFT
	draw_rect(tag, edge)
	if blocked:
		draw_texture(LOCK, tag.position + Vector2(2, 2))
	else:
		PixelFont.draw(self, Settings.key_label(PotionUser.ACTIONS[i]), tag.position + Vector2(2, 2), Palette.CHALK if lit else Palette.PARCHMENT)
	var ctag := Rect2(x + POTION_SLOT - TAG.x, POTION_TAG_Y, TAG.x, TAG.y)
	draw_rect(ctag, edge)
	draw_rect(ctag.grow(-1), Palette.PARCHMENT if lit else Palette.PARCHMENT_OLD)
	PixelFont.draw_centered(self, str(charges), ctag.get_center().x, ctag.position.y + 2, edge)
	if _blocked[i] > 0.0:
		for k: int in 6:
			draw_rect(Rect2(x + 7 + k, y + 7 + k, 1, 1), Palette.CHALK)
			draw_rect(Rect2(x + 12 - k, y + 7 + k, 1, 1), Palette.CHALK)
	# Barra: duração restante, intervalo enchendo, pronta cheia; sem carga = traço.
	var bar := Rect2(x, POTION_BAR_Y, POTION_SLOT, POTION_BAR_H)
	if empty and not in_effect:
		draw_rect(Rect2(x + 2, POTION_BAR_Y + 1, POTION_SLOT - 4, 1), Palette.INK_SOFT)
	elif in_effect:
		var total: float = b.stats(p.id).duration
		UiStyle.draw_bar(self, bar, b.left.get(p.id, 0.0) / maxf(total, 0.001), Palette.PARCHMENT_OLD, Palette.INK)
	elif in_gap:
		var gap: float = b.tuning.use_gap
		UiStyle.draw_bar(self, bar, 1.0 - user.gap_left / maxf(gap, 0.001), Palette.PARCHMENT_OLD, Palette.INK_SOFT, null, 0, Palette.INK_SOFT)
	else:
		var inner: Rect2 = UiStyle.draw_bar(self, bar, 1.0, Palette.PARCHMENT_OLD, Palette.INK if lit else Palette.INK_SOFT, null, 0, edge)
		if lit:
			draw_rect(Rect2(inner.position, Vector2(inner.size.x, 1)), Palette.CHALK)


func _potion_user() -> PotionUser:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	return player.potion_user if player != null else null


func _dimmed_potion(p: PotionData) -> Texture2D:
	var key: StringName = StringName("potion_" + String(p.id))
	if _dim_cache.has(key):
		return _dim_cache[key]
	var img: Image = p.icon.get_image()
	if img == null:
		return p.icon
	img.convert(Image.FORMAT_RGBA8)
	var swap: Dictionary = {}
	for from: String in DIM_POTION:
		swap[Palette.ALL[StringName(from)].to_rgba32()] = Palette.ALL[StringName(DIM_POTION[from])]
	for py: int in img.get_height():
		for px: int in img.get_width():
			var c: Color = img.get_pixel(px, py)
			if c.a8 > 0 and swap.has(Color(c.r, c.g, c.b, 1.0).to_rgba32()):
				img.set_pixel(px, py, swap[Color(c.r, c.g, c.b, 1.0).to_rgba32()])
	var tex := ImageTexture.create_from_image(img)
	_dim_cache[key] = tex
	return tex


func _draw_slot(i: int, slot: WeaponSlot, active: bool) -> void:
	var x: float = SLOT_X0 + SLOT_STEP * i
	var y: float = SLOT_Y - (LIFT if active and slot != null else 0)
	var r := Rect2(x, y, SLOT, SLOT)
	if slot == null:
		draw_rect(r, Palette.INK_SOFT)
		draw_rect(r.grow(-1), Palette.PARCHMENT_OLD)
	elif active:
		draw_rect(r, Palette.INK)
		draw_rect(r.grow(-2), Palette.PARCHMENT)
		draw_rect(Rect2(x - 1, SLOT_Y + SLOT, SLOT + 2, 2), Palette.INK_SOFT)
	else:
		draw_rect(r, Palette.INK_SOFT)
		draw_rect(r.grow(-1), Palette.PARCHMENT_OLD)
	var edge: Color = Palette.INK if active else Palette.INK_SOFT
	if slot != null and slot.weapon.icon != null:
		var tex: Texture2D = slot.weapon.icon if active else _dimmed(slot.weapon)
		draw_texture(tex, Vector2(x + 2, y + 2))
	# Tecla no canto de cima à esquerda.
	var key: String = Settings.key_label(StringName("weapon_%d" % (i + 1)))
	var kw: float = PixelFont.width(key) + 3
	draw_rect(Rect2(x, y, maxf(kw, TAG.x), TAG.y), edge)
	PixelFont.draw(self, key, Vector2(x + 2, y + 2), Palette.CHALK if active else Palette.PARCHMENT)
	if slot == null:
		return
	# Nível na etiqueta de baixo à direita.
	var lv := Rect2(x + SLOT - TAG.x, y + SLOT - TAG.y, TAG.x, TAG.y)
	draw_rect(lv, edge)
	draw_rect(lv.grow(-1), Palette.PARCHMENT if active else Palette.PARCHMENT_OLD)
	PixelFont.draw_centered(self, str(slot.level), lv.get_center().x, lv.position.y + 2, edge)
	# Recarga: moldura, trilho claro, preenchimento em tinta; pronta = linha de luz CHALK.
	var inner: Rect2 = UiStyle.draw_bar(self, Rect2(x, CHARGE_Y, SLOT, CHARGE_H), slot.charge,
		Palette.PARCHMENT_OLD, edge, null, 0, edge)
	if active and slot.charge >= 1.0:
		draw_rect(Rect2(inner.position, Vector2(inner.size.x, 1)), Palette.CHALK)


## Ícone em tons baixos para o espaço inativo (feito uma vez por arma, cores exatas da paleta).
func _dimmed(w: WeaponData) -> Texture2D:
	if _dim_cache.has(w.id):
		return _dim_cache[w.id]
	var img: Image = w.icon.get_image()
	if img == null:
		return w.icon
	img.convert(Image.FORMAT_RGBA8)
	var swap: Dictionary = {}
	for from: String in DIM_MAP:
		swap[Palette.ALL[StringName(from)].to_rgba32()] = Palette.ALL[StringName(DIM_MAP[from])]
	for py: int in img.get_height():
		for px: int in img.get_width():
			var c: Color = img.get_pixel(px, py)
			if c.a8 > 0 and swap.has(Color(c.r, c.g, c.b, 1.0).to_rgba32()):
				img.set_pixel(px, py, swap[Color(c.r, c.g, c.b, 1.0).to_rgba32()])
	var tex := ImageTexture.create_from_image(img)
	_dim_cache[w.id] = tex
	return tex
