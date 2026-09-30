class_name HudAtril
extends Node2D
## O atril no HUD (T072, T073, art bible §8.3): espaços = capacidade, letras na ordem, estados
## EMPTY/FILL/PARTIAL/VALID/FULL_REJECT e animações CAST, PURGE, HERESY, REJECT; dicas à direita.
## Fica na faixa de baixo (Y > 300), fora da área central. No VALID nada na tela brilha mais.
## 002: COMBO_READY = VALID numa palavra que fecha combo → 2ª moldura GOLD (forma, não brilho);
## as dicas que fecham combo com a última palavra ficam em GOLD.

enum Anim { NONE, CAST, PURGE, HERESY, REJECT, FIZZLE }

const SLOT := Vector2(12, 14)
const SLOT_GAP := 2
const TOP := 314.0
const CENTER_X := 320.0
const HINTS_GAP := 22
## T1800: painel D (miolo) em volta dos espaços: 12 px de cada lado (cabe o selo), de y308 a y340
## (a janela de combo fica dentro, em y335).
const PLATE_SIDE := 12.0
const PLATE_TOP := 308.0
const PLATE_H := 32.0
const HERESY_Y := 298.0
## Painel das dicas: respiro de 4 px em volta do texto, 14 de altura.
const HINTS_PAD := 4.0
const HINTS_H := 14.0
const HINTS_TEXT_Y := 318.0
## Largura reservada às dicas nos retângulos do HUD.
const HINTS_RESERVE := 120.0
## Duração das animações (escala de durações do art bible §14 / ficha 26: frames × ms).
const ANIM_TIME: Dictionary[int, float] = {
	Anim.CAST: 0.3, Anim.PURGE: 0.2, Anim.HERESY: 0.36, Anim.REJECT: 0.15, Anim.FIZZLE: 0.2,
}
const VALID_PULSE := 0.2
const HERESY_TEXT := "HÆRESIS!"
## VERBUM (design-agent): a palavra repetida aparece como fantasma INK_SOFT em xadrez, +2 px.
const ECHO_TIME := 0.3
const ECHO_OFFSET := Vector2(2, 2)
## Falha do VERBUM: as letras piscam INK_SOFT 2 vezes em 0.2 s (sem BLOOD: não é dano).
const FIZZLE_BLINK := 0.05
## MISERERE (design-agent): selo GOLD 5×5 no canto do atril com o perdão guardado; ao ser usado,
## pisca CHALK 3× em 0.3 s e some, e uma cruz GOLD de 7 px sobe 8 px sobre o escriba em 0.4 s.
const SEAL_SIZE := 5
const SEAL_BLINK_TIME := 0.3
const SEAL_BLINKS := 3
const FORGIVEN_CROSS_TIME := 0.4
const FORGIVEN_CROSS_RISE := 8.0
const FORGIVEN_CROSS_ABOVE := 26.0

var letters := PackedStringArray()
var status: int = Atril.Status.EMPTY
var hints := PackedStringArray()
var rare_mask: int = 0
var anim: Anim = Anim.NONE

var _anim_left: float = 0.0
var _pulse: float = 0.0
var _last_letters := PackedStringArray()
## Latim das palavras que fecham combo com a última conjurada (vazio sem janela aberta).
var combo_partners := PackedStringArray()
var echo_text: String = ""
var forgiveness_ready: bool = false
var _seal_blink_left: float = 0.0
var _cross_left: float = 0.0
var _cross_at: Vector2 = Vector2.ZERO
## Rasura (006): aviso na última letra durante a telegrafia; rabisco INK por 3 quadros ao apagar.
var erasure_warning: bool = false
var _erased_left: float = 0.0
var _erased_slot: int = -1
const ERASE_SCRIBBLE := 0.05
var _echo_left: float = 0.0


