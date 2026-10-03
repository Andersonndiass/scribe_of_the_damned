extends BossAttack
## Wing_Gust (012 FR-1209; T1200 §4): rajada das asas num cone de `arc_degrees` e alcance `reach`,
## mirado no escriba no começo da telegrafia. No golpe: fere `damage` e empurra o escriba `push` px
## para longe da Mãe em `push_time` s (as paredes e as peças seguram: é velocidade, não teleporte).
## Visual: telegrafia = arco e bordas BLOOD tracejados (como o Swipe); golpe = 3 riscos de vento CHALK.

const WIND_LINES := 3

var _aim: float = 0.0
var _origin: Vector2


func _on_begin() -> void:
	_origin = boss.hurt_center()
	_aim = (player_body() - _origin).angle()


func in_cone(p: Vector2) -> bool:
	var rel: Vector2 = p - _origin
	var r: float = boss.manager.player_hurt_radius
	return rel.length() <= attack.reach + r and absf(angle_difference(_aim, rel.angle())) <= deg_to_rad(attack.arc_degrees) / 2.0


func _active_tick(_delta: float) -> void:
	if hit_player or not in_cone(player_body()):
		return
	hurt_player(attack.damage)
	if boss.player != null and attack.push > 0.0:
		var dir: Vector2 = (player_body() - _origin).normalized()
		boss.player.shove(dir * attack.push / maxf(attack.push_time, 0.01), attack.push_time)


func _draw() -> void:
	if attack == null:
		return
	var half: float = deg_to_rad(attack.arc_degrees) / 2.0
	if is_telegraphing():
		if telegraph_on():
			draw_arc(_origin, attack.reach, _aim - half, _aim + half, 24, Palette.BLOOD, 1.0)
			dashed_line(_origin, _origin + Vector2.RIGHT.rotated(_aim - half) * attack.reach, Palette.BLOOD)
			dashed_line(_origin, _origin + Vector2.RIGHT.rotated(_aim + half) * attack.reach, Palette.BLOOD)
	elif is_active():
		var grow: float = clampf(_t / maxf(attack.active, 0.01), 0.0, 1.0)
		for k: int in WIND_LINES:
			var a: float = _aim + half * (float(k) / (WIND_LINES - 1) * 2.0 - 1.0) * 0.6
			var p0: Vector2 = _origin + Vector2.RIGHT.rotated(a) * attack.reach * 0.3 * grow
			var p1: Vector2 = _origin + Vector2.RIGHT.rotated(a) * attack.reach * grow
			draw_line(p0.round(), p1.round(), Palette.CHALK, 1.0)
