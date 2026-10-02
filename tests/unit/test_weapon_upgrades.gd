extends GutTest
## D-098 (T1830; mechanics-agent): a arma tem base + atributos; cada selo sobe 1 posto; nível =
## 1 + compras (teto 7); os números ficam em cache e mudam a cada posto; os 6 .tres validam no teto.

const PEN := preload("res://data/weapons/pen.tres")
const LIMITS := preload("res://data/weapons/arsenal_tuning.tres")


func test_all_weapons_validate_with_every_attribute_at_the_cap() -> void:
	for w: WeaponData in LIMITS.weapons:
		assert_eq(w.validate(LIMITS), "", String(w.id))
		assert_eq(w.max_level(), 7, "%s: 1 + 6 compras" % w.id)


func test_base_is_the_old_level_one() -> void:
	assert_almost_eq(PEN.base.interval, 0.8, 0.0001)
	assert_eq(PEN.base.count, 2)


func test_rank_up_changes_the_cached_stats() -> void:
	var s := WeaponSlot.new(PEN)
	var before: WeaponLevelData = s.stats()
	assert_same(s.stats(), before, "cache: a mesma instância entre ticks")
	assert_true(s.rank_up(&"rate"))
	assert_ne(s.stats(), before, "o posto novo refaz os números")
	assert_almost_eq(s.stats().interval, 0.71, 0.0001)
	assert_eq(s.level, 2)


func test_cap_per_attribute_and_total() -> void:
	var s := WeaponSlot.new(PEN)
	assert_true(s.rank_up(&"drop"))
	assert_false(s.rank_up(&"drop"), "+1 GOTA tem 1 posto só")
	s.auto_rank_up_times(10)
	assert_eq(s.bought(), PEN.max_upgrades, "no máximo 6 compras")
	assert_eq(s.level, 7)
	assert_false(s.can_level())
	assert_true(s.free_upgrades().is_empty())


func test_describe_shows_now_and_next() -> void:
	var s := WeaponSlot.new(PEN)
	var u: WeaponUpgradeData = PEN.upgrade(&"slow")
	assert_eq(u.describe(s.stats(), s.preview(&"slow")), "0% > 20%")
