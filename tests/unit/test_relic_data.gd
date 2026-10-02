extends GutTest
## D-103 (T1900; mechanics-agent 019): as 5 relíquias validam no teto; gatilho/efeito inválido é
## recusado; postos e cache como nas armas.

const RELICS := preload("res://data/tuning/relics.tres")


func test_all_relics_validate_at_the_cap() -> void:
	assert_eq(RELICS.relics.size(), 5)
	for r: RelicData in RELICS.relics:
		assert_eq(r.validate(RELICS), "", String(r.id))


func test_magnet_pulses_every_5s_at_base() -> void:
	var s := RelicSlot.new(RELICS.by_id(&"reverse_magnet"))
	assert_almost_eq(s.stats().interval, 5.0, 0.0001, "pedido do autor (D-103)")
	assert_true(s.rank_up(&"rate"))
	assert_almost_eq(s.stats().interval, 4.5, 0.0001)
	assert_eq(s.level, 2)


func test_wax_seal_comes_charged_and_caps_at_two() -> void:
	var s := RelicSlot.new(RELICS.by_id(&"wax_seal"))
	assert_eq(s.charges, 1, "vem carregado ao comprar")
	s.auto_rank_up_times(10)
	assert_eq(s.stats().charges, 2)
	assert_almost_eq(s.stats().interval, 20.0, 0.0001, "R1 1b: 25 → 20 s")


func test_bad_trigger_effect_pair_is_refused() -> void:
	var r: RelicData = RELICS.by_id(&"vespers_bell").duplicate()
	r.effect = &"absorb"
	assert_ne(r.validate(), "")
