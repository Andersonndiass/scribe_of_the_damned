extends GutTest
## T220 PlayerBuffs (002 FR-206, FR-207, FR-209; D-046): escudo da FIDES, LUMEN, GLORIA e o
## estado de SPIRITUS/MISERERE (efeitos na Fase 4). Reconjurar renova, não acumula.

var _b: PlayerBuffs


func before_each() -> void:
	_b = PlayerBuffs.new()


func test_starts_neutral() -> void:
	assert_false(_b.has_shield())
	assert_eq(_b.magnet_mul(), 1.0)
	assert_eq(_b.target_weight_mul(), 1.0)
	assert_eq(_b.damage_mul(), 1.0)
	assert_eq(_b.speed_mul(), 1.0)
	assert_false(_b.is_intangible())


func test_fides_absorbs_one_hit_and_renews_without_stacking() -> void:
	_b.apply_fides(1)
	_b.apply_fides(1)
	assert_eq(_b.shield_charges, 1, "renova, não acumula")
	assert_true(_b.absorb_hit())
	assert_false(_b.has_shield())
	assert_false(_b.absorb_hit(), "sem escudo, o golpe passa")


func test_fides_lasts_until_the_wave_ends() -> void:
	_b.apply_fides(1)
	_b.tick(120.0)
	assert_true(_b.has_shield(), "não expira por tempo")
	_b.on_wave_ended()
	assert_false(_b.has_shield())


func test_lumen_multiplies_magnet_and_target_for_its_duration() -> void:
	_b.apply_lumen(10.0, 2.0, 2.0)
	assert_eq(_b.magnet_mul(), 2.0)
	assert_eq(_b.target_weight_mul(), 2.0)
	_b.tick(9.9)
	assert_eq(_b.magnet_mul(), 2.0)
	_b.tick(0.2)
	assert_eq(_b.magnet_mul(), 1.0)
	assert_eq(_b.target_weight_mul(), 1.0)


func test_gloria_multiplies_damage_and_renews() -> void:
	_b.apply_gloria(6.0, 1.5)
	_b.tick(5.0)
	_b.apply_gloria(6.0, 1.5)
	_b.tick(5.0)
	assert_eq(_b.damage_mul(), 1.5, "renovou aos 5 s")
	_b.tick(1.1)
	assert_eq(_b.damage_mul(), 1.0)


func test_spiritus_state_for_phase_4() -> void:
	_b.apply_spiritus(6.0, 1.5)
	assert_eq(_b.speed_mul(), 1.5)
	assert_true(_b.is_intangible())
	_b.tick(6.1)
	assert_false(_b.is_intangible())


func test_forgive_heresy_is_consumed_once() -> void:
	_b.grant_forgiveness()
	assert_true(_b.consume_forgiveness())
	assert_false(_b.consume_forgiveness())
