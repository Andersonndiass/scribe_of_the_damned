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
## Um campeão entrou na página (o Grimório registra o verbete "Campeão").
signal champion_spawned(slot: int, data: EnemyData)

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
## 002 FIDES: o escudo absorveu um golpe.
signal shield_broken(position: Vector2)
## 002 VERBUM: repetiu `word` / não havia o que repetir (falha sem heresia, D-055).
signal verbum_echoed(word: WordData)
signal verbum_failed()
## 002 MISERERE: apaga as poças de heresia; a próxima heresia foi perdoada (sem stun, letras ficam).
signal heresy_absolved()
signal heresy_forgiveness_granted()
signal heresy_forgiven(position: Vector2)

# Loja (003)
signal shop_opened(wave: int)
signal shop_closed()
signal item_bought(item: ShopItemData, price: int)
signal shop_rerolled(cost: int)

# Chefe (006)
signal boss_spawned(boss: BossData)
signal boss_damaged(hp: int, max_hp: int)
signal boss_phase_changed(phase_index: int)
signal boss_exposed(seconds: float)
signal boss_defeated(boss: BossData)
## Rasura: o chefe pede; o LetterField aplica as proteções e avisa o que apagou.
signal atril_erase_requested()
signal letter_erased(letter: String, position: Vector2)
## Rasura telegrafando (true) / acabou (false): o atril marca a última letra (design-agent).
signal erasure_warned(active: bool)
## Morte do chefe: as letras douradas explodem de `position` (visual).
signal boss_letters_burst(position: Vector2, count: int)
## Sensação (006 FR-612): força em px e duração em s; a câmera decide se treme (opção).
signal shake_requested(strength: float, duration: float)

# Configurações (007)
signal settings_applied()
## Telas (007): o roteador trocou de tela; a partida pediu para recomeçar.
signal screen_changed(screen: StringName)
signal game_restart_requested()
## Uma tela pediu outra (o roteador faz a transição).
signal screen_requested(screen: StringName)
## Grimório: entrada nova (categoria: words, combos, enemies, bosses).
signal codex_discovered(category: StringName, id: StringName)

# Capítulo
signal chapter_completed(chapter: int)

# Página (004): a onda está nos últimos segundos; o estágio da página mudou (animado = fim de onda);
# o estágio terminou de aparecer; o layout de obstáculos mudou (ondas ou chefe).
signal wave_closing(index: int, seconds_left: float)
signal page_stage_changed(stage: int, next_stage: int, animated: bool)
signal page_degraded(stage: int)
signal arena_layout_changed(boss_layout: bool)

# Cutscenes (008): o fluxo do jogo escuta só o `cutscene_finished`, que sai sempre por último.
signal cutscene_started(id: StringName)
signal cutscene_mark_reached(id: StringName, mark: StringName)
signal cutscene_skipped(id: StringName)
signal cutscene_finished(id: StringName, skipped: bool)

# Sensação
signal hitstop_requested(duration_ms: int)

@warning_ignore_restore("unused_signal")
