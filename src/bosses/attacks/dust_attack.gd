extends BossAttack
## Dust_Cloud (012 FR-1209; T1200 §4): nuvem de pó que cai no ponto do escriba (travado na
## telegrafia), círculo de `radius`. Na queda fere `damage` quem está dentro e deixa a poça
## `hazard` (lentidão; não soma com o Borrão: o HazardField usa o mínimo).
## Visual: telegrafia = círculo BLOOD tracejado; golpe = disco INK_SOFT pontilhado.

var _center: Vector2


func _on_begin() -> void:
	_center = player_body()


func _on_activate() -> void:
	if player_body().distance_to(_center) <= attack.radius + boss.manager.player_hurt_radius:
		hurt_player(attack.damage)
	var hz: HazardField = boss.manager.get_hazards()
	if attack.hazard != null and hz != null:
		hz.add_puddle(attack.hazard, _center)


func _draw() -> void:
	if attack == null:
		return
	if is_telegraphing():
		if telegraph_on():
			for k: int in 16:
				if k % 2 == 0:
					draw_arc(_center, attack.radius, TAU * k / 16.0, TAU * (k + 1) / 16.0, 3, Palette.BLOOD, 1.0)
	elif is_active():
		UiStyle.dither(self, Rect2(_center - Vector2.ONE * attack.radius * 0.7, Vector2.ONE * attack.radius * 1.4), Palette.INK_SOFT, 0.5)
