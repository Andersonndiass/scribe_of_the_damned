extends GutTest
## T602 BossDamageFilter (006 FR-604, FR-609b, SC-603; D-062): teto por conjuração, parada no
## limiar da fase com invulnerabilidade, janela de exposição, automático sem teto.

const BOSS := preload("res://data/bosses/asmodeus.tres")
const DATA := preload("res://data/tuning/boss_damage_filter.tres")

var _f: BossDamageFilter


func before_each() -> void:
	_f = BossDamageFilter.new(DATA, BOSS)


func test_starts_full_in_phase_one() -> void:
	assert_eq(_f.hp, 1500)
	assert_eq(_f.phase_index, 0)


func test_cast_soft_and_hard_caps() -> void:
	assert_eq(_f.apply(70, &"mortis", 1), 70, "abaixo do teto suave entra inteiro")
	# 017 (rules-agent T1700 §3): teto suave 250, duro 500.
	assert_eq(_f.apply(400, &"miserere", 2), 250 + 75, "250 inteiros + metade dos 150 seguintes")
	_f = BossDamageFilter.new(DATA, BOSS)  # fase cheia de novo (o golpe anterior gastou a fase)
	assert_eq(_f.apply(900, &"miserere", 3), 250 + 125, "teto duro: 500 no máximo")


func test_cap_sums_ticks_of_the_same_cast() -> void:
	var total: int = 0
	for i: int in 48:  # SANCTUS: 15 por tick × 48 = 720
		total += _f.apply(15, &"sanctus", 7)
	assert_eq(total, 375, "o teto vale para a soma da conjuração")
	assert_eq(_f.apply(15, &"sanctus", 8), 15, "outra conjuração começa do zero")


func test_auto_attack_has_no_cap() -> void:
	var total: int = 0
	for i: int in 300:
		total += _f.apply(1, &"auto", 0)
	assert_eq(total, 300)


func test_damage_stops_at_the_phase_threshold_and_grants_invulnerability() -> void:
	_f.hp = 1000
	var got: int = _f.apply(100, &"dominus", 1)
	assert_eq(_f.hp, 990, "para no limiar de 66% (990)")
	assert_eq(got, 10)
	assert_eq(_f.phase_index, 1, "entrou na F2")
	assert_eq(_f.apply(50, &"mortis", 2), 0, "invulnerável no PhaseShift")
	_f.tick(1.6)
	assert_eq(_f.apply(50, &"mortis", 3), 50)


func test_no_single_word_skips_a_phase() -> void:
	# SC-603: nem MISERERE × GLORIA (420) tira mais que uma fase.
	var got: int = _f.apply(420, &"miserere", 1)
	assert_true(got <= 1500 - 990, "no máximo até o limiar")
	assert_eq(_f.phase_index, 0, "240 não chega ao limiar de 510")


func test_exposed_window_boosts_words_only() -> void:
	_f.expose()
	assert_eq(_f.apply(40, &"lux", 1), 50, "+25% nas palavras")
	assert_eq(_f.apply(4, &"auto", 0), 4, "o automático não ganha bônus")
	_f.tick(1.1)
	assert_eq(_f.apply(40, &"lux", 2), 40)


func test_last_phase_can_reach_zero() -> void:
	_f.hp = 100
	_f.phase_index = 2
	_f.apply(70, &"mortis", 1)
	_f.apply(70, &"mortis", 2)
	assert_eq(_f.hp, 0)
	assert_true(_f.is_dead())
