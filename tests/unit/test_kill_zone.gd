extends GutTest
## D-084 KillZone: forma (linha, círculo, cruz girada, tela com anel), FSM com drenagem, golpe no
## campeão (fração × multiplicador ou fixo) e reuso.


func _zone(shape: KillZone.Shape) -> KillZone:
	var z := KillZone.new()
	z.open(shape, 1.0)
	z.origin = Vector2(100, 100)
	return z


func test_line_counts_the_enemy_radius_and_the_ends() -> void:
	var z := _zone(KillZone.Shape.LINE)
	z.dir = Vector2.RIGHT
	z.length = 100
	z.width = 10
	assert_true(z.contains(Vector2(150, 100), 3))
	assert_true(z.contains(Vector2(150, 107), 3), "meia largura + raio")
	assert_false(z.contains(Vector2(150, 110), 3))
	assert_true(z.contains(Vector2(203, 100), 3), "a ponta conta com o raio")
	assert_false(z.contains(Vector2(90, 100), 3), "atrás da origem, não")


func test_circle_and_cross_rotated() -> void:
	var c := _zone(KillZone.Shape.CIRCLE)
	c.radius = 20
	assert_true(c.contains(Vector2(124, 100), 5))
	assert_false(c.contains(Vector2(130, 100), 5))
	var x := _zone(KillZone.Shape.CROSS)
	x.length = 40
	x.width = 6
	assert_true(x.contains(Vector2(135, 100), 2), "braço horizontal")
	assert_true(x.contains(Vector2(100, 65), 2), "braço vertical")
	assert_false(x.contains(Vector2(120, 120), 2), "entre os braços, não")
	x.angle = PI / 4.0
	assert_true(x.contains(Vector2(120, 120), 2), "girada 45°: o braço passa na diagonal")


func test_screen_with_growing_ring() -> void:
	var s := _zone(KillZone.Shape.SCREEN)
	assert_true(s.contains(Vector2(600, 300), 5), "raio 0 = a tela toda")
	s.radius = 50
	assert_false(s.contains(Vector2(600, 300), 5), "o anel ainda não chegou")


func test_states_and_drain() -> void:
	var z := KillZone.new()
	z.open(KillZone.Shape.SCREEN, 0.1, true)
	assert_eq(z.phase, KillZone.Phase.ACTIVE)
	z.tick(0.2, true)
	assert_eq(z.phase, KillZone.Phase.DRAINING, "tempo acabou, ainda tem gente dentro")
	z.tick(0.1, true)
	assert_eq(z.phase, KillZone.Phase.DRAINING)
	z.tick(0.1, false)
	assert_eq(z.phase, KillZone.Phase.CLOSED)
	var n := KillZone.new()
	n.open(KillZone.Shape.CIRCLE, 0.1)
	n.tick(0.2, true)
	assert_eq(n.phase, KillZone.Phase.CLOSED, "sem drenagem fecha no tempo")


func test_champion_damage_and_reuse() -> void:
	var z := _zone(KillZone.Shape.CIRCLE)
	z.champion_frac = 0.4
	z.champion_mul = 1.0
	assert_eq(z.champion_damage(12), 5, "ceil(0,4 × 12)")
	z.champion_mul = 1.6
	assert_eq(z.champion_damage(12), 8, "Tinta/GLORIA multiplicam")
	z.champion_flat = 10
	assert_eq(z.champion_damage(999), 10, "fixo (PURGO)")
	z.champions_hit.append(3)
	z.kills = 4
	z.open(KillZone.Shape.LINE, 0.5)
	assert_eq(z.champions_hit.size(), 0, "zerada ao reabrir")
	assert_eq(z.kills, 0)
