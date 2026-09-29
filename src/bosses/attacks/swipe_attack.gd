extends BossAttack
## Swipe (006 FR-608): raspadores num arco de `arc_degrees` e alcance `reach` na direção do
## escriba (só sai com ele perto: `max_distance`). Fere fraco.
## Visual (design-agent): telegrafia = arco + 2 bordas radiais em BLOOD tracejado; golpe = faixa
## INK_SOFT de 3 px com fio CHALK na borda externa.

var _aim: float = 0.0
var _origin: Vector2


func _on_begin() -> void:
	_origin = boss.hurt_center()
	_aim = (player_body() - _origin).angle()


func _active_tick(_delta: float) -> void:
	if hit_player:
		return
	var rel: Vector2 = player_body() - _origin
	var r: float = boss.manager.player_hurt_radius
	if rel.length() <= attack.reach + r and absf(angle_difference(_aim, rel.angle())) <= deg_to_rad(attack.arc_degrees) / 2.0:
		hurt_player(attack.damage)


func _draw() -> void:
	if attack == null:
		return
	var half: float = deg_to_rad(attack.arc_degrees) / 2.0
	var a0: float = _aim - half
	var a1: float = _aim + half
	if is_telegraphing():
		if telegraph_on():
			draw_arc(_origin, attack.reach, a0, a1, 24, Palette.BLOOD, 1.0)
			dashed_line(_origin, _origin + Vector2.RIGHT.rotated(a0) * attack.reach, Palette.BLOOD)
			dashed_line(_origin, _origin + Vector2.RIGHT.rotated(a1) * attack.reach, Palette.BLOOD)
	elif is_active():
		draw_arc(_origin, attack.reach - 2.0, a0, a1, 24, Palette.INK_SOFT, 3.0)
		draw_arc(_origin, attack.reach, a0, a1, 24, Palette.CHALK, 1.0)
