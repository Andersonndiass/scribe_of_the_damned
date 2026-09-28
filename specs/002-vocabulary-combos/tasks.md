# 002 — Tasks

Legenda: `[TEST-FIRST]` = o teste é escrito e falha antes da implementação.

## Fase 1 — Vocabulário conhecido
- ✅ **T200** `WordData` + `group`, `requires_unlock`, `combo_eligible`, `buff_mul`, `magnet_mul`; `GameState.unlock_word`; sinal `word_unlocked`.
- ✅ **T201** [TEST-FIRST] `test_known_words.gd` → filtro de conhecidas no `Lexicon` (atril, dicas, Tab, drop). SC-203.
- ✅ **T202** As 11 palavras novas no `base.tres`; `test_word_power` com 18 palavras (SC-204).

## Fase 2 — Combos
- ✅ **T210** [TEST-FIRST] `test_combo_book.gd` → `ComboBook` + `ComboData` + os 5 `.tres` (par em qualquer ordem, janela, GLORIA/PURGO fora, combo não encadeia).
- ✅ **T211** Caster: janela de combo, substituição da 2ª palavra, sinais `combo_cast`/`combo_window_opened` (+ `combo_window_closed`, D-052). Integração `test_combos.gd` (SC-201).
- ✅ **T212** EnemyManager: `blind_left` (vaga; **o contato continua**, D-046/D-052), `guaranteed_drop` (`requiem_step`) e escriba oculto (`hide_player`, Vapor).
- ✅ **T213** Os 5 milagres de combo (Vapor, Chama Radiante, Cegueira, Martírio, Réquiem). Números: D-051.
- ✅ **T214** HUD: `combo_window.gd` (barra em 12 passos + nome do combo) + COMBO_READY no atril + dicas destacando o par.

**Checkpoint 002-A:** ✅ os 5 combos jogáveis (2026-09-28, GUT 175/175, export web ok).

## Fase 3 — Apócrifos
- ✅ **T220** [TEST-FIRST] `test_player_buffs.gd` → `PlayerBuffs` (FIDES, LUMEN, GLORIA, SPIRITUS, perdão da MISERERE).
- ✅ **T221** FIDES, LUMEN, GLORIA, VERBUM (+ B liberado) e PURGO em lotes. `test_apocrypha.gd`. SC-202 medido (`?stress=purgo`): inconclusivo nesta máquina, fica para a T240 (D-055).
- ✅ **T222** Debug `?unlock=all` / `-- unlock=all` para playtest.

## Fase 4 — Grandes Orações
- **T230** SANCTUS, DOMINUS, ANGELUS (7 letras).
- **T231** SPIRITUS, SALVATOR, MISERERE (8 letras).
- **T232** Integração `test_orations.gd` (atril 7–8).

## Fase 5 — Fechamento
- **T240** Parecer do rules-agent sobre os números finais; stress com PURGO/MISERERE/DOMINUS (SC-202, SC-205).
- **T241** Export web, GUT, `FEATURES.md` (002 → Complete), `CLAUDE.md`, `docs/DECISIONS.md`.
