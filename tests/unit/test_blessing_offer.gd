extends GutTest
## T1605 Sorteio dos selos (016 FR-1608): 3 distintas abaixo do teto, menos quando sobram menos,
## reserva quando não sobra nenhuma; sorteio próprio, sem consumir o RNG das letras.

const TUNING := preload("res://data/tuning/grace.tres")
const PLAYER := preload("res://data/player/anselmo.tres")

var _stats: RunStats
var _rng := RandomNumberGenerator.new()


func before_each() -> void:
	_stats = RunStats.new(PLAYER)
	_rng.seed = 11


func _draw() -> Array[BlessingData]:
	return BlessingOffer.draw(TUNING.blessings, _stats, _rng, TUNING.choices, TUNING.fallback)


func test_three_distinct_blessings() -> void:
	for i: int in 50:
		var seals: Array[BlessingData] = _draw()
		assert_eq(seals.size(), 3)
		assert_ne(seals[0], seals[1])
		assert_ne(seals[1], seals[2])
		assert_ne(seals[0], seals[2])


func _cap_all_but(keep: Array[StringName]) -> void:
	for b: BlessingData in TUNING.blessings:
		if keep.has(b.id):
			continue
		var guard: int = 0
		while not _stats.is_capped(b) and guard < 50:
			_stats.apply(b)
			guard += 1


func test_capped_blessings_are_never_offered() -> void:
	_cap_all_but([&"lodestone", &"sandals"])
	for i: int in 30:
		var ids: Array = _draw().map(func(b: BlessingData) -> StringName: return b.id)
		assert_eq(ids.size(), 2, "sobram 2: mostra 2")
		assert_true(ids.has(&"lodestone") and ids.has(&"sandals"))


func test_fallback_when_everything_is_capped() -> void:
	_cap_all_but([])
	var seals: Array[BlessingData] = _draw()
	assert_eq(seals.size(), 1)
	assert_eq(seals[0], TUNING.fallback)


func test_same_seed_same_seals() -> void:
	_rng.seed = 99
	var a: Array = _draw().map(func(b: BlessingData) -> StringName: return b.id)
	_rng.seed = 99
	var b: Array = _draw().map(func(x: BlessingData) -> StringName: return x.id)
	assert_eq(a, b)


func test_grace_draws_do_not_touch_the_letter_rng() -> void:
	GameState.start_run(PLAYER, 5)
	var state_before: int = GameState.rng.state
	for i: int in 10:
		BlessingOffer.draw(TUNING.blessings, GameState.run_stats, GameState.grace_rng, 3, TUNING.fallback)
	assert_eq(GameState.rng.state, state_before, "a sequência de letras não muda")
