# 002 — Plan

## 1. Arquitetura
- **Vocabulário conhecido:** o `Lexicon` recebe um filtro `is_known(word)` (Callable de `GameState`). `is_word`, `is_prefix`, `words_with_prefix` e `next_letters` passam a considerar só as conhecidas. As desconhecidas continuam validadas no load (Princípio VIII).
- **Combos:** o `Caster` guarda a última palavra e o instante dela. Na conjuração seguinte, se houver `ComboData` para o par e ainda estiver dentro da janela, dispara o combo (pool com a chave = id do combo) **em vez do** milagre da 2ª palavra. `ComboBook` (lógica pura, testável) resolve o par.
- **Buffs do jogador:** `PlayerBuffs` (RefCounted no Player) com timers; FIDES absorve em `Player.take_hit`, SPIRITUS/SALVATOR dão invulnerabilidade, LUMEN multiplica o ímã (LetterField lê), GLORIA multiplica o `power` no Caster.
- **Cegueira/Vapor:** `blind_left` por inimigo no EnemyManager: o inimigo cego vaga (direção por slot e tempo) e não causa contato.
- **Drop garantido (Réquiem, MISERERE):** `guaranteed_drop` por slot, lido pelo LetterField no `enemy_killed`.
- **PURGO:** reutiliza o padrão de lotes do MORTIS (`mortis_step`), com 30 por frame e dano grande em campeões.
- **VERBUM:** o Caster repete `last_word` (exceto VERBUM) com o mesmo poder, e conta como a palavra repetida para os combos.

## 2. Arquivos
```
src/letters/lexicon.gd (filtro de conhecidas) · src/core/game_state.gd (unlock_word)
src/miracles/combo_book.gd (lógica pura) · src/data/combo_data.gd · src/data/combo_tuning.gd
src/miracles/caster.gd (combos, VERBUM, GLORIA)
src/player/player_buffs.gd · player.gd (FIDES, SPIRITUS, SALVATOR)
src/enemies/enemy_manager.gd (blind_left, guaranteed_drop, purgo em lotes)
src/miracles/{fides,lumen,purgo,gloria,verbum,sanctus,dominus,angelus,spiritus,salvator,miserere}/
src/miracles/combos/{vapor,radiant,blindness,martyrdom,requiem}/
src/ui/hud/combo_window.gd
data/words/*.tres (11) · data/combos/*.tres (5) · data/tuning/combo.tres · data/lexicon/base.tres
tests/unit/test_combo_book.gd · test_known_words.gd · test_player_buffs.gd
tests/integration/test_combos.gd · test_apocrypha.gd · test_orations.gd
```

## 3. Riscos
| Risco | Mitigação |
|---|---|
| Combos confusos para o jogador | HUD da janela + dicas destacando o par; os combos só entre palavras base |
| Grandes Orações fortes demais | Só com atril 7–8 (upgrade caro na 003); números com o rules-agent |
| Custo no web de efeitos de tela (DOMINUS, MISERERE, PURGO) | Lotes escalonados como no MORTIS; medir com a cena de stress |
