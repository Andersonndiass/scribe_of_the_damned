class_name HudComboWindow
extends Node2D
## Nome do combo (FR-202b, D-045): latim em GOLD com contorno INK, fonte 5×6 em 2×, 16 px acima da
## cabeça do escriba, por NAME_TIME s e corte seco (sem alpha). D-099: a barra da janela de 2,5 s
## saiu (o combo vem da palavra guardada).

const NAME_TIME := 1.0
const NAME_SCALE := 2
## Topo da cabeça do Anselmo em relação à origem (pés) + folga de 16 px.
const NAME_ABOVE := 36.0
const OUTLINE_OFFSETS: Array[Vector2] = [
	Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1),
	Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1),
]

var shown_name: String = ""
var _name_left: float = 0.0


func _ready() -> void:
	EventBus.combo_cast.connect(func(combo: ComboData, _p: float) -> void:
		shown_name = combo.display_name
		_name_left = NAME_TIME
		queue_redraw())


## Sem área fixa no HUD: o nome é feedback no mundo, sobre o escriba, por 1 s.
func hud_rect() -> Rect2:
	return Rect2()


func _process(delta: float) -> void:
	if _name_left > 0.0:
		_name_left -= delta
		if _name_left <= 0.0:
			shown_name = ""
		queue_redraw()


func _draw() -> void:
	if shown_name == "":
		return
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return
	var y: float = roundf(player.global_position.y - NAME_ABOVE - PixelFont.height(NAME_SCALE))
	var x: float = player.global_position.x
	for o: Vector2 in OUTLINE_OFFSETS:
		PixelFont.draw_centered(self, shown_name, x + o.x, y + o.y, Palette.INK, NAME_SCALE)
	PixelFont.draw_centered(self, shown_name, x, y, Palette.GOLD, NAME_SCALE)
