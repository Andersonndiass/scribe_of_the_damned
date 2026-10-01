class_name LevelUpBeamView
extends Node2D
## Feixe do nível (018 D-095; animation-agent T1802): um feixe dourado desce do topo da tela até
## os pés do Anselmo (4 degraus de 50 ms), pulsa 16/12 px a cada 200 ms e sai em 12/8/4 px; acima
## da cabeça, uma barra 25×3 que esvazia em degraus de 100 ms mostra quanto falta da câmera lenta
## (pisca GOLD/CHALK no fim, sem alpha). Borda GOLD, miolo GOLD_LIGHT, filete CHALK (a Graça é
## dourada). Tudo no relógio do GraceFlow (`beam_t`), que desconta a câmera lenta e o hit-stop.

## Altura do Anselmo acima dos pés (topo da cabeça) e o pé do feixe.
const HEAD := 16.0
const BORDER := 2
const CORE_WIDE := 4
const CORE_NARROW := 2

var flow: GraceFlow


func _ready() -> void:
	pass  # na camada de efeitos do Main (origem 0,0): atrás do escriba e dos inimigos, sobre a página


func _process(_delta: float) -> void:
	var on: bool = flow != null and flow.phase == GraceFlow.Phase.BEAM and flow.player != null
	visible = on
	if on:
		queue_redraw()


func _draw() -> void:
	var t: GraceTuning = flow.tuning
	var feet: Vector2 = flow.player.global_position.round()
	var top_y: float = (get_viewport().get_canvas_transform().affine_inverse() * Vector2.ZERO).y
	var total: float = t.levelup_slow_time
	var bt: float = flow.beam_t
	# Largura e alcance do feixe.
	var enter_time: float = t.beam_enter_step * t.beam_enter_steps
	var exit_time: float = t.beam_exit_step * t.beam_exit_widths.size()
	var reach: float = 1.0
	var width: int = t.beam_width
	if bt < enter_time:
		reach = float(int(bt / t.beam_enter_step) + 1) / float(t.beam_enter_steps)
	elif bt >= total - exit_time:
		var k: int = mini(int((bt - (total - exit_time)) / t.beam_exit_step), t.beam_exit_widths.size() - 1)
		width = t.beam_exit_widths[k]
	elif int((bt - enter_time) / t.beam_pulse_step) % 2 == 1:
		width = t.beam_width_narrow
	var height: float = roundf((feet.y - top_y) * reach)
	var x0: float = feet.x - floorf(width / 2.0)
	var rect := Rect2(x0, top_y, width, height)
	draw_rect(rect, Palette.GOLD)
	if width > BORDER * 2:
		draw_rect(rect.grow_individual(-BORDER, 0, -BORDER, 0), Palette.GOLD_LIGHT)
	var core: int = CORE_WIDE if width >= t.beam_width else CORE_NARROW
	if width > core + BORDER * 2:
		draw_rect(Rect2(feet.x - core / 2, top_y, core, height), Palette.CHALK)
	# Flash no Anselmo quando o feixe chega (q3).
	if bt >= enter_time - t.beam_enter_step and bt < enter_time - t.beam_enter_step + t.beam_flash:
		draw_rect(Rect2(feet.x - 6, feet.y - HEAD, 12, HEAD), Palette.CHALK)
	_draw_bar(t, feet, total, bt)


## Barra acima da cabeça: 25 degraus de 100 ms, esvazia da direita para a esquerda.
func _draw_bar(t: GraceTuning, feet: Vector2, total: float, bt: float) -> void:
	var left: float = maxf(total - bt, 0.0)
	var steps: float = ceilf(left / t.levelup_bar_step)
	var full_steps: float = ceilf(total / t.levelup_bar_step)
	var w: int = t.levelup_bar_width
	var fill_w: int = int(roundf(w * steps / maxf(full_steps, 1.0)))
	var r := Rect2(feet.x - floorf(w / 2.0) - 1, feet.y - HEAD - t.levelup_bar_offset_y - t.levelup_bar_height - 2, w + 2, t.levelup_bar_height + 2)
	var color: Color = Palette.GOLD
	if left <= t.levelup_bar_blink_time:
		var period: float = t.levelup_bar_blink_fast_step if left <= t.levelup_bar_blink_fast_time else t.levelup_bar_blink_step
		if int(left / period) % 2 == 1:
			color = Palette.CHALK
	UiStyle.draw_bar(self, r, float(fill_w) / float(w), Palette.PARCHMENT_OLD, color)
