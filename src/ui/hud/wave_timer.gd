class_name HudWaveTimer
extends Node2D
## Tempo restante e "Onda N" no topo central (T075, ficha 26). Fica acima de Y 60.
## T1800: painel B; com a etiqueta de fim de onda, o painel alarga até o texto + 8, centrado.

const CENTER_X := 320.0
const PLATE := Rect2(292, 7, 56, 25)
const WAVE_Y := 10.0
const TIME_Y := 18.0
const DONE_Y := 16.0
const DONE_PAD := 8.0

var remaining: float = 0.0
var wave_index: int = 0
var running: bool = false
var chapter_done: bool = false
var _shown_seconds: int = -1


func hud_rect() -> Rect2:
	return Rect2(260, 6, 120, 28)


func _ready() -> void:
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_ended.connect(_on_wave_ended)
	# Na luta contra o chefe (006) o cronômetro da onda sai: a barra do chefe ocupa o topo.
	EventBus.boss_spawned.connect(func(_b: BossData) -> void: visible = false)
	EventBus.wave_started.connect(func(_i: int, _d: float) -> void: visible = true)
	EventBus.chapter_completed.connect(func(_c: int) -> void:
		chapter_done = true
		queue_redraw())


func _on_wave_started(index: int, duration: float) -> void:
	wave_index = index
	remaining = duration
	running = true
	queue_redraw()


func _on_wave_ended(_index: int) -> void:
	running = false
	remaining = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if not running:
		return
	remaining = maxf(0.0, remaining - delta)
	var s: int = ceili(remaining)
	if s != _shown_seconds:
		_shown_seconds = s
		queue_redraw()


func time_text() -> String:
	var s: int = ceili(remaining)
	return "%d:%02d" % [s / 60, s % 60]


func _draw() -> void:
	if wave_index == 0:
		return
	if not running:
		var done: String = tr(&"HUD_CHAPTER_COMPLETE") if chapter_done else tr(&"HUD_WAVE_COMPLETE")
		var w: float = maxf(PLATE.size.x, PixelFont.width(done) + DONE_PAD)
		UiStyle.draw_plate(self, Rect2(roundf(CENTER_X - w / 2.0), PLATE.position.y, w, PLATE.size.y))
		PixelFont.draw_centered(self, done, CENTER_X, DONE_Y, Palette.INK)
		return
	UiStyle.draw_plate(self, PLATE)
	PixelFont.draw_centered(self, tr(&"HUD_WAVE").format({"n": wave_index}), CENTER_X, WAVE_Y, Palette.INK_SOFT)
	var urgent: bool = remaining <= 10.0
	PixelFont.draw_centered(self, time_text(), CENTER_X, TIME_Y, Palette.BLOOD if urgent else Palette.INK, 2)
