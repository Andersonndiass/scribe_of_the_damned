extends Miracle
## GLORIA — por `duration` s, o dano (e a cura) dos milagres e combos sai × buff_mul
## (002 FR-209). Não escala limiar, stun nem duração. Reconjurar renova (PlayerBuffs).
## Visual (design-agent): 2 colchetes GOLD 3×1 nos pés (y +13 do corpo), um de cada lado,
## pulsando 1 px a cada 0.25 s; piscam nos últimos 1.5 s. GOLD parado no chão ≠ LUMEN.

const FEET_Y := 1.0
const HALF_GAP := 6.0
const PULSE := 0.25
const BLINK_WINDOW := 1.5

var _player: Player


func _on_start() -> void:
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player != null:
		_player.buffs.apply_gloria(word.duration, word.buff_mul)
	_follow()
	queue_redraw()


func _process(_delta: float) -> void:
	if _player == null or _player.buffs.gloria_left <= 0.0:
		finish()
		return
	_follow()
	var left: float = _player.buffs.gloria_left
	visible = left > BLINK_WINDOW or int(left / 0.1) % 2 == 0
	queue_redraw()


func _follow() -> void:
	if _player != null:
		global_position = _player.global_position.round()


func _draw() -> void:
	var out: float = float(int(Time.get_ticks_msec() / 1000.0 / PULSE) % 2)
	for side: float in [-1.0, 1.0]:
		var x: float = side * (HALF_GAP + out)
		draw_rect(Rect2(Vector2(x - 1.0 if side > 0.0 else x - 2.0, FEET_Y), Vector2(3, 1)), Palette.GOLD)
