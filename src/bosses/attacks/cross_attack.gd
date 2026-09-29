extends BossAttack
## Cruz giratória (006 FR-608, F3): `arms` braços de `reach` × `width` px girando a
## `turn_degrees_per_s` em volta do chefe por `duration` s. Fere forte (os i-frames do escriba
## evitam o golpe repetido). Visual (design-agent): telegrafia = contorno dos braços + seta na ponta
## (sentido do giro); golpe = braços INK cheios com núcleo CHALK 2 px.

var _origin: Vector2
var _angle: float = 0.0


func _on_begin() -> void:
	_origin = boss.hurt_center()
	_angle = (player_body() - _origin).angle() + PI / float(maxi(1, attack.arms))


func _active_tick(delta: float) -> void:
	_angle += deg_to_rad(attack.turn_degrees_per_s) * delta
	var body: Vector2 = player_body()
	var reach: float = attack.width / 2.0 + boss.manager.player_hurt_radius
	for i: int in attack.arms:
		var d: Vector2 = Vector2.RIGHT.rotated(_angle + TAU * i / attack.arms)
		if distance_to_segment(body, _origin, _origin + d * attack.reach) <= reach:
			hurt_player(attack.damage)
			return


func _draw() -> void:
	if attack == null:
		return
	for i: int in attack.arms:
		var d: Vector2 = Vector2.RIGHT.rotated(_angle + TAU * i / attack.arms)
		var end: Vector2 = _origin + d * attack.reach
		var n: Vector2 = d.orthogonal() * attack.width / 2.0
		if is_telegraphing():
			if telegraph_on():
				dashed_line(_origin + n, end + n, Palette.BLOOD)
				dashed_line(_origin - n, end - n, Palette.BLOOD)
				var tip: Vector2 = end + d.orthogonal() * 3.0
				draw_line(end.round(), tip.round(), Palette.BLOOD, 1.0)
		elif is_active():
			draw_line(_origin, end, Palette.INK, attack.width)
			draw_line(_origin, end, Palette.CHALK, 2.0)
