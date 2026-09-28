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
const HINTS_GAP := 12
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
	return Rect2(s.position - Vector2(0, 12), Vector2(s.size.x + HINTS_GAP + 120, s.size.y + 12))


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
	var shake: float = 0.0
	if anim == Anim.HERESY:
		shake = 1.0 if int(_anim_left / 0.06) % 2 == 0 else -1.0
	var frame_color: Color = _frame_color()
	var shown: PackedStringArray = letters
	if anim in [Anim.CAST, Anim.PURGE, Anim.HERESY, Anim.FIZZLE] and letters.is_empty():
		shown = _last_letters
	for i: int in capacity():
		var pos := Vector2(rect.position.x + i * (SLOT.x + SLOT_GAP) + shake, rect.position.y)
		var slot := Rect2(pos, SLOT)
		draw_rect(slot.grow(1.0), frame_color)
		draw_rect(slot, Palette.PARCHMENT_OLD if anim != Anim.CAST else Palette.CHALK)
		if i < shown.size():
			var dy: float = 0.0
			if anim == Anim.PURGE:
				dy = (1.0 - _anim_left / ANIM_TIME[Anim.PURGE]) * 6.0
			var rare: bool = (rare_mask >> i) & 1 == 1 and anim == Anim.NONE
			var color: Color = Palette.GOLD if (rare or status == Atril.Status.VALID) else Palette.INK
			if anim == Anim.HERESY:
				color = Palette.BLOOD
			elif anim == Anim.FIZZLE:
				color = Palette.INK_SOFT if int(_anim_left / FIZZLE_BLINK) % 2 == 0 else Palette.PARCHMENT_OLD
			if anim != Anim.CAST:
				PixelFont.draw(self, shown[i], pos + Vector2(4, 4 + dy), color)
	if echo_text != "":
		_draw_echo(rect)
	_draw_forgiveness(rect)
	if is_combo_ready() and anim == Anim.NONE:
		_draw_frame(rect.grow(3.0), frame_color)
	if anim == Anim.HERESY:
		PixelFont.draw_centered(self, HERESY_TEXT, CENTER_X, rect.position.y - 10, Palette.BLOOD)
	_draw_hints(rect)


func _draw_forgiveness(rect: Rect2) -> void:
	var seal := Rect2(rect.position - Vector2(SEAL_SIZE + 4, 0), Vector2(SEAL_SIZE, SEAL_SIZE))
	if forgiveness_ready:
		draw_rect(seal, Palette.GOLD)
	elif _seal_blink_left > 0.0:
		var phase: int = int((SEAL_BLINK_TIME - _seal_blink_left) / (SEAL_BLINK_TIME / (SEAL_BLINKS * 2)))
		if phase % 2 == 0:
			draw_rect(seal, Palette.CHALK)
	if _cross_left > 0.0:
		var k: float = 1.0 - _cross_left / FORGIVEN_CROSS_TIME
		var c: Vector2 = (_cross_at - Vector2(0, FORGIVEN_CROSS_ABOVE + FORGIVEN_CROSS_RISE * k)).round()
		draw_rect(Rect2(c + Vector2(-3, 0), Vector2(7, 1)), Palette.GOLD)
		draw_rect(Rect2(c + Vector2(0, -3), Vector2(1, 7)), Palette.GOLD)


## Fantasma do VERBUM: as letras em INK_SOFT deslocadas, com metade dos pixels cobertos pelo
## fundo do slot em xadrez (dithering 50%, Princípio VII: sem alpha).
func _draw_echo(rect: Rect2) -> void:
	var bg: Color = Palette.CHALK if anim == Anim.CAST else Palette.PARCHMENT_OLD
	for i: int in mini(echo_text.length(), capacity()):
		var pos := Vector2(rect.position.x + i * (SLOT.x + SLOT_GAP), rect.position.y)
		PixelFont.draw(self, echo_text[i], pos + Vector2(4, 4) + ECHO_OFFSET, Palette.INK_SOFT)
		for y: int in int(SLOT.y):
			for x: int in range(y % 2, int(SLOT.x), 2):
				draw_rect(Rect2(pos + Vector2(x, y), Vector2.ONE), bg)


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
			return Palette.GOLD_LIGHT
	match status:
		Atril.Status.VALID:
			return Palette.GOLD if int(_pulse / VALID_PULSE) % 2 == 0 else Palette.GOLD_LIGHT
		Atril.Status.PARTIAL:
			return Palette.INK
		Atril.Status.FULL_REJECT:
			return Palette.BLOOD
	return Palette.INK_SOFT


func _draw_hints(rect: Rect2) -> void:
	var x: float = rect.end.x + HINTS_GAP
	var y: float = rect.position.y + 4
	for i: int in hints.size():
		var first_valid: bool = status == Atril.Status.VALID and i == 0
		var color: Color = Palette.GOLD if (first_valid or combo_partners.has(hints[i])) else Palette.INK_SOFT
		PixelFont.draw(self, hints[i], Vector2(x, y), color)
		x += PixelFont.width(hints[i]) + 8
