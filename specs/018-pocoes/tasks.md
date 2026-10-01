# 018 — Tasks

> Ordem do mechanics-agent (T1801) + o subir de nível da D-095. Cada fase fecha com GUT + export web + commit. Agentes: tarefas simples com Sonnet, difíceis com Opus. Arte nova com a skill `pixel-art-gen`; telas/HUD conferidas com a skill `ui-ux-game`.

## Fase 1 — Subir de nível e banco
- **T1801** Curva da Graça (`level_costs [16, 40]`, base 8, passo 28) + `validate()` checa `level_costs[0]`.
- **T1802** Parecer curto do animation-agent e do design-agent para o feixe dourado e a barra da câmera lenta (2,5 s); desenho do feixe com a skill pixel-art-gen.
- **T1803** `GraceFlow`: fase de feixe (câmera lenta pelo `TimeScale`, dono `level_up`) antes de pausar; barra; fila com 1 feixe só; testes.
- **T1804** Banco (o6) em (184, 272) + sonda ARENA/STUCK.

## Fase 2 — Poções: base, uso e HUD
- **T1805** `PotionData`/`PotionLevelData`/`PotionTuning` + 4 `.tres` + validação.
- **T1806** `PotionBelt` no `GameState` (1 Óleo no começo).
- **T1807** Ações `potion_1..4` (3–6) + `Settings` (contexto play).
- **T1808** `PotionUser` (FSM, guardas, sinais `potion_drunk/refused/effect_ended/charges_changed/leveled`).
- **T1809** Óleo da Unção (vela + invulnerabilidade por nível).
- **T1810** HUD: `POTION_SLOTS = 4`, ícones da skill, estados do design-agent, `DIM_POTION`, feedback de recusa.

## Fase 3 — Vinho e Iluminura
- **T1811** `cadence_mul` no Arsenal (só o espaço do momento; piso 0,55; Bíblia e Rosário).
- **T1812** `LetterMenu.can_open_now/open_now` + Iluminura (úteis 1/2/3 por nível; cantoneiras nas 3 cartas).

## Fase 4 — Água Benta
- **T1813** `RefugeZones` + barra no `EnemyManager._place` + expulsão inicial.
- **T1814** Travas: heresia dentro apaga; parado dentro não recupera vela.
- **T1815** `RefugeCircle` (anel + marcadores) + `?stress=refuge`.

## Fase 5 — Loja, selo e VITA
- **T1816** Prateleira fixa (`ShopOffer`/`Shop`/`ShopScreen`, ↑/↓ entre cartas e prateleira) + a sonda compra poção.
- **T1817** `SealPool` tipo poção (`BlessingData.target`, peso 0,08; status 0,37) + `RunUpgrade`.
- **T1818** VITA acende 2 velas.

## Fase 6 — Passada de ritmo
- **T1819** Sonda nova (distância = alcance, ≥ 3 rodadas, capítulo inteiro, onda 9 sem god; o bot bebe poções).
- **T1820** Ajustes pela lista do rules-agent (T1801 §5) com parecer novo.
- **T1821** Docs: art bible, FEATURES, CLAUDE.md, DECISIONS.