func _ready() -> void:
	EventBus.atril_changed.connect(_on_atril_changed)
	EventBus.word_cast.connect(func(_w: WordData, _p: float, _o: Vector2, _d: Vector2) -> void: _play(Anim.CAST))
	EventBus.atril_purged.connect(func(_l: PackedStringArray, _p: Vector2) -> void: _play(Anim.PURGE))
	EventBus.heresy_committed.connect(func(_p: Vector2) -> void: _play(Anim.HERESY))
	EventBus.letter_rejected.connect(func(_l: String) -> void: _play(Anim.REJECT))
	EventBus.combo_window_opened.connect(func(_w: WordData, _d: float, partners: PackedStringArray) -> void:
		combo_partners = partners
		queue_redraw())
	EventBus.verbum_echoed.connect(func(w: WordData) -> void:
		echo_text = w.latin
		_echo_left = ECHO_TIME
		queue_redraw())
	EventBus.verbum_failed.connect(func() -> void: _play(Anim.FIZZLE))
	EventBus.erasure_warned.connect(func(active: bool) -> void:
		erasure_warning = active
		queue_redraw())
	EventBus.letter_erased.connect(func(_l: String, _p: Vector2) -> void:
		_erased_slot = letters.size()
		_erased_left = ERASE_SCRIBBLE
		queue_redraw())
	EventBus.heresy_forgiveness_granted.connect(func() -> void:
		forgiveness_ready = true
		queue_redraw())
	EventBus.heresy_forgiven.connect(func(pos: Vector2) -> void:
		forgiveness_ready = false
		_seal_blink_left = SEAL_BLINK_TIME
		_cross_left = FORGIVEN_CROSS_TIME
		_cross_at = pos
		queue_redraw())
	EventBus.combo_window_closed.connect(func() -> void:
		combo_partners = PackedStringArray()
		queue_redraw())


func is_combo_ready() -> bool:
	return status == Atril.Status.VALID and combo_partners.has("".join(letters))


func capacity() -> int:
	return GameState.atril_capacity


func slots_rect() -> Rect2:
	var n: int = capacity()
	var w: float = n * SLOT.x + (n - 1) * SLOT_GAP
	return Rect2(Vector2(roundf(CENTER_X - w / 2.0), TOP), Vector2(w, SLOT.y))


func hud_rect() -> Rect2:
	var s: Rect2 = slots_rect()
	var left: float = s.position.x - PLATE_SIDE - 1.0
	return Rect2(left, PLATE_TOP - 1.0, s.end.x + HINTS_GAP + HINTS_RESERVE - left, PLATE_H + 3.0)


func _on_atril_changed(p_letters: PackedStringArray, p_status: int, p_hints: PackedStringArray, p_rare: int) -> void:
	# Durante CAST/PURGE/HERESY mostramos as letras que acabaram de sair.
	if p_letters.is_empty() and not letters.is_empty():
		_last_letters = letters
	letters = p_letters
	status = p_status
	hints = p_hints
	rare_mask = p_rare
	queue_redraw()


func _play(a: Anim) -> void:
	anim = a
	_anim_left = ANIM_TIME[a]
	if a != Anim.REJECT and _last_letters.is_empty():
		_last_letters = letters
	queue_redraw()


func _process(delta: float) -> void:
	if _anim_left > 0.0:
		_anim_left -= delta
		if _anim_left <= 0.0:
			anim = Anim.NONE
			_last_letters = PackedStringArray()
		queue_redraw()
	if _erased_left > 0.0:
		_erased_left -= delta
		queue_redraw()
	if _seal_blink_left > 0.0 or _cross_left > 0.0:
		_seal_blink_left -= delta
		_cross_left -= delta
		queue_redraw()
	if _echo_left > 0.0:
		_echo_left -= delta
		if _echo_left <= 0.0:
			echo_text = ""
		queue_redraw()
	if status == Atril.Status.VALID:
		_pulse += delta
		queue_redraw()


