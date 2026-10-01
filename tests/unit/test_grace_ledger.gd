extends GutTest
## T1604 Graça (016 FR-1601..FR-1605; rules-agent D-083): curva 30 + 6·(n−1), fila de níveis,
## zera a cada partida e continua entre as ondas e na loja.

const TUNING := preload("res://data/tuning/grace.tres")

var _g: GraceLedger


func before_each() -> void:
	_g = GraceLedger.new(TUNING)


func test_curve_matches_the_rules_table() -> void:
	var costs: Array[int] = []
	for level: int in range(1, 6):
		costs.append(TUNING.cost(level))
	# 017 (rules-agent T1700 §4): o nível custa 40, 64, 88, 112…
	assert_eq(costs, [40, 64, 88, 112, 136] as Array[int])
	var acc: int = 0
	for level: int in range(1, 17):
		acc += TUNING.cost(level)
	assert_eq(acc, 3520, "nível 17 com 3520 de Graça (~3900 no capítulo → nível ~18)")


func test_crossing_the_threshold_queues_a_level() -> void:
	assert_eq(_g.add(39), 0)
	assert_eq(_g.level, 1)
	assert_eq(_g.add(1), 1, "40 → nível 2")
	assert_eq(_g.level, 2)
	assert_eq(_g.pending, 1)
	assert_eq(_g.progress, 0)


func test_a_big_gain_queues_several_levels() -> void:
	assert_eq(_g.add(40 + 64 + 5), 2, "um ganho grande pode subir 2 de uma vez")
	assert_eq(_g.pending, 2)
	assert_eq(_g.progress, 5, "o que sobra fica no nível")
	assert_true(_g.consume())
	assert_true(_g.consume())
	assert_false(_g.consume(), "fila vazia")


func test_nothing_from_zero_or_negative() -> void:
	assert_eq(_g.add(0), 0)
	assert_eq(_g.add(-5), 0)
	assert_eq(_g.total, 0)


func test_a_cost_table_overrides_the_formula() -> void:
	var t: GraceTuning = TUNING.duplicate()
	t.level_costs = PackedInt32Array([10, 20])
	assert_eq(t.cost(1), 10)
	assert_eq(t.cost(2), 20)
	assert_eq(t.cost(3), t.level_base + t.level_step * 2, "depois da tabela, a fórmula")


func test_run_start_resets_and_waves_do_not() -> void:
	GameState.start_run(load("res://data/player/anselmo.tres"), 7)
	GameState.grace.add(40)
	var level: int = GameState.grace.level
	EventBus.wave_ended.emit(1)
	EventBus.shop_opened.emit(1)
	assert_eq(GameState.grace.level, level, "continua entre as ondas e na loja")
	GameState.start_run(load("res://data/player/anselmo.tres"), 7)
	assert_eq(GameState.grace.level, 1, "zera a cada partida")
	assert_eq(GameState.grace.total, 0)


func test_tuning_is_valid() -> void:
	assert_eq(TUNING.validate(), "")
	assert_eq(TUNING.blessings.size(), 9, "017: saiu a Pedra-Ímã; entraram Estante Nova e Tinteiro Duplo")
