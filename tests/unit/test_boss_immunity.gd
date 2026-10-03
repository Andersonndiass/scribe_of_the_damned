extends GutTest
## 012 F3 (FR-1210, SC-1202; D-107 3a): chefe `words_only` — armas, relíquias, poções e dano sem
## origem dão 0 (`last_block` = immune); palavras e PURGO passam com os tetos; o retorno "imune" tem
## intervalo; as armas não miram o chefe imune.

const ASMODEUS := preload("res://data/bosses/asmodeus.tres")
const DATA := preload("res://data/tuning/boss_damage_filter.tres")
const IMP := preload("res://data/enemies/imp.tres")
const BOSS_SCENE := preload("res://src/bosses/boss.tscn")


class FakeBoss:
	extends BossHurtbox
	var weapon_target: bool = true

	func hurt_radius() -> float:
		return 20.0

	func is_targetable() -> bool:
		return true

	func is_weapon_target() -> bool:
		return weapon_target


var _immune: Array = []


func _words_only() -> BossData:
	var b: BossData = ASMODEUS.duplicate()
	b.words_only = true
	return b


func _on_immune(p: Vector2, tag: StringName) -> void:
	_immune.append(tag)


func test_non_word_sources_do_nothing() -> void:
	var f := BossDamageFilter.new(DATA, _words_only())
	for tag: StringName in [&"auto", &"relic", &"potion", &""]:
		assert_eq(f.apply(50, tag, 0), 0, "%s não fere" % tag)
		assert_eq(f.last_block, &"immune")
	assert_eq(f.hp, f.boss.max_hp)


func test_words_and_purgo_still_hurt_with_caps() -> void:
	var f := BossDamageFilter.new(DATA, _words_only())
	assert_eq(f.apply(70, &"mortis", 1), 70)
	assert_eq(f.last_block, &"")
	assert_eq(f.apply(25, &"purgo", 2), 25, "PURGO é palavra")
	assert_eq(f.apply(600, &"miserere", 3), 250 + 125, "tetos da 006 continuam")


func test_normal_boss_still_takes_weapons() -> void:
	var f := BossDamageFilter.new(DATA, ASMODEUS)
	assert_eq(f.apply(5, &"auto", 0), 5)


func test_immune_feedback_is_throttled() -> void:
	var boss: Boss = BOSS_SCENE.instantiate()
	boss.data = _words_only()
	var m := EnemyManager.new()
	add_child_autofree(m)
	m.set_physics_process(false)
	boss.manager = m
	add_child_autofree(boss)
	boss.start_fight(true)
	EventBus.boss_immune_hit.connect(_on_immune)
	for k: int in 5:
		boss.take(3, &"auto", 0)
	boss.take(10, &"lux", 7)
	EventBus.boss_immune_hit.disconnect(_on_immune)
	assert_eq(_immune, [&"auto"], "1 retorno por intervalo; a palavra não é imune")
	assert_false(boss.is_weapon_target())


func test_weapons_ignore_an_immune_boss() -> void:
	var root := Node2D.new()
	add_child_autofree(root)
	var m := EnemyManager.new()
	root.add_child(m)
	m.set_physics_process(false)
	var fb := FakeBoss.new()
	root.add_child(fb)
	fb.global_position = Vector2(300, 180)
	m.boss_target = fb
	assert_eq(m.query_nearest(Vector2(280, 180), 100.0), Vector2(300, 180), "chefe normal é alvo")
	fb.weapon_target = false
	assert_eq(m.query_nearest(Vector2(280, 180), 100.0), Vector2.INF, "imune: as armas não miram")
	m.spawn(IMP, Vector2(240, 180))
	assert_ne(m.query_nearest(Vector2(280, 180), 100.0), Vector2.INF, "miram as crias")
	assert_eq(m.query_nearest_list(Vector2(280, 180), 100.0, 3).size(), 1)