func _draw() -> void:
	var rect: Rect2 = slots_rect()
	UiStyle.draw_plate(self, Rect2(rect.position.x - PLATE_SIDE, PLATE_TOP, rect.size.x + PLATE_SIDE * 2.0, PLATE_H))
	var shake: float = 0.0
	if anim == Anim.HERESY:
		shake = 1.0 if int(_anim_left / 0.06) % 2 == 0 else -1.0
	var frame_color: Color = _frame_color()
	var shown: PackedStringArray = letters
	if anim in [Anim.CAST, Anim.PURGE, Anim.HERESY, Anim.FIZZLE] and letters.is_empty():
		shown = _last_letters
	var valid: bool = status == Atril.Status.VALID and anim == Anim.NONE
	if valid:
		# Palavra pronta: anel externo que pulsa GOLD/GOLD_LIGHT por fora da moldura INK (D-076).
		var pulse: Color = Palette.GOLD if int(_pulse / VALID_PULSE) % 2 == 0 else Palette.GOLD_LIGHT
		_draw_frame(Rect2(rect.position + Vector2(shake, 0), rect.size).grow(2.0), pulse)
	for i: int in capacity():
		var pos := Vector2(rect.position.x + i * (SLOT.x + SLOT_GAP) + shake, rect.position.y)
		var slot := Rect2(pos, SLOT)
		var rare: bool = i < shown.size() and (rare_mask >> i) & 1 == 1 and anim == Anim.NONE
		var bg: Color = Palette.PARCHMENT_OLD
		if anim == Anim.CAST:
			bg = Palette.CHALK
		elif valid or rare:
			bg = Palette.GOLD_LIGHT
		draw_rect(slot.grow(1.0), frame_color)
		draw_rect(slot, bg)
	if echo_text != "":
		_draw_echo(rect)
	for i: int in mini(shown.size(), capacity()):
		var pos := Vector2(rect.position.x + i * (SLOT.x + SLOT_GAP) + shake, rect.position.y)
		var dy: float = 0.0
		if anim == Anim.PURGE:
			dy = (1.0 - _anim_left / ANIM_TIME[Anim.PURGE]) * 6.0
		# Letra sempre INK (GOLD sobre o slot dava 1.38:1, ilegível); o ouro vai para o fundo.
		var color: Color = Palette.INK
		if anim == Anim.HERESY:
			color = Palette.BLOOD
		elif anim == Anim.FIZZLE:
			color = Palette.INK_SOFT if int(_anim_left / FIZZLE_BLINK) % 2 == 0 else Palette.PARCHMENT_OLD
		if anim != Anim.CAST:
			PixelFont.draw(self, shown[i], pos + Vector2(4, 4 + dy), color)
	_draw_forgiveness(rect)
	_draw_erasure(rect)
	if is_combo_ready() and anim == Anim.NONE:
		# Combo pronto: moldura de 2 px (INK por fora, GOLD por dentro).
		_draw_frame(rect.grow(4.0), Palette.INK)
		_draw_frame(rect.grow(3.0), Palette.GOLD)
	if anim == Anim.HERESY:
		PixelFont.draw_centered(self, HERESY_TEXT, CENTER_X, HERESY_Y, Palette.BLOOD)
	_draw_hints(rect)


## Rasura: traço BLOOD na diagonal da última letra (nunca com a palavra pronta) e o rabisco
## INK em zigue-zague no slot apagado.
func _draw_erasure(rect: Rect2) -> void:
	if erasure_warning and not letters.is_empty() and status != Atril.Status.VALID:
		var pos := Vector2(rect.position.x + (letters.size() - 1) * (SLOT.x + SLOT_GAP), rect.position.y)
		# Diagonal em degraus de 2×1 (traço de 1 px de draw_line some).
		for k: int in int(SLOT.x) - 2:
			draw_rect(Rect2(pos + Vector2(1 + k, SLOT.y - 2 - k), Vector2(2, 1)), Palette.BLOOD)
	if _erased_left > 0.0 and _erased_slot >= 0:
		var p := Vector2(rect.position.x + _erased_slot * (SLOT.x + SLOT_GAP), rect.position.y)
		for i: int in 4:
			draw_line(p + Vector2(2 + i * 2, 3), p + Vector2(3 + i * 2, SLOT.y - 3), Palette.INK, 1.0)


