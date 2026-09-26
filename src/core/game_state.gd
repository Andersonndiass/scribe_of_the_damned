extends Node
## Estado da partida em runtime (data-model, "Estado em tempo de execução"). Autoload "GameState".
## Na feature 003 os números de jogador passam a vir do RunStats.

var candles: int = 3
var max_candles: int = 8
var atril_capacity: int = 5
var wave_index: int = 0
## Tinta dourada da partida (005 FR-512); zera a cada partida (D-018).
var gold_ink: int = 0
var unlocked_words: Array[StringName] = []
var rng := RandomNumberGenerator.new()


## Reinicia a partida a partir dos dados do personagem.
func start_run(player: PlayerData, seed_value: int = -1) -> void:
	candles = player.start_candles
	# Máximo ATUAL da partida = velas iniciais; o teto absoluto (8) só se alcança por upgrades (D-010).
	max_candles = player.start_candles
	atril_capacity = player.atril_capacity
	wave_index = 0
	gold_ink = 0
	unlocked_words.clear()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


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
