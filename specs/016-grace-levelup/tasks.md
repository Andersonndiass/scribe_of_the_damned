# 016 — Graça: tarefas

> Ordem do mechanics-agent (parecer 2026-09-30). Números: rules-agent (spec). Cada fase termina com GUT + export web + commit.

## Fase 0 — Pareceres de visual e tempo
- ✅ **T1600** design-agent: selos (desenho sobre a página, 3 lado a lado, legíveis em 1×), barra de Graça no HUD (fora da área central), ícones das bênçãos (os 7 da loja + Tinta Consagrada + Graça plena), `ITM_` do pingo de cera; conferir a tela de Opções com as 3 ações novas. animation-agent: `announce_time`, `stamp_time`, brilho da barra, piscar do pingo.

## Fase 1 — Dados e lógica pura (teste primeiro)
- ✅ **T1601** `StatUpgradeData` (id, nome/frase `tr`, ícone, stat, modo, valor, teto, `heal_candles`); `ShopItemData` passa a herdar dela (os `.tres` antigos continuam carregando).
- ✅ **T1602** `BlessingData` + `GraceTuning` (`data/tuning/grace.tres`: por letra, ×combo, ×campeão, curva, `boss_grace_mul`, proteção 0,4 s, invulnerabilidade 0,5 s, lista explícita das bênçãos, reserva) com validação no load.
- ✅ **T1603** `RunStats`: `word_damage_mul` (começa em 1) e `has_stat`.
- ✅ **T1604** [TEST-FIRST] `GraceLedger` (em `GameState.grace`, recriado no `start_run`): ganho, limiar, fila de níveis, curva, não zera entre ondas/loja.
- ✅ **T1605** [TEST-FIRST] `BlessingOffer`: 3 distintas abaixo do teto, menos de 3, reserva, sorteio próprio com semente (não consome o `GameState.rng`).
- ✅ **T1606** Migrar os 7 itens para `data/blessings/` (tetos novos: Bolsa 1,4; Pena 0,56), criar `consecrated_ink` e `grace_full`; tirar do deck da loja; `shop_tuning` (2 vagas, dízimo 5, reroll 3+2); teste SC-1603.
- ✅ **T1607** `RunUpgrade.apply` extraído de `Shop._apply` (cura em dados, stat vazio não grava), usado pela loja e pelo level-up.
- ✅ **T1608** `EnemyData.grace` e `wax_drop_chance` nos 5 inimigos; textos em `i18n/ui.csv` (PT-BR e EN).

**Checkpoint 016-A:** ✅ números e sorteio testados; a loja nunca oferece os 7 (2026-09-30, GUT 431/431).

## Fase 2 — Fluxo e pausa
- ✅ **T1610** Sinais: `grace_gained`, `grace_changed`, `grace_leveled`, `seals_shown`, `blessing_chosen`, `seals_hidden`, `pause_menu_toggled`, `wax_drop_collected`.
- ✅ **T1611** `GraceFlow` (nó do Main, sempre ativo): FSM IDLE → ARMED → ANNOUNCING → CHOOSING → STAMPING, DEAD, SEALED; abre só no quadro seguinte ao ganho; relógio real (hit-stop não trava); `auto_pick` fora do jogo real.
- ✅ **T1612** `PlayerVitals.grant_iframes_for(s)`.
- ✅ **T1613** `GameOverlays`: não despausar com os selos abertos; `pause_menu_toggled`.
- ✅ **T1614** [TEST] `test_grace_flow`: a pausa congela tudo; proteção; fila; espera loja/cutscene; morte no mesmo quadro; Pausa por cima; fim do chefe.

**Checkpoint 016-B:** ✅ subir de nível pausa, escolhe e volta sem brigar com Pausa, loja, cutscene e Game Over (2026-09-30, GUT 440/440).

## Fase 3 — Dano
- ✅ **T1620** `Caster` compõe `damage_mul` = GLORIA × Tinta e `heal_mul` = só GLORIA; VITA e SALVATOR usam `heal_mul`; `test_miracle_damage` (cura igual com Tinta; D-051; filtro do chefe depois).

## Fase 4 — Selos, barra e teclas
- ✅ **T1630** Ações `grace_pick_1..3` (1/2/3 e teclado numérico) no InputMap, `Settings.REBINDABLE` e Opções.
- ✅ **T1631** `GraceSeals` (desenho em camadas, pelas regras de pixel art; clique, setas + confirmar).
- ✅ **T1632** `GraceBar` no HUD.
- ✅ **T1633** [TEST] `test_grace_input` + `test_hud`.

**Checkpoint 016-C:** ✅ jogável — o autor já pode testar (2026-09-30, GUT 448/448).

## Fase 5 — Pingo de cera
- ✅ **T1640** `wax_drop.tres`, `WaxDrop` + `WaxDropField` em pool, registro no Main, testes.
- ✅ **T1641** Placeholder do pingo no gerador.

## Fase 6 — Sonda e fechamento
- ✅ **T1650** `balance_probe`: linha GRACE (níveis por onda, % de palavras, primeiro nível, escolhas).
- ✅ **T1651** SC-1601 com o rules-agent (ajuste só de dados).
- ✅ **T1652** SC-001 + A/B dos obstáculos (SC-1605), no máximo 2 Godot rodando.
- ✅ **T1653** GUT, export web, emendas (003 FR-310/SC-306, game bible §3.9), `FEATURES.md`, `CLAUDE.md`, `DECISIONS.md`.
- **T1654** Playtest do autor (SC-1606).

**Fechamento (2026-09-30, D-086):** GUT 479/479; export web ok. SC-001 no Chrome igual ao build de antes da 016 (49,6/54,7 contra 51,3/56,2 FPS, alternados). Sonda do capítulo com a Graça (`cast god chapter buy grace only_waves`): nível 14, 13 subidas (3·2·1·1·1·2·0·2·1), 44% da Graça de palavras, 1º nível aos 17 s, 5 compras. O conteúdo dos selos e a proporção da Graça mudam na 017 (D-085); a curva é revista na passada de ritmo. T1654 (playtest do autor) segue aberto.