func _draw_forgiveness(rect: Rect2) -> void:
	# Selo 7×7: 1 px INK por fora e o miolo 5×5 (GOLD pronto; pisca CHALK ao ser usado).
	var seal := Rect2(rect.position - Vector2(SEAL_SIZE + 5, -1), Vector2(SEAL_SIZE, SEAL_SIZE))
	if forgiveness_ready:
		draw_rect(seal.grow(1.0), Palette.INK)
		draw_rect(seal, Palette.GOLD)
	elif _seal_blink_left > 0.0:
		var phase: int = int((SEAL_BLINK_TIME - _seal_blink_left) / (SEAL_BLINK_TIME / (SEAL_BLINKS * 2)))
		if phase % 2 == 0:
			draw_rect(seal.grow(1.0), Palette.INK)
			draw_rect(seal, Palette.CHALK)
	if _cross_left > 0.0:
		var k: float = 1.0 - _cross_left / FORGIVEN_CROSS_TIME
		var c: Vector2 = (_cross_at - Vector2(0, FORGIVEN_CROSS_ABOVE + FORGIVEN_CROSS_RISE * k)).round()
		# Cruz de braços de 2 px com contorno INK.
		var h_bar := Rect2(c + Vector2(-4, -1), Vector2(8, 2))
		var v_bar := Rect2(c + Vector2(-1, -4), Vector2(2, 8))
		draw_rect(h_bar.grow(1.0), Palette.INK)
		draw_rect(v_bar.grow(1.0), Palette.INK)
		draw_rect(h_bar, Palette.GOLD)
		draw_rect(v_bar, Palette.GOLD)


## Eco do VERBUM: as letras em INK_SOFT sólido, deslocadas, por baixo das letras reais (D-076: o
## xadrez destruía o glifo de 1 px e apagava metade da letra de verdade).
func _draw_echo(rect: Rect2) -> void:
	for i: int in mini(echo_text.length(), capacity()):
		var pos := Vector2(rect.position.x + i * (SLOT.x + SLOT_GAP), rect.position.y)
		PixelFont.draw(self, echo_text[i], pos + Vector2(4, 4) + ECHO_OFFSET, Palette.INK_SOFT)


## Moldura de 1 px com retângulos cheios (pixel exato; a linha do draw_rect vazado cai no meio pixel).
func _draw_frame(r: Rect2, color: Color) -> void:
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), color)
	draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), color)
	draw_rect(Rect2(r.position, Vector2(1, r.size.y)), color)
	draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), color)


func _frame_color() -> Color:
	match anim:
		Anim.HERESY, Anim.REJECT:
			return Palette.BLOOD
		Anim.CAST:
			return Palette.INK
	match status:
		Atril.Status.VALID:
			return Palette.INK
		Atril.Status.PARTIAL:
			return Palette.INK
		Atril.Status.FULL_REJECT:
			return Palette.BLOOD
	return Palette.INK_SOFT


func _draw_hints(rect: Rect2) -> void:
	if hints.is_empty():
		return
	var x: float = rect.end.x + HINTS_GAP
	var y: float = HINTS_TEXT_Y
	var total: float = 0.0
	for h: String in hints:
		total += PixelFont.width(h) + 8
	UiStyle.draw_plate(self, Rect2(x - HINTS_PAD, rect.position.y, total - 8 + HINTS_PAD * 2.0, HINTS_H))
	for i: int in hints.size():
		var first_valid: bool = status == Atril.Status.VALID and i == 0
		var gold: bool = first_valid or combo_partners.has(hints[i])
		if gold:
			# Dica em destaque: texto INK sobre etiqueta GOLD_LIGHT (GOLD em texto dava 2.1:1).
			draw_rect(Rect2(x - 2, y - 2, PixelFont.width(hints[i]) + 4, 10), Palette.GOLD_LIGHT)
		PixelFont.draw(self, hints[i], Vector2(x, y), Palette.INK if gold else Palette.INK_SOFT)
		x += PixelFont.width(hints[i]) + 8
