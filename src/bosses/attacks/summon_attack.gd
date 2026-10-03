extends BossAttack
## Summon (006 FR-608, F2+): `summon_count` inimigos em anel de `radius` px em volta do chefe,
## até `summon_max_alive` vivos. Usa os slots do EnemyManager (sem instantiate). Os Diabretes
## soltam letras normalmente (fonte principal de letras nas F2–F3).
## Visual (design-agent): anel de 20 px em cada ponto de nascimento, traços girando 1 px/quadro.

const MARK_RADIUS := 10.0

var _points: Array[Vector2] = []


func _on_begin() -> void:
	_points.clear()
	var center: Vector2 = boss.hurt_center()
	for i: int in attack.summon_count:
		var p: Vector2 = center + Vector2.RIGHT.rotated(TAU * i / maxf(1.0, attack.summon_count)) * (attack.radius + boss.data.body_radius)
		p = p.clamp(PlayArea.rect.position, PlayArea.rect.end)
		if attack.summon_enemy != null:
			# O anel mostra onde o Diabrete nasce de fato: fora das peças (004 FR-411).
			p = ObstacleQuery.spawn_point(p, attack.summon_enemy.radius)
		_points.append(p)


func _on_activate() -> void:
	var em: EnemyManager = boss.manager
	for p: Vector2 in _points:
		if attack.summon_enemy == null or em.count_of(attack.summon_enemy) >= attack.summon_max_alive:
			break
		em.spawn(attack.summon_enemy, p)


func _draw() -> void:
	if not is_telegraphing():
		return
	var spin: int = int(_t * 60.0)
	for p: Vector2 in _points:
		for k: int in 8:
			var a: float = TAU * k / 8.0 + spin * 0.1
			if k % 2 == 0:
				draw_line((p + Vector2.RIGHT.rotated(a) * MARK_RADIUS).round(), (p + Vector2.RIGHT.rotated(a + 0.3) * MARK_RADIUS).round(), Palette.BLOOD, 1.0)
