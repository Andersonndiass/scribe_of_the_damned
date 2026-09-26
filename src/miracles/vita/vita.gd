extends Miracle
## VITA — acende velas (FR-021). Usa: heal_candles. Não escala com power: vela é inteira.
## Visual placeholder: 6 faíscas CHALK/GOLD subindo em 0.5s.

const TIME := 0.5
const SPARKS := 6

var _t: float = 0.0


func _on_start() -> void:
	_t = 0.0
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player != null:
		player.heal(word.heal_candles)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= TIME:
		finish()


func _draw() -> void:
	var rise: float = _t / TIME * 16.0
	for i: int in SPARKS:
		var x: float = (i - SPARKS / 2.0) * 3.0
		var y: float = -rise - float(i % 3) * 3.0
		draw_rect(Rect2(x, y, 1, 1), Palette.GOLD if i % 2 == 0 else Palette.CHALK)
