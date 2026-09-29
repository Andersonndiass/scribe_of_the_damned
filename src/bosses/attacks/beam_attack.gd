extends BossAttack
## Raio e Raio duplo (006 FR-608): `lines` linhas retas pela tela inteira, a partir do chefe, com a
## mira travada no escriba no começo da telegrafia; `angle_offset_degrees` abre as linhas (±20°).
## Golpe (design-agent): faixa INK de `width` px com bordas PARCHMENT_OLD em dither e núcleo CHALK 2 px.

const REACH := 800.0

var _dirs: Array[Vector2] = []
var _origin: Vector2


func _on_begin() -> void:
	_origin = boss.hurt_center()
	var aim: Vector2 = (player_body() - _origin).normalized()
	if aim.is_zero_approx():
		aim = Vector2.DOWN
	_dirs.clear()
	if attack.lines <= 1:
		_dirs.append(aim)
	else:
		for i: int in attack.lines:
			var t: float = float(i) / float(attack.lines - 1) * 2.0 - 1.0
			_dirs.append(aim.rotated(deg_to_rad(attack.angle_offset_degrees) * t))


func _active_tick(_delta: float) -> void:
	if hit_player:
		return
	var body: Vector2 = player_body()
	for d: Vector2 in _dirs:
		if distance_to_segment(body, _origin, _origin + d * REACH) <= attack.width / 2.0 + boss.manager.player_hurt_radius:
			hurt_player(attack.damage)
			return


func _draw() -> void:
	if attack == null:
		return
	var half: float = attack.width / 2.0
	for d: Vector2 in _dirs:
		var n: Vector2 = d.orthogonal() * half
		var end: Vector2 = _origin + d * REACH
		if is_telegraphing():
			if telegraph_on():
				dashed_line(_origin + n, end + n, Palette.BLOOD)
				dashed_line(_origin - n, end - n, Palette.BLOOD)
		elif is_active():
			draw_line(_origin, end, Palette.PARCHMENT_OLD, attack.width + 2.0)
			draw_line(_origin, end, Palette.INK, attack.width)
			draw_line(_origin, end, Palette.CHALK, 2.0)
