class_name HudComboWindow
extends Node2D
## Janela de combo (002 FR-205, UI_COMBO_WINDOW) e nome do combo (FR-202b, D-045).
##   Barra 48×3 abaixo do atril: cheia enquanto a janela espera a 1ª letra; depois encolhe das
##   bordas para o centro em 12 passos de 4 px durante `duration` s (design-agent, 002).
##   Nome: latim em GOLD com contorno INK, fonte 5×6 em 2×, 16 px acima da cabeça do escriba,
##   por NAME_TIME s e corte seco (sem alpha).

const BAR := Rect2(296, 335, 48, 3)
const STEPS := 12
const NAME_TIME := 1.0
const NAME_SCALE := 2
## Topo da cabeça do Anselmo em relação à origem (pés) + folga de 16 px.
const NAME_ABOVE := 36.0
const OUTLINE_OFFSETS: Array[Vector2] = [
	Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1),
	Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1),
]

var open: bool = false
var started: bool = false
var duration: float = 0.0
var left: float = 0.0
var shown_name: String = ""

var _name_left: float = 0.0


func _ready() -> void:
	EventBus.combo_window_opened.connect(_on_opened)
	EventBus.combo_window_closed.connect(_on_closed)
	EventBus.letter_collected.connect(func(_l: String, _r: bool) -> void:
		if open and not started:
			started = true
			left = duration)
	EventBus.combo_cast.connect(func(combo: ComboData, _p: float) -> void:
		shown_name = combo.display_name
		_name_left = NAME_TIME
		queue_redraw())


## Área fixa do HUD (a barra). O nome é feedback no mundo, sobre o escriba, por 1 s (design-agent).
func hud_rect() -> Rect2:
	return BAR.grow(1.0)


func _on_opened(_word: WordData, p_duration: float, _partners: PackedStringArray) -> void:
	open = true
	started = false
	duration = p_duration
	left = p_duration
	queue_redraw()


func _on_closed() -> void:
	open = false
	started = false
	queue_redraw()


## Largura atual do preenchimento (px), em passos inteiros de BAR.size.x / STEPS.
func fill_width() -> float:
	if not open:
		return 0.0
	var frac: float = clampf(left / duration, 0.0, 1.0) if started and duration > 0.0 else 1.0
	return ceilf(frac * STEPS) * (BAR.size.x / STEPS)


func _process(delta: float) -> void:
	if open and started:
		left = maxf(0.0, left - delta)
		queue_redraw()
	if _name_left > 0.0:
		_name_left -= delta
		if _name_left <= 0.0:
			shown_name = ""
		queue_redraw()


func _draw() -> void:
	if open:
		draw_rect(BAR.grow(1.0), Palette.INK)
		draw_rect(BAR, Palette.INK_SOFT)
		var w: float = fill_width()
		draw_rect(Rect2(roundf(BAR.get_center().x - w / 2.0), BAR.position.y, w, BAR.size.y), Palette.GOLD)
	if shown_name != "":
		var player := get_tree().get_first_node_in_group(&"player") as Node2D
		if player == null:
			return
		var y: float = roundf(player.global_position.y - NAME_ABOVE - PixelFont.height(NAME_SCALE))
		var x: float = player.global_position.x
		for o: Vector2 in OUTLINE_OFFSETS:
			PixelFont.draw_centered(self, shown_name, x + o.x, y + o.y, Palette.INK, NAME_SCALE)
		PixelFont.draw_centered(self, shown_name, x, y, Palette.GOLD, NAME_SCALE)
