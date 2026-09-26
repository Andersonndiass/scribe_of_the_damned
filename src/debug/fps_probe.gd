class_name FpsProbe
extends CanvasLayer
## DEBUG (T080/T084/T085): mede FPS médio e p95 durante `duration` s (depois de `warmup` s) e o
## custo por seção via Prof. Imprime uma linha "FPS_PROBE ..." (vai para o console do navegador).
## p95 = FPS do frame no percentil 95 de duração (95% dos frames foram pelo menos tão rápidos).

signal finished(result: Dictionary)

@export var warmup: float = 3.0
@export var duration: float = 30.0

var result: Dictionary = {}
var counts_provider: Callable

var _elapsed: float = 0.0
var _deltas := PackedFloat32Array()
var _canvas: Node2D
var _last_us: int = 0


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Node2D.new()
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)
	Prof.enabled = true
	Prof.reset()
	_last_us = Time.get_ticks_usec()


func _process(_delta: float) -> void:
	# Tempo real entre frames (não depende de time_scale nem do limite de delta do motor).
	var now: int = Time.get_ticks_usec()
	var real_dt: float = float(now - _last_us) / 1_000_000.0
	_last_us = now
	Prof.end_frame()
	if not result.is_empty():
		return
	_elapsed += real_dt
	if _elapsed < warmup:
		Prof.reset()
		return
	_deltas.append(real_dt)
	if _elapsed >= warmup + duration:
		_finish()
	elif _deltas.size() % 30 == 0:
		_canvas.queue_redraw()


func _finish() -> void:
	var sorted: PackedFloat32Array = _deltas.duplicate()
	sorted.sort()
	var total: float = 0.0
	for d: float in _deltas:
		total += d
	var p95_dt: float = sorted[int(floor(0.95 * (sorted.size() - 1)))]
	result = {
		"frames": _deltas.size(),
		"avg_fps": _deltas.size() / total,
		"p95_fps": 1.0 / p95_dt,
		"worst_ms": sorted[sorted.size() - 1] * 1000.0,
		"prof": Prof.report(),
		"counts": counts_provider.call() if counts_provider.is_valid() else {},
		"platform": OS.get_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
	}
	var costs: PackedStringArray = []
	for c: Dictionary in result["prof"]:
		costs.append("%s=%.0fus" % [c["key"], c["us"]])
	print("FPS_PROBE avg=%.1f p95=%.1f worst_ms=%.1f frames=%d counts=%s custos: %s" % [
		result["avg_fps"], result["p95_fps"], result["worst_ms"], result["frames"],
		result["counts"], ", ".join(costs)])
	_canvas.queue_redraw()
	if OS.has_feature("web"):
		# Qualquer navegador (inclusive o Firefox, sem CDP): o resultado vai numa requisição ao
		# servidor local, que registra a URL no log.
		JavaScriptBridge.eval("fetch('/fps_result?' + encodeURIComponent(%s)).catch(function(){})" % JSON.stringify(
			"avg=%.1f p95=%.1f worst_ms=%.1f custos: %s" % [
				result["avg_fps"], result["p95_fps"], result["worst_ms"], ", ".join(costs)]))
	finished.emit(result)


func _on_draw() -> void:
	_canvas.draw_rect(Rect2(8, 44, 150, 20), Palette.PARCHMENT)
	if result.is_empty():
		var fps: float = Engine.get_frames_per_second()
		PixelFont.draw(_canvas, "STRESS %.0f FPS" % fps, Vector2(12, 48), Palette.INK)
		PixelFont.draw(_canvas, "MEDINDO %.0fS" % maxf(0.0, warmup + duration - _elapsed), Vector2(12, 56), Palette.INK_SOFT)
	else:
		PixelFont.draw(_canvas, "MEDIA %.0f  P95 %.0f" % [result["avg_fps"], result["p95_fps"]], Vector2(12, 48), Palette.INK)
		PixelFont.draw(_canvas, "FIM", Vector2(12, 56), Palette.INK_SOFT)
