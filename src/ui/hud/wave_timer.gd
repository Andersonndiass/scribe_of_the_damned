class_name HudWaveTimer
extends Node2D
## Tempo restante e "Onda N" no topo central (T075, ficha 26). Fica acima de Y 60.

const CENTER_X := 320.0
const TOP := 6.0

var remaining: float = 0.0
var wave_index: int = 0
var running: bool = false
var chapter_done: bool = false
var _shown_seconds: int = -1


func hud_rect() -> Rect2:
	return Rect2(CENTER_X - 45, TOP, 90, 26)


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
		UiStyle.draw_tag(self, tr(&"HUD_CHAPTER_COMPLETE") if chapter_done else tr(&"HUD_WAVE_COMPLETE"), CENTER_X, TOP + 4)
		return
	PixelFont.draw_centered(self, tr(&"HUD_WAVE").format({"n": wave_index}), CENTER_X, TOP, Palette.INK_SOFT)
	var urgent: bool = remaining <= 10.0
	PixelFont.draw_centered(self, time_text(), CENTER_X, TOP + 10, Palette.BLOOD if urgent else Palette.INK, 2)
