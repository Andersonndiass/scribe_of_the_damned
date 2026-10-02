# T1830 — Parecer do rules-agent: letras mais raras e selos de atributo (D-098)

> 2026-10-01 · Skill: `game-development/game-design`. Fontes: D-085…D-098, T1820, `letter_menu`, `letter_offer_roll`, `letter_dropper`, `drop_tuning`, `letter_safety`, `champion`, `combo`, `wave_01…09`, inimigos, armas, `seal_pool`, `run_upgrade`, `grace`, `potions`, `player_projectiles`, `enemy_manager`.

**PARECER: VÁLIDO COM RESSALVAS** (R1 combos, R2 chefe, R3 sonda × humano).

## Parte 1 — Letras mais difíceis (alvo do autor: ~1 palavra a cada 2 min)

Hoje: ~0,86–1,0 palavra/min. Alvo 0,5/min ≈ ×0,55 no fluxo de letras úteis.

**A (principal): menos menus** — `letter_drop_mul` × 0,55 em todas as ondas (substitui a alavanca pendente `wave_01` 1,2 → 1,0 da T1820):

| Onda | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|---|---|---|---|---|---|---|---|---|---|
| Antes | 1,20 | 0,90 | 0,80 | 0,70 | 0,57 | 0,55 | 0,47 | 0,42 | 0,45 |
| Depois | **0,66** | **0,50** | **0,44** | **0,39** | **0,31** | **0,30** | **0,26** | **0,23** | **0,25** |

**B (a Graça não quebrar):** `grace.tres` `per_letter` 10 → **16** (cada milagre vale mais; não 20, para a onda 1 não passar de 3 níveis). Curva e 1º nível sem mudança.

**C (reserva):** `LetterMenuTuning.useful_chance` (novo) 1,0; vai a 0,8 só se o aceite H falhar, e só com uma tecla de "descartar" o menu.

Não mexer: raras, campeão, LUMEN, Tinteiro Duplo, chance por HP, `menu_time`.

**Aceites** (capítulo ×5, mediana; e H = react 1,0 / acerto 1,0 ×3):
L1 palavras/min 0,40–0,60 · L2 menus/min 2,8–4,0 (onda 1 4,0–5,5) · L3 1ª palavra até 125 s em ≥ 4/5 · L4 maior intervalo entre palavras ≤ 4 min em ≥ 4/5 · L5 1º nível 12–20 s · L6 níveis o1/o9/final 2–3 / 1–2 / 15–17 · L7 Graça de palavras 8–20% · L8 Iluminura ≤ 15% · L9 tinta e compras sem regressão · H ≤ 0,65 (senão alavanca C).

## Parte 2 — Selos de atributo (resposta 2b)

- Base = o nível 1 de hoje. Cada selo sobe 1 posto de um atributo; nível = 1 + compras, até 7 (`max_upgrades` 6). A soma dos postos é 7–9: não dá para pegar tudo (build).
- Até os 3 selos podem ser da mesma arma, nunca o mesmo atributo duas vezes; o atributo é sorteado entre os que não chegaram ao teto; continua a garantia de 1 selo de arma.

| Arma | Atributos (teto) |
|---|---|
| Pena | CADÊNCIA 0,80/0,71/0,63/0,56 (3) · +1 GOTA 2/3 (1) · TAMANHO 6/8/10 (2) · LENTIDÃO 1,0/0,80 por 1 s (1) |
| Bíblia | CADÊNCIA 0,70/0,60/0,52/0,46/0,42 (4) · +1 ALVO 2/3 (1) · TAMANHO alcance 200/230/260 e largura 6/8/10 (2) |
| Crucifixo | CADÊNCIA 0,80/0,70/0,60/0,53/0,47 (4) · TAMANHO largura 8/10/12 e alcance 140/160/180 (2) · DANO 4/6 (1) |
| Rosário | +1 CONTA 3/4/5 (2) · TAMANHO raio 36/40/44/48 (3) · GIRO período 1,6/1,45/1,3 (2) · DANO 1/2 (1) |
| Turíbulo | CADÊNCIA 1,2/1,1/1,0 (2) · TAMANHO 40/46/52 (2) · INCENSO 1,0/1,75/2,5 s (2) · DANO 1/2 (1) · LENTIDÃO 0,80 por 0,6 s (1) |
| Aspersório | CADÊNCIA 1,10/0,97/0,85 (2) · +1 GOTA 4/5/6 (2) · TAMANHO alcance 64/72/80 e largura 4/5/6 (2) · DANO 1/2 (1) · LENTIDÃO 0,85/0,75 por 1 s (2) |

- Lentidão: piso 0,75 (as palavras AQUA/SANCTUS seguem mais fortes), sem acúmulo, metade no campeão, nada no chefe.
- Desempenho: pior caso muito abaixo das 200 vagas de projéteis; validar `count` ≤ 6, `interval` ≥ 0,40 (0,29 no tick da Bíblia), `trail_life/trail_every` ≤ `trail_cap`, `slow_factor` ≥ 0,75.
- Dados: `WeaponUpgradeData` (id, rótulo, ícone, `effects` campo → valores por posto); `WeaponData.upgrades` + `max_upgrades`; `WeaponLevelData.slow_factor/slow_time`; `WeaponSlot.ranks`; `BlessingData.target` = atributo; `EnemyManager.apply_slow`.
- Rótulos: CADÊNCIA, +1 GOTA, +1 ALVO, +1 CONTA, TAMANHO, DANO, LENTIDÃO, GIRO, INCENSO (EN: FIRE RATE, +1 DROP, +1 TARGET, +1 BEAD, SIZE, DAMAGE, SLOW, SPIN, INCENSE).
- Aceites: onda 1 sem god igual (base igual); #10 ≤ 1,25× a mediana com 2/4/6 compras; arma no nível 7 entre as ondas 4 e 7; nível final 15–17; stress no teto sem regressão.

## Ressalvas
- **R1 (autor):** com ~1 palavra a cada 2 min, a janela de combo de 2,5 s quase nunca é usada; FLAMMA, VAPOR, REQUIEM, CAECITAS e MARTYRIUM viram raridade. Aceitar ou mudar a regra.
- **R2:** na campanha o chefe herda o `letter_drop_mul` da onda 9 (cairia a 0,25). Proposta: `BossData.letter_drop_mul` 0,45 ao surgir o chefe.
- **R3:** com o menu pausado a sonda (react 0,8, acerto 0,9) subestima o humano: aceite H.
- Fora de escopo: MARTYRIUM tem 9 letras e Y (combo, não digitado); conferir na D-052.
