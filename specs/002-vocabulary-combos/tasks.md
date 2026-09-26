# 002 — Tasks

Legenda: `[TEST-FIRST]` = o teste é escrito e falha antes da implementação.

## Fase 1 — Vocabulário conhecido
- ✅ **T200** `WordData` + `group`, `requires_unlock`, `combo_eligible`, `buff_mul`, `magnet_mul`; `GameState.unlock_word`; sinal `word_unlocked`.
- ✅ **T201** [TEST-FIRST] `test_known_words.gd` → filtro de conhecidas no `Lexicon` (atril, dicas, Tab, drop). SC-203.
- ✅ **T202** As 11 palavras novas no `base.tres`; `test_word_power` com 18 palavras (SC-204).

## Fase 2 — Combos
- **T210** [TEST-FIRST] `test_combo_book.gd` → `ComboBook` + `ComboData` + os 5 `.tres` (par em qualquer ordem, janela, GLORIA/PURGO fora, combo não encadeia).
- **T211** Caster: janela de combo, substituição da 2ª palavra, sinais `combo_cast`/`combo_window_opened`. Integração `test_combos.gd` (SC-201).
- **T212** EnemyManager: `blind_left` (vagar, sem contato) e `guaranteed_drop`.
- **T213** Os 5 milagres de combo (Vapor, Chama Radiante, Cegueira, Martírio, Réquiem).
- **T214** HUD: `combo_window.gd` (12 quadros) + dicas destacando o par.

**Checkpoint 002-A:** os 5 combos jogáveis.

## Fase 3 — Apócrifos
- **T220** [TEST-FIRST] `test_player_buffs.gd` → `PlayerBuffs` (FIDES, LUMEN, GLORIA, SPIRITUS, invul).
- **T221** FIDES, LUMEN, GLORIA, VERBUM (+ B liberado) e PURGO em lotes (SC-202).
- **T222** Debug `?unlock=all` para playtest.

## Fase 4 — Grandes Orações
- **T230** SANCTUS, DOMINUS, ANGELUS (7 letras).
- **T231** SPIRITUS, SALVATOR, MISERERE (8 letras).
- **T232** Integração `test_orations.gd` (atril 7–8).

## Fase 5 — Fechamento
- **T240** Parecer do rules-agent sobre os números finais; stress com PURGO/MISERERE/DOMINUS (SC-202, SC-205).
- **T241** Export web, GUT, `FEATURES.md` (002 → Complete), `CLAUDE.md`, `docs/DECISIONS.md`.
