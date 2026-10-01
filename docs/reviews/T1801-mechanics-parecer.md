# T1801 — Parecer do mechanics-agent: 018 Poções

> 2026-10-01 · Reaproveita o que existe: injeção pelo Main, registro estático (como `KillZones`), `BlessingData.kind`, `ShopItemData.kind`. Sem `instantiate()` na onda. Números: rules-agent (T1801R).

## Estados
**PotionUser** (Node filho do Player, pausável): OFF →(wave_started/boss_spawned, vivo) READY →(beber, guardas ok: gasta 1 carga, `potion_drunk`) GAP →(use_gap) READY; beber com guarda falhando: `potion_refused(id, motivo)` sem gastar; wave_ended/shop_opened/player_died → OFF (encerra efeitos, motivo `wave_end`).
Guardas em ordem: READY (cobre loja, morte, fora da onda, intervalo → `gap`); menu da letra fechado (`blocked`); pausa e selos já não entregam input; escriba fora do `Stunned` (recomendado, pilar 3); `charges > 0` (`empty`); Óleo: velas abaixo do máximo (`full`); Iluminura: `letter_menu.can_open_now()` (`menu_busy`).
Efeitos em tempo de jogo; a mesma poção renova a duração; poções diferentes coexistem.
- **Água Benta (RefugeZone):** INACTIVE → ACTIVE → (tempo | heresia com posição dentro | fim de onda) INACTIVE. No máximo 1 círculo.
- **Vinho:** preso ao espaço ativo no momento de beber (`fervor_slot`); trocar de arma não leva o efeito.

## Eventos
`potion_drunk(id, level, charges)`, `potion_refused(id, reason)`, `potion_effect_ended(id, reason: timeout|heresy|wave_end)`, `potion_charges_changed(id, charges, max)`, `potion_leveled(id, level)`. Usa `heresy_committed(pos)` (a perdoada pelo MISERERE não apaga), `player_healed`, `wave_started/ended`, `shop_opened`, `player_died`, `boss_spawned`.

## Componentes
- `PotionBelt` (RefCounted, `GameState.potions`): cargas e nível por id (0 = nunca comprada), efeitos em curso, `cadence_mul(slot)`; começa com Óleo nv 1, 1 carga.
- `PotionUser` (FSM acima), `RefugeZones` (estático: set/clear/contains), `RefugeCircle` (Node2D na cena, anel abaixo dos inimigos), `LetterMenu.can_open_now()/open_now()` (abre na hora, pulando o GAP; falso sem opções = não gasta).
- **Óleo:** `player.heal(level.heal)`.
- **Água Benta:** `RefugeZones.set(pos, r)` + `EnemyManager.repulse` inicial; barra no `_place(i, p)` (funil único: 1 distância² por inimigo por passo, só com o círculo ativo) — comuns, voadores e campeões; o chefe não. Projéteis inimigos não são barrados. Trava da heresia (escuta `heresy_committed`); trava da vela: no Player, `idle` falso dentro do círculo.
- **Vinho:** `Arsenal.interval_of` × `cadence_mul(slot)`, também no `_interval_mul` (Rosário, Turíbulo) e no tick da Bíblia; piso `cadence_floor` com a Pena de Ganso.
- **Iluminura:** `letter_menu.open_now()`.

## Dados
`PotionData` (`data/potions/<id>.tres`: id, effect heal|refuge|fervor|illumination, display_name, short_desc, icon, levels, max_charges), `PotionLevelData` (heal, duration, radius, interval_mul, expel, campos da Iluminura), `PotionTuning` (`data/tuning/potions.tres`: order = teclas 3–6, use_gap, cadence_floor, start {oil: 1}), `GraceTuning.seal_potion`, `BlessingData.target`, `ShopItemData.kind = potion` + `potion`, `ShopTuning.potion_shelf`.
- Loja: prateleira fixa fora de `cards` (sem reroll nem trava), `buy_shelf` respeita o teto, pode comprar várias vezes na visita; `ShopScreen` ganha 2ª fileira (layout do design-agent); a sonda compra poção.
- Input: `potion_1..4` = 3..6, contexto play, trocáveis (conflitam com `weapon_1/2`, não com `grace_pick_*`).
- HUD: `POTION_SLOTS = 4`; ícone, tecla, cargas, nível; barra = duração restante; sem carga = esmaecido; zero GOLD.

## Performance
`_place` com o círculo: 1 distância² por inimigo por passo; medir `?stress=refuge`. Nenhum `instantiate()`.

## Testes
Unit: potion_belt, potion_user (recusas sem gastar, renovar, coexistir, fim de onda), arsenal (Vinho só no fervor_slot, piso), enemy_manager_refuge (ninguém entra; chefe não é barrado; expulsão), refuge (heresia dentro/fora/perdoada), player_vitals_refuge, letter_menu (`open_now`), seal_pool (tipo poção), run_upgrade, shop_offer (prateleira), settings, potion_data, weapon_bar (não cobre o banco). Integração: test_potion_flow.

## Fases
1. Base e banco: T1802 banco da arena; T1803 dados + 4 .tres; T1804 PotionBelt; T1805 ações.
2. Usar e HUD: T1806 PotionUser; T1807 Óleo; T1808 HUD.
3. Vinho e Iluminura: T1809 cadence_mul; T1810 open_now + Iluminura.
4. Água Benta: T1811 RefugeZones; T1812 travas; T1813 RefugeCircle + `?stress=refuge`.
5. Loja e selo: T1814 prateleira; T1815 SealPool tipo poção.
6. Passada de ritmo: T1816 sonda nova; T1817 ajustes (inclui o custo do nível 1→2, D-094).

## Perguntas abertas
1. Água Benta bebida de novo: recentraliza no escriba (recomendado) ou só renova o tempo?
2. Vinho: preso ao espaço do momento (recomendado) ou segue a arma ativa?
3. Beber atordoado: bloquear (recomendado)?
4. Iluminura: o que cresce nos níveis 2+?
5. Confirmar que a luta do chefe liga o PotionUser (`boss_spawned`).
