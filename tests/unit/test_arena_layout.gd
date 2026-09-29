extends GutTest
## T402/T403 Layout de obstáculos do Cap. 1 (004 FR-408, FR-411; SC-406; rules-agent): layout válido
## (dentro da área, sem sobreposição, folga 0 ou ≥ 40 px); área livre CONEXA para o escriba e para o
## maior inimigo campeão (flood fill); nascimento do escriba e casa do chefe livres; o mapa responde
## certo (bloqueio por máscara, empurrar para fora, ponto livre mais próximo).

const CHAPTER := preload("res://data/chapters/chapter_1.tres")
const GRID := 4.0
const SCRIBE_R := 8.0
const SPAWN := Vector2(320, 180)
const BOSS_HOME := Vector2(320, 110)


func _arena() -> ArenaData:
	return CHAPTER.arena


func test_layout_is_valid() -> void:
	assert_not_null(_arena(), "o capítulo tem arena")
	assert_eq(_arena().validate(), "")
	assert_eq(_arena().obstacles.size(), 7, "4 furos, vitral, altar, banco")


func test_spawn_and_boss_home_are_free() -> void:
	for boss_layout: bool in [false, true]:
		var m := ObstacleMap.from_arena(_arena(), boss_layout)
		assert_true(m.is_free(SPAWN, SCRIBE_R), "escriba nasce livre")
		assert_true(m.is_free(BOSS_HOME, 20.0), "casa do chefe livre")


## Flood fill numa grade de 4 px: toda célula livre para o raio `r` é alcançável a partir do escriba.
func _connected(m: ObstacleMap, r: float) -> bool:
	var inner: Rect2 = ArenaData.PLAYABLE.grow(-r)
	var cols: int = int(inner.size.x / GRID)
	var rows: int = int(inner.size.y / GRID)
	var free := PackedByteArray()
	free.resize(cols * rows)
	var total: int = 0
	for y: int in rows:
		for x: int in cols:
			var p: Vector2 = inner.position + Vector2(x + 0.5, y + 0.5) * GRID
			if m.is_free(p, r):
				free[y * cols + x] = 1
				total += 1
	var start := Vector2i(int((SPAWN.x - inner.position.x) / GRID), int((SPAWN.y - inner.position.y) / GRID))
	var seen := PackedByteArray()
	seen.resize(cols * rows)
	var queue: Array[Vector2i] = [start]
	seen[start.y * cols + start.x] = 1
	var visited: int = 0
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		visited += 1
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if n.x < 0 or n.y < 0 or n.x >= cols or n.y >= rows:
				continue
			var i: int = n.y * cols + n.x
			if free[i] == 1 and seen[i] == 0:
				seen[i] = 1
				queue.append(n)
	return visited == total


func test_free_area_is_connected() -> void:
	var champion: ChampionTuning = load("res://data/tuning/champion.tres")
	var biggest: float = 6.0 * champion.radius_mul
	for boss_layout: bool in [false, true]:
		var m := ObstacleMap.from_arena(_arena(), boss_layout)
		assert_true(_connected(m, SCRIBE_R), "sem bolsão para o escriba (chefe=%s)" % boss_layout)
		assert_true(_connected(m, biggest), "sem bolsão para o campeão (chefe=%s)" % boss_layout)


func test_map_blocks_by_mask() -> void:
	var m := ObstacleMap.from_arena(_arena(), false)
	var hole := Vector2(80, 80)
	var window := Vector2(34, 180)
	assert_true(m.blocks(hole, ObstacleTypeData.Block.WALK), "furo bloqueia andar")
	assert_false(m.blocks(hole, ObstacleTypeData.Block.ENEMY_SHOT), "tiro passa pelo furo")
	assert_true(m.blocks(window, ObstacleTypeData.Block.ENEMY_SHOT), "o vitral para o tiro do Monge")
	assert_false(m.blocks(window, ObstacleTypeData.Block.FLYER), "a Traça voa por cima")
	assert_false(m.blocks(window, ObstacleTypeData.Block.PLAYER_SHOT), "o tiro do escriba passa")


func test_constrain_pushes_out_and_nearest_free_finds_room() -> void:
	var m := ObstacleMap.from_arena(_arena(), false)
	var inside := Vector2(80, 80)
	var out: Vector2 = m.constrain(inside, 5.0)
	assert_true(m.is_free(out, 5.0), "empurrado para fora")
	assert_lt(out.distance_to(inside), 14.0, "pelo lado mais curto")
	var drop: Vector2 = m.nearest_free(Vector2(320, 30), 3.0)
	assert_true(m.is_free(drop, 3.0), "letra que cairia no altar vai para fora")
	assert_true(ArenaData.PLAYABLE.has_point(drop))


func test_constrain_never_pushes_into_the_margin() -> void:
	# Bug da sonda (004 T413): inimigo no alto do altar era empurrado para y=19, entre a peça e a parede.
	var m := ObstacleMap.from_arena(_arena(), false)
	var inner: Rect2 = ArenaData.PLAYABLE.grow(-5.0)
	for p: Vector2 in [Vector2(320, 26), Vector2(26, 180), Vector2(320, 334), Vector2(291, 30)]:
		var q: Vector2 = m.constrain(p, 5.0)
		assert_true(inner.grow(0.1).has_point(q), "%s → %s fica na página" % [p, q])
		assert_true(m.is_free(q, 5.0), "%s → %s fora da peça" % [p, q])


func test_slide_never_heads_into_the_wall_corner() -> void:
	# Bug da sonda (T413): ao lado do altar, empurrado para cima pela multidão, o inimigo deslizava
	# para o canto entre a peça e a parede e ficava preso.
	var m := ObstacleMap.from_arena(_arena(), false)
	var v: Vector2 = m.slide(Vector2(355, 26), Vector2(-26, -51), 5.0)
	assert_gt(v.y, 0.0, "desce, para longe da parede")
