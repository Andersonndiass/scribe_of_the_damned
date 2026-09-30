class_name GraceBar
extends Node2D
## Barra de Graça (016 FR-1616; design-agent T1600, animation-agent T1600): etiqueta com o nível e
## barra fina logo abaixo das velas. Morte enche direto; palavra mostra o trecho ganho em CHALK e
## depois o GOLD avança sobre ele; subir de nível pisca CHALK/GOLD (relógio real: o jogo está
## pausado nessa hora).

## T1800 (design-agent): dentro do painel A. Etiqueta do nível à esquerda; barra de moldura INK,
## trilho INK_SOFT (3,4:1 contra o GOLD) e 10 segmentos de 5 px.
const RECT := Rect2(10, 29, 78, 9)
const TAG := Rect2(10, 29, 15, 9)
const BAR := Rect2(27, 30, 61, 7)
const SEG := 6
const TEXT_Y := 31

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
	draw_rect(TAG, Palette.INK)
	draw_rect(TAG.grow(-1), Palette.GOLD_LIGHT)
	PixelFont.draw_centered(self, str(level), TAG.get_center().x, TEXT_Y - (1 if flashing else 0), Palette.INK)
	# Barra: moldura (GOLD no pulso da palavra), trilho escuro, preenchimento GOLD e segmentos.
	var word_age: float = float(now - _word_ms) / 1000.0
	var word_pulse: bool = _word_from >= 0.0 and word_age < _tuning.bar_word_pulse
	var frame: Color = Palette.GOLD if word_pulse else Palette.INK
	if flashing:
		var step: int = int(flash_age / _tuning.bar_flash_step)
		UiStyle.draw_bar(self, BAR, 1.0, Palette.INK_SOFT, Palette.CHALK if step % 2 == 0 else Palette.GOLD, null, SEG, frame)
		return
	var inner: Rect2 = UiStyle.draw_bar(self, BAR, 0.0, Palette.INK_SOFT, Palette.GOLD, null, 0, frame)
	var full: int = floori(inner.size.x * fraction)
	var gold: int = full
	if _word_from >= 0.0 and word_age < _tuning.bar_word_pulse + _tuning.bar_fill_time:
		var from_px: int = floori(inner.size.x * _word_from)
		var t: float = clampf((word_age - _tuning.bar_word_pulse) / _tuning.bar_fill_time, 0.0, 1.0)
		gold = from_px + floori((full - from_px) * t)
		draw_rect(Rect2(inner.position, Vector2(full, inner.size.y)), Palette.CHALK)
	if gold > 0:
		draw_rect(Rect2(inner.position, Vector2(gold, inner.size.y)), Palette.GOLD)
		draw_rect(Rect2(inner.position, Vector2(gold, 1)), Palette.GOLD_LIGHT)
	var x: float = inner.position.x + SEG - 1
	while x < inner.end.x - 1:
		draw_rect(Rect2(x, inner.position.y, 1, inner.size.y), Palette.INK)
		x += SEG
