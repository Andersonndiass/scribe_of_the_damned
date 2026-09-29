extends Node
## Estado da partida em runtime (data-model, "Estado em tempo de execução"). Autoload "GameState".
## Os números do escriba na partida vêm do `run_stats` (003).

var candles: int = 3
var max_candles: int = 8
var atril_capacity: int = 5
var wave_index: int = 0
## Tinta dourada da partida (005 FR-512); zera a cada partida (D-018).
var gold_ink: int = 0
var unlocked_words: Array[StringName] = []
var rng := RandomNumberGenerator.new()
## Números do escriba com os itens da loja (003 FR-309). Recriado a cada partida.
var run_stats: RunStats = null
## Fração de tinta acumulada pelo ×tinta da Bolsa do Esmoler (a gota é inteira).
var gold_fraction: float = 0.0
## Screen shake ligado (D-047 6B; a tela de Opções, 007, muda). Vale entre partidas.
var shake_enabled: bool = true


## Reinicia a partida a partir dos dados do personagem.
func start_run(player: PlayerData, seed_value: int = -1) -> void:
	candles = player.start_candles
	# Máximo ATUAL da partida = velas iniciais; o teto absoluto (8) só se alcança por upgrades (D-010).
	max_candles = player.start_candles
	atril_capacity = player.atril_capacity
	wave_index = 0
	gold_ink = 0
	gold_fraction = 0.0
	run_stats = RunStats.new(player)
	unlocked_words.clear()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


## Soma tinta dourada com o ×tinta da partida (Bolsa do Esmoler, 003). Retorna quanto entrou.
func add_gold(raw: int) -> int:
	var mul: float = run_stats.value(&"gold_mul") if run_stats != null else 1.0
	var total: float = float(raw) * mul + gold_fraction
	var whole: int = int(floor(total + 0.0001))
	gold_fraction = total - float(whole)
	gold_ink += whole
	return whole


func is_word_unlocked(word_id: StringName) -> bool:
	return unlocked_words.has(word_id)


## Palavra conhecida = não exige desbloqueio ou já foi desbloqueada (002 FR-201).
func is_word_known(word: WordData) -> bool:
	return not word.requires_unlock or unlocked_words.has(word.id)


## Desbloqueia um apócrifo (a loja da 003 chama). VERBUM libera o B no drop (D-015).
func unlock_word(word: WordData) -> void:
	if unlocked_words.has(word.id):
		return
	unlocked_words.append(word.id)
	EventBus.word_unlocked.emit(word)
