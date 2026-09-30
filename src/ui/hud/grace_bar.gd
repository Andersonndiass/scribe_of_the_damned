class_name GraceBar
extends Node2D
## Barra de Graça (016 FR-1616; design-agent T1600, animation-agent T1600): etiqueta com o nível e
## barra fina logo abaixo das velas. Morte enche direto; palavra mostra o trecho ganho em CHALK e
## depois o GOLD avança sobre ele; subir de nível pisca CHALK/GOLD (relógio real: o jogo está
## pausado nessa hora).

const RECT := Rect2(8, 28, 108, 10)
const TAG_MIN_W := 17
const BAR_W := 88
const FILL_W := 86

var level: int = 1
var fraction: float = 0.0
var _word_from: float = -1.0
var _word_ms: int = 0
var _flash_ms: int = -100000
var _tuning: GraceTuning


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_tuning = GameState.grace_tuning
	EventBus.grace_changed.connect(_on_changed)
	EventBus.grace_gained.connect(_on_gained)
	EventBus.grace_leveled.connect(func(_l: int, _p: int) -> void: _flash_ms = Time.get_ticks_msec())
	if GameState.grace != null:
		_on_changed(GameState.grace.progress, GameState.grace.needed(), GameState.grace.level)


func hud_rect() -> Rect2:
	return RECT


func _on_gained(_amount: int, source: StringName, _p: Vector2) -> void:
	if source == &"word" or source == &"combo":
		_word_from = fraction
		_word_ms = Time.get_ticks_msec()


func _on_changed(progress: int, needed: int, p_level: int) -> void:
	if p_level != level:
		_word_from = -1.0  # cruzou o nível: o brilho vale
	level = p_level
	fraction = clampf(float(progress) / maxf(1.0, float(needed)), 0.0, 1.0)
	queue_redraw()


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	var word_ms: int = int((_tuning.bar_word_pulse + _tuning.bar_fill_time) * 1000.0)
	if now - _flash_ms < int(_tuning.bar_flash_time * 1000.0) + 50 or (_word_from >= 0.0 and now - _word_ms < word_ms + 50):
		queue_redraw()


func _draw() -> void:
	var now: int = Time.get_ticks_msec()
	var flash_age: float = float(now - _flash_ms) / 1000.0
	var flashing: bool = flash_age >= 0.0 and flash_age < _tuning.bar_flash_time
	# Etiqueta do nível (o número sobe 1 px no brilho).
	var text: String = str(level)
	var tag_w: float = maxf(TAG_MIN_W, PixelFont.width(text) + 6)
	var tag := Rect2(RECT.position, Vector2(tag_w, RECT.size.y))
	draw_rect(tag, Palette.INK)
	draw_rect(tag.grow(-1), Palette.GOLD_LIGHT)
	PixelFont.draw_centered(self, text, tag.get_center().x, 30 - (1 if flashing else 0), Palette.INK)
	# Barra.
	var bx: float = tag.end.x + 2
	var border := Rect2(bx, 30, BAR_W, 6)
	var inner := Rect2(bx + 1, 31, FILL_W, 4)
	var word_age: float = float(now - _word_ms) / 1000.0
	var word_pulse: bool = _word_from >= 0.0 and word_age < _tuning.bar_word_pulse
	draw_rect(border, Palette.GOLD if word_pulse else Palette.INK)
	draw_rect(inner, Palette.PARCHMENT_OLD)
	draw_rect(Rect2(bx + 1, 36, FILL_W, 1), Palette.INK_SOFT)
	if flashing:
		var step: int = int(flash_age / _tuning.bar_flash_step)
		draw_rect(inner, Palette.CHALK if step % 2 == 0 else Palette.GOLD)
		return
	var full: int = floori(FILL_W * fraction)
	var gold: int = full
	if _word_from >= 0.0 and word_age < _tuning.bar_word_pulse + _tuning.bar_fill_time:
		var from_px: int = floori(FILL_W * _word_from)
		var t: float = clampf((word_age - _tuning.bar_word_pulse) / _tuning.bar_fill_time, 0.0, 1.0)
		gold = from_px + floori((full - from_px) * t)
		draw_rect(Rect2(inner.position.x, inner.position.y, full, 4), Palette.CHALK)
	if gold > 0:
		draw_rect(Rect2(inner.position.x, inner.position.y, gold, 4), Palette.GOLD)
		draw_rect(Rect2(inner.position.x, inner.position.y, gold, 1), Palette.GOLD_LIGHT)
