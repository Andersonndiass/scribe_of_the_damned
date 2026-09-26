class_name MinimalOverlays
extends CanvasLayer
## Pausa (T077, FR-025) e Game Over (T078, FR-005) mínimos. As telas completas são da feature 007.
## Esc pausa/continua; R reinicia (pausado ou morto). Escurecimento por dithering INK, sem alpha.

signal restart_requested()

const GAME_OVER_DELAY := 0.6
const DITHER_STEP := 2

enum Mode { NONE, PAUSED, GAME_OVER }

var mode: Mode = Mode.NONE

var _canvas: Node2D
var _death_left: float = -1.0


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Node2D.new()
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)
	EventBus.player_died.connect(func() -> void: _death_left = GAME_OVER_DELAY)


func _process(delta: float) -> void:
	if _death_left > 0.0:
		_death_left -= delta
		if _death_left <= 0.0:
			_set_mode(Mode.GAME_OVER)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and mode != Mode.GAME_OVER:
		_set_mode(Mode.NONE if mode == Mode.PAUSED else Mode.PAUSED)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"restart") and mode != Mode.NONE:
		restart()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if mode != Mode.GAME_OVER:
		_set_mode(Mode.NONE if mode == Mode.PAUSED else Mode.PAUSED)


func restart() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	restart_requested.emit()


func _set_mode(m: Mode) -> void:
	mode = m
	get_tree().paused = m == Mode.PAUSED
	_canvas.queue_redraw()


func _on_draw() -> void:
	if mode == Mode.NONE:
		return
	for y: int in range(0, 360, DITHER_STEP):
		for x: int in range((y / DITHER_STEP) % 2 * DITHER_STEP, 640, DITHER_STEP * 2):
			_canvas.draw_rect(Rect2(x, y, DITHER_STEP, DITHER_STEP), Palette.INK)
	var box := Rect2(200, 140, 240, 80)
	_canvas.draw_rect(box.grow(1.0), Palette.INK)
	_canvas.draw_rect(box, Palette.PARCHMENT)
	if mode == Mode.PAUSED:
		PixelFont.draw_centered(_canvas, "PAUSA", 320, 156, Palette.INK, 2)
		PixelFont.draw_centered(_canvas, "ESC CONTINUAR   R REINICIAR", 320, 190, Palette.INK_SOFT)
	else:
		PixelFont.draw_centered(_canvas, "A PÁGINA ARDEU", 320, 156, Palette.BLOOD, 2)
		PixelFont.draw_centered(_canvas, "R TENTAR DE NOVO", 320, 190, Palette.INK_SOFT)
