extends GutTest
## 010 (D-101; T1000): os 5 escribas validam; passivas, arma, poções e desbloqueio dos dados.

const ROSTER := preload("res://data/player/roster.tres")


func test_roster_validates() -> void:
	assert_eq(ROSTER.validate(), "")
	assert_eq(ROSTER.characters.size(), 5)
	assert_eq(ROSTER.default().id, &"anselmo")


func test_passives_come_from_data() -> void:
	assert_eq(RunStats.new(ROSTER.by_id(&"tome")).value(&"heresy_stun_mul"), 0.0, "Tomé: sem atordoamento")
	assert_eq(ROSTER.by_id(&"tome").start_candles, 2)
	assert_almost_eq(RunStats.new(ROSTER.by_id(&"iluminador")).value(&"double_letter_chance"), 0.24, 0.001)
	assert_eq(RunStats.new(ROSTER.by_id(&"beda")).int_value(&"atril_capacity"), 4)
	assert_eq(RunStats.new(ROSTER.by_id(&"hildegarda")).int_value(&"word_guard_slots"), 2)


func test_start_potions_and_weapons() -> void:
	var belt := PotionBelt.new(GameState.potion_tuning, ROSTER.by_id(&"tome").start_potions)
	assert_eq(belt.charges(&"oil"), 2, "Tomé: Óleo ×2")
	assert_eq(ROSTER.by_id(&"iluminador").start_weapon.id, &"bible")
	assert_eq(ROSTER.by_id(&"anselmo").start_weapon.id, &"pen")


func test_unlocks() -> void:
	assert_null(ROSTER.by_id(&"anselmo").unlock, "o Anselmo é livre")
	assert_eq(ROSTER.by_id(&"tome").unlock.kind, &"heresies_survived")
	assert_eq(ROSTER.by_id(&"tome").unlock.target, 10)
	assert_eq(ROSTER.by_id(&"beda").unlock.target, 7)
