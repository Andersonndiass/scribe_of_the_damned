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
	# 018 (rules-agent T1801, pedido D-094): o 1º nível é curto; depois 40, 64, 92, 120…
	assert_eq(costs, [16, 40, 64, 92, 120] as Array[int])
	var acc: int = 0
	for level: int in range(1, 18):
		acc += TUNING.cost(level)
	assert_eq(acc, 3956, "nível 18 com 3956 de Graça (o total do capítulo continua)")


func test_crossing_the_threshold_queues_a_level() -> void:
	assert_eq(_g.add(15), 0)
	assert_eq(_g.level, 1)
	assert_eq(_g.add(1), 1, "16 → nível 2 (D-094)")
	assert_eq(_g.level, 2)
	assert_eq(_g.pending, 1)
	assert_eq(_g.progress, 0)


func test_a_big_gain_queues_several_levels() -> void:
	assert_eq(_g.add(16 + 40 + 5), 2, "um ganho grande pode subir 2 de uma vez")
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
