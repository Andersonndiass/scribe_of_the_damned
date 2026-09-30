class_name WeaponBar
extends Node2D
## Inventário no HUD (017 FR-1701; design-agent T1700): 2 espaços no canto de baixo à esquerda, com
## ícone, tecla (1/2) e nível em contas. Ativo: sobe 2 px, borda INK de 2 px, miolo PARCHMENT;
## inativo: PARCHMENT_OLD e ícone recolorido para tons baixos; sem GOLD (o dourado é das palavras).
## O painel já reserva o lugar das 4 poções (018).

const PANEL := Rect2(8, 308, 68, 46)
const SLOT_X0 := 12
const SLOT_STEP := 32
const SLOT_Y := 312
const SLOT := 28
const LIFT := 2
const BEAD_Y := 344
const BEADS := 5
## Recolor do ícone no espaço inativo (tons baixos, só cores da paleta).
const DIM_MAP: Dictionary = {"ink": "ink_soft", "chalk": "parchment", "parchment": "parchment_old"}

var _dim_cache: Dictionary = {}


func _ready() -> void:
	EventBus.weapon_switched.connect(func(_s: int, _w: WeaponData) -> void: queue_redraw())
	EventBus.weapon_equipped.connect(func(_s: int, _w: WeaponData, _l: int) -> void: queue_redraw())
	EventBus.weapon_leveled.connect(func(_s: int, _w: WeaponData, _l: int) -> void: queue_redraw())
	EventBus.settings_applied.connect(queue_redraw)
	EventBus.wave_started.connect(func(_i: int, _d: float) -> void: queue_redraw())
	queue_redraw.call_deferred()


func hud_rect() -> Rect2:
	return PANEL.grow(1)


func _draw() -> void:
	var lo: Loadout = GameState.loadout
	UiStyle.draw_panel(self, PANEL)
	if lo == null:
		return
	for i: int in mini(2, lo.slots.size()):
		_draw_slot(i, lo.slots[i], i == lo.active)


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
	if slot != null and slot.weapon.icon != null:
		var tex: Texture2D = slot.weapon.icon if active else _dimmed(slot.weapon)
		draw_texture(tex, Vector2(x + 2, y + 2))
	# Tecla no canto de cima à esquerda.
	var key: String = Settings.key_label(StringName("weapon_%d" % (i + 1)))
	var kw: float = PixelFont.width(key) + 3
	draw_rect(Rect2(x, y, kw, 9), Palette.INK if active else Palette.INK_SOFT)
	PixelFont.draw(self, key, Vector2(x + 2, y + 2), Palette.CHALK if active else Palette.PARCHMENT)
	# Nível em contas.
	if slot == null:
		return
	for b: int in BEADS:
		var bead := Rect2(x + 2 + 5 * b, BEAD_Y, 4, 4)
		if b < slot.level:
			draw_rect(bead, Palette.INK if active else Palette.INK_SOFT)
		else:
			draw_rect(bead, Palette.INK_SOFT if active else Palette.PARCHMENT_OLD)
			draw_rect(bead.grow(-1), Palette.PARCHMENT)


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
