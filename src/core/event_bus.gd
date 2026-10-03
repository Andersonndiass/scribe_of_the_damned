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
## 012: a Traça-Mãe pequena estourou (crias nascidas e abafadas por zona letal/teto).
signal brood_burst(position: Vector2, spawned: int, smothered: int)

signal champion_killed(data: EnemyData, position: Vector2)
## Um campeão entrou na página (o Grimório registra o verbete "Campeão").
signal champion_spawned(slot: int, data: EnemyData)

# Jogador
signal player_damaged(amount: int, candles: int)
signal player_healed(amount: int, candles: int)
signal player_died()

# Letras e atril
signal letter_collected(letter: String, rare: bool)
## 017 menu da letra: abriu com as opções ({letter, rare, useful}); escolheu; o tempo acabou (a
## letra se perdeu); fechou; um pedido passou do teto da fila e se perdeu.
signal letter_menu_opened(options: Array)
signal letter_chosen(letter: String, rare: bool)
signal letter_lost()
signal letter_menu_closed()
signal letter_offer_dropped()
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
## D-099: a palavra pronta foi para a guarda (`partners` = latim das que fecham combo com ela).
signal word_stored(word: WordData, rare_count: int, partners: PackedStringArray, rare_mask: int)
## D-099: a guardada saiu (`cause`: &"cast" = conjurada sozinha; &"combo" = gasta num combo).
signal stored_word_released(word: WordData, cause: StringName)
## 010: o estado inteiro da guarda (1 ou 2 espaços), da mais antiga para a mais nova.
signal word_guard_changed(words: Array[WordData], rare_masks: PackedInt32Array, capacity: int)
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

# Graça (016): ganho (fonte &"kill", &"champion", &"word", &"combo"), barra, nível subido (com a fila),
# selos abertos e fechados (sempre o último), bênção escolhida; a Pausa por cima dos selos; pingo de cera.
signal grace_gained(amount: int, source: StringName, position: Vector2)
signal grace_changed(progress: int, needed: int, level: int)
signal grace_leveled(level: int, pending: int)
signal seals_shown(blessings: Array[BlessingData], level: int)
signal blessing_chosen(blessing: BlessingData, level: int)
signal seals_hidden()
signal pause_menu_toggled(open: bool)
signal wax_drop_collected(position: Vector2)

# Armas (017): arma posta num espaço, troca da ativa (1/2), nível subido.
signal weapon_equipped(slot: int, weapon: WeaponData, level: int)
signal weapon_switched(slot: int, weapon: WeaponData)
## 017: ímã reverso subiu de nível (1 = comprado) e soltou um pulso (inimigos empurrados).
## 018 (D-095): feixe do nível começou (duração da câmera lenta) e terminou.
signal levelup_beam_started(duration: float)
signal levelup_beam_ended()
## 018 Poções: bebeu (id, nível, cargas que sobraram); recusou sem gastar (motivo: empty, gap,
## blocked, stunned, full, menu_busy); efeito acabou (timeout, heresy, wave_end); cargas mudaram
## (loja ou gole); nível subiu (selo).
signal potion_drunk(id: StringName, level: int, charges: int)
signal potion_refused(id: StringName, reason: StringName)
signal potion_effect_ended(id: StringName, reason: StringName)
signal potion_charges_changed(id: StringName, charges: int, max_charges: int)
signal potion_leveled(id: StringName, level: int)
signal potion_bought(id: StringName, price: int)
# --- Relíquias e venda (019; D-103) ---
signal relic_equipped(slot: int, relic: RelicData, level: int)
signal relic_leveled(slot: int, relic: RelicData, level: int, upgrade: StringName, rank: int)
## cause: &"sold" | &"replaced".
signal relic_removed(slot: int, relic: RelicData, cause: StringName)
signal relic_pulsed(slot: int, id: StringName, center: Vector2, radius: float, hits: int)
signal relic_shield_changed(slot: int, charges: int, max_charges: int)
signal relic_shield_absorbed(slot: int, position: Vector2)
signal weapon_removed(slot: int, weapon: WeaponData, cause: StringName)
## kind: &"weapon" | &"relic" | &"potion".
signal item_sold(kind: StringName, id: StringName, price: int)
## 010: um escriba foi liberado (o nome reescrito no registro).
signal character_unlocked(id: StringName)
## D-098: `upgrade` = o atributo que subiu e `rank` o posto novo dele.
signal weapon_leveled(slot: int, weapon: WeaponData, level: int, upgrade: StringName, rank: int)

# Cutscenes (008): o fluxo do jogo escuta só o `cutscene_finished`, que sai sempre por último.
signal cutscene_started(id: StringName)
signal cutscene_mark_reached(id: StringName, mark: StringName)
signal cutscene_skipped(id: StringName)
signal cutscene_finished(id: StringName, skipped: bool)

# Sensação
signal hitstop_requested(duration_ms: int)

# --- Áudio (009/018; DIRECAO-SONORA §4.2): momentos que só o som precisa ouvir ---
signal weapon_fired(weapon_id: StringName)
signal weapon_hit(weapon_id: StringName)
signal weapon_windup_started(weapon_id: StringName)
signal weapon_beam_toggled(weapon_id: StringName, on: bool)
signal boss_attack_telegraphed(kind: StringName)
signal boss_attack_started(kind: StringName)
signal boss_attack_finished(kind: StringName)
signal boss_stunned(seconds: float)
signal enemy_spawn_telegraphed(champion: bool)
signal enemy_telegraphed(enemy_id: StringName)
signal enemy_attacked(enemy_id: StringName)
signal enemy_projectile_hit()
signal hazard_entered()
signal letter_menu_cursor_moved(index: int)
signal shop_purchase_denied()
signal shop_lock_toggled(locked: bool)
signal ui_focus_changed()
signal ui_confirmed()
signal ui_backed()
signal ui_slider_changed()
signal ui_key_remapped()

@warning_ignore_restore("unused_signal")
