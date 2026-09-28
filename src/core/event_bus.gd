extends Node
## Barramento de sinais entre sistemas (plan §4.3). Autoload "EventBus".
## Sistemas emitem e escutam aqui; nenhum sistema busca outro por caminho de nó.

@warning_ignore_start("unused_signal")

# Ondas
signal wave_started(index: int, duration: float)
signal wave_ended(index: int)

# Inimigos
signal enemy_spawned(slot: int, data: EnemyData)
signal enemy_killed(slot: int, data: EnemyData, position: Vector2)

signal champion_killed(data: EnemyData, position: Vector2)

# Jogador
signal player_damaged(amount: int, candles: int)
signal player_healed(amount: int, candles: int)
signal player_died()

# Letras e atril
signal letter_dropped(letter: String, rare: bool, target: bool, position: Vector2)
signal letter_collected(letter: String, rare: bool)
signal letter_rejected(letter: String)
## rare_mask: bit i ligado = a letra i é vogal rara.
signal atril_changed(letters: PackedStringArray, state: int, hints: PackedStringArray, rare_mask: int)

signal letter_eaten(letter: String, position: Vector2)
signal word_unlocked(word: WordData)
signal gold_ink_collected(amount: int, total: int)

# Conjuração
signal word_cast(word: WordData, power: float, origin: Vector2, direction: Vector2)
signal heresy_committed(position: Vector2)
signal atril_purged(letters: PackedStringArray, position: Vector2)
## 002: um combo substituiu o milagre da 2ª palavra (o word_cast dela sai antes).
signal combo_cast(combo: ComboData, power: float)
## 002: a palavra abriu a janela de combo; `duration` = segundos contados da 1ª letra;
## `partners` = latim das palavras que fecham combo com ela (dicas e COMBO_READY do HUD).
signal combo_window_opened(word: WordData, duration: float, partners: PackedStringArray)
signal combo_window_closed()

# Capítulo
signal chapter_completed(chapter: int)

# Sensação
signal hitstop_requested(duration_ms: int)

@warning_ignore_restore("unused_signal")
