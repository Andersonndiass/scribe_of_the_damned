extends Miracle
## LUMEN — por `duration` s, a chance de letra dos inimigos multiplicada (017 D-087 item 8; antes
## era o ímã, que saiu com as letras do chão). Usa: duration, letter_chance_mul. Reconjurar renova.
## Visual (design-agent): 4 pontos CHALK de 1 px em órbita (raio 14, 1 volta / 1.2 s) no corpo;
## piscam em passos de 0.1 s nos últimos 2 s. A fase vem do relógio: duas instâncias coincidem.

const BODY := Vector2(0, -10)
const ORBIT_RADIUS := 14.0
const ORBIT_PERIOD := 1.2
const POINTS := 4
const BLINK_WINDOW := 2.0

var _player: Player


func _on_start() -> void:
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player != null:
		_player.buffs.apply_lumen(word.duration, word.letter_chance_mul)
	_follow()
	queue_redraw()


func _process(_delta: float) -> void:
	if _player == null or _player.buffs.lumen_left <= 0.0:
		finish()
		return
	_follow()
	var left: float = _player.buffs.lumen_left
	visible = left > BLINK_WINDOW or int(left / 0.1) % 2 == 0
	queue_redraw()


func _follow() -> void:
	if _player != null:
		global_position = _player.global_position.round()


func _draw() -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	for k: int in POINTS:
		var a: float = TAU * (t / ORBIT_PERIOD + float(k) / POINTS)
		draw_rect(Rect2((BODY + Vector2.RIGHT.rotated(a) * ORBIT_RADIUS).round(), Vector2.ONE), Palette.CHALK)
