# T1200 — Parecer do rules-agent: 012 Capítulo 2, A Mãe das Traças

> 2026-10-03 · Skill: `game-development/game-design`. Vinculantes: D-102, D-107.
> Base: `data/chapters/chapter_1.tres`, `data/waves/chapter_1/*`, `data/enemies/*`, `data/bosses/asmodeus*` + `attacks/`, `data/tuning/{boss_damage_filter,letter_safety}.tres`, T1700 §3, T1820, T1900, T1000, D-062, D-098, ASSET-CATALOG §5.

**PARECER: VÁLIDO COM RESSALVAS** (R1–R9). Nenhuma palavra nova. Todo número vai para `.tres`; "medir" = sai da sonda, com a alavanca indicada.

## 1. `data/chapters/chapter_2.tres`
| Campo | Valor | Justificativa |
|---|---|---|
| `chapter` | 2 | — |
| `waves` | `wave_01..09` de `data/waves/chapter_2/` | D-102 |
| `boss` | `data/bosses/mae_tracas.tres` | FR-1201 |
| `intro_cutscenes` | `[]` (virada de página e abertura por escriba via `pending_intro`) | FR-1205 |
| `boss_cutscene` / `outro_cutscene` | `&"c2_01"` / `&"c2_02"` | D-102, D-107 6a |
| `arena` | `data/arena/chapter_2.tres` | — |
| `boss_stage` | 3 | ≥ estágio da onda 9 |

## 2. As 9 ondas (`data/waves/chapter_2/wave_NN.tres`)
Spawn **+8–15% acima da onda equivalente do Cap. 1**; crias somam pressão. `letter_drop_mul` recalculado para o **mesmo fluxo de letras do Cap. 1** (FR-1203, D-098). Grupos com `start_time` 0 e `end_time` = `duration` salvo indicação; formato `início→fim /max_alive`. `chapter = 2`, `index = N`, `min_spawn_distance` 96.

| Onda | `duration` | Grupos | Total fim (C1) | `letter_drop_mul` | Campeão (pool @ s) | `degradation_stage` |
|---|---|---|---|---|---|---|
| 1 | 60 | imp 0–20 s 0,5→1,0 /60 · imp 20–60 s 1,0→1,4 /60 · moth 0,15→0,25 /6 | 1,65 (1,5) | 0,70 | 0 | 0 |
| 2 | 65 | imp 0,8→2,0 /60 · moth 0,15→0,3 /8 · ink_blot 0,05→0,15 /5 | 2,45 (2,3) | 0,50 | 0 | 0 |
| **3** | 70 | **moth_mother 0,4→0,8 /14** (sozinha + crias) | ≈3,2 mortes/s (2,55) | 0,48 | 1 (imp @ 38,5) | 1 |
| 4 | 75 | imp 1,0→2,2 /70 · moth_mother 0,15→0,3 /6 · moth 0,15 /6 · ink_blot 0,15→0,3 /10 | 2,95 (2,85) | 0,30 | 1 (imp, blot @ 41,2) | 1 |
| 5 | 80 | imp 1,2→2,4 /80 · mãe 0,2→0,3 /8 · moth 0,15 /6 · blot 0,2 /10 · gargoyle 0,1→0,2 /6 | 3,25 (3,05) | 0,24 | 1 (imp, blot, garg @ 44,0) | 2 |
| 6 | 85 | imp 1,3→2,5 /85 · mãe 0,25 /8 · moth 0,2 /8 · blot 0,2 /10 · garg 0,15 /7 · hollow_monk 0,1→0,2 /6 | 3,5 (3,15) | 0,22 | 1 (4 tipos @ 46,8) | 2 |
| 7 | 85 | imp 1,5→2,7 /95 · mãe 0,3 /10 · moth 0,2 /8 · blot 0,25 /12 · garg 0,2 /8 · monk 0,2 /8 | 3,85 (3,5) | 0,19 | 1 (4 tipos @ 46,8) | 3 |
| 8 | 90 | imp 1,7→2,9 /105 · mãe 0,3→0,4 /10 · moth 0,25 /8 · blot 0,3 /14 · garg 0,25 /10 · monk 0,25 /10 | 4,35 (3,9) | 0,17 | 1 (4 tipos @ 49,5) | 3 |
| 9 | 90 | imp 1,9→3,1 /115 · mãe 0,35→0,45 /12 · moth 0,25 /8 · blot 0,3 /15 · garg 0,3 /12 · monk 0,3 /12 | 4,7 (4,35) | 0,18 | 1 (4 tipos @ 49,5) | 3 |

- **Apresentação na onda 3** (1ª com campeão, D-019): só a Traça-Mãe pequena + o campeão Diabrete. Ondas 4–9: no elenco.
- Total 700 s (C1: 695). `champion_pool` sem a Traça-Mãe (como a Traça, D-040; R8).
- `letter_drop_mul` = estimativa; medir. Aceite T1820: menus/min 5,0–6,5 por onda, onda 9 ≥ 4,5. Alavanca: `letter_drop_mul` ±0,02.

## 3. `data/enemies/moth_mother.tres`
| Campo | Valor | Justificativa |
|---|---|---|
| `id` | `&"moth_mother"` | — |
| `max_hp` | 4 | 1 golpe da arma nv 3–4 (como o Monge) |
| `move_speed` | 32 | lenta (bolsa de ovos) |
| `radius` | 6 | ficha 12 |
| `contact_damage` | 1 | a ameaça são as crias |
| `flying` | true | passa sobre os furos |
| `letter_drop_chance` | 0,10 | entre Diabrete e Borrão |
| `grace` / `wax_drop_chance` | 3 / 0,01 | crias +1 cada |
| `telegraph_time` | 0,5 | padrão |
| **novo** `burst_enemy` | `data/enemies/moth.tres` | D-107 2a |
| **novo** `burst_count` | 3 | — |
| **novo** `burst_radius` | 14 px | — |
| **novo** `burst_max_alive` | **14** traças vivas no total (grupo `moth` + crias); a que passaria do teto não nasce | D-107 2a; pools aquecem para 14 |
| **novo** `burst_grace` | 0,4 s sem contato e sem roubo do atril | matar colado não rouba na hora |

Crias usam `moth.tres` (drop 0,04 × `letter_drop_mul`). FR-1208: cria morta por zona letal conta como morte normal e não estoura de novo.

## 4. Chefe `data/bosses/mae_tracas.tres`
**Vida:** dano típico no chefe (filtro 250/500): LUX 20, CRUX ~100–200, IGNIS ~160, MORTIS 175, DOMINUS 250, Grandes Orações ~375; PAX/VITA/AQUA/FIDES/LUMEN 0. ~90/palavra × ~10 palavras = **900** (medir; alavanca `max_hp` 700–1.100, passo 100).

| BossData | Valor | BossData | Valor |
|---|---|---|---|
| `max_hp` | 900 (medir) | `min_telegraph` | 0,6 |
| `body_radius` | 26 (80×64) | `phase_shift_invulnerable` | 1,5 |
| `contact_damage` | 2 | `exposed_time` / `exposed_word_bonus` | **0 / 0** (FR-1213) |
| `move_speed` | 16 | `stun_mul` | 0,33 |
| **novo** `word_only` | true: lista branca (só palavra/combo) | **novo** `max_y` | 130 (hoje `const` em `boss.gd`; R3) |

| PhaseData | `threshold` | `interval` | `idle_frame_ms` | Ataques: pesos |
|---|---|---|---|---|
| `mae_tracas_phase_1` | 1,0 | 1,8 | 110 | Wing_Gust 60 · Swarm_f1 40 |
| `mae_tracas_phase_2` | 0,66 | 1,5 | 70 | Gust 40 · Swarm_f2 35 · Dust 25 |
| `mae_tracas_phase_3` | 0,33 | 1,5 | 70 | Gust 40 · Swarm_f2 30 · Dust 30 + **Eat_Page por relógio** |

| AttackData | `kind` | tel / ativo / rec | `damage` | Forma | Efeito |
|---|---|---|---|---|---|
| `wing_gust` | **novo** `gust` | 0,8 / 0,3 / 0,5 | 1 | cone `reach` 128, `arc_degrees` 100, mirado | empurra 64 px (**novo** `push`) escriba e crias; `cooldown` 0 |
| `swarm_f1` | `summon` | 0,8 / 0,1 / 0,5 | 0 | anel 48 | `moth` ×4, `summon_max_alive` 8, `cooldown` 9 |
| `swarm_f2` | `summon` | 0,8 / 0,1 / 0,5 | 0 | anel 48 | `moth` ×6, `summon_max_alive` 10, `cooldown` 7 |
| `dust_cloud` | **novo** `dust` | 0,9 / 0,2 / 0,5 | 1 (na queda) | círculo 40 no escriba | poça 3,5 s, lentidão ×0,65 (**novo** `slow_factor`, `min` com o Borrão); 1 por vez; `cooldown` 6 |
| `eat_page` | **novo** `eat_page` | **2,5** / 0,5 / 0,6 | 0 | faixa na borda | abaixo |

- **Crias = fonte de letras (FR-1211):** **novo** `AttackData.summon_letter_drop` = **0,35** (−1 = a do inimigo). F1 ≈ 9,5 menus/min (~28 s/palavra); F2/F3 ≈ 14 menus/min (~20 s). LetterSafety sem mudança. Alavanca: 0,25–0,50, depois `cooldown` do Swarm.
- **Eat_Page (só F3, D-107 4a), por relógio:** `PhaseData.timed_attack` = `eat_page`, `timed_interval` 15 s, `timed_first_delay` 5 s (só a fase 3).
  - **Cancelamento:** palavra/combo que fere ou atordoa a Mãe nos 2,5 s de aviso (PAX e DOMINUS contam; VITA, AQUA, FIDES não). O relógio recomeça igual.
  - **Passo:** esquerda/direita 48 px, baixo 46 px; cima nunca. Escolhe a borda de mais folga; empate alterna esq./dir.
  - **Mínimo:** 592×312 → **400×220** em 6 mordidas; final `Rect2(120, 24, 400, 220)`. Nunca cresce.
  - **Novos** `eat_step_side` 48, `eat_step_bottom` 46, `eat_min_size` (400, 220), `eat_push_speed` 180 px/s. Só empurra: sem dano, sem vela.
- Todo ataque ≥ 0,6 s de telegrafia (SC-1206). Guarda (D-100) imune.

## 5. FR-1213 confirmado
Sem janela de exposição; DOMINUS atordoa 1 s e, no aviso do Eat_Page, cancela. Tetos da 006 inalterados.

## 6. Aceites da sonda (`-s tools/balance_probe.gd -- …`; ≤ 2 Godot)
`chapter=2` é argumento novo, separado de `chapter`.

| # | Comando | Aceite |
|---|---|---|
| A1 | `cast chapter=2 wave=1 kite potions char=<id>` ×5 | Anselmo ≥ 4/5, demais ≥ 3/5. Falhou: tirar `moth` da onda 1, depois `spawn_rate_end` 1,4 → 1,3 |
| A2 | `cast chapter=2 wave=9 kite potions` ×3 | derrota 3/3; tempo vivo ≤ o do Cap. 1 |
| A3 | `cast god chapter=2 chapter buy grace only_waves kite potions` ×5 | palavras/min 0,40–0,60 · menus/min 5,0–6,5, onda 9 ≥ 4,5 · 1º nível 12–20 s · nível final 15–17 · tinta 80–100 · compras 6–8 · STUCK ≤ Cap. 1 |
| A4 | A3 sem `god`, Cap. 1 e 2, ×5 | onda mediana de morte Cap. 2 ≤ Cap. 1; nenhuma morte antes da onda 3 em ≥ 4/5 |
| A5 | `cast god boss chapter=2 unlock=all atril=6 wlevel=5 grace` ×5 (+ ×3 `char=beda`) | BOSS: 180–240 s, 20–30 s entre palavras, 7–12 palavras; Beda ≤ 300 s. Também com `norelics` e `relics=reverse_magnet,blessed_salt rlevel=3` |
| A6 | linha `EATPAGE` de A5 | 4–6 tentativas na F3; área ≥ 400×220; nunca cresce; STUCK 0 (10 lutas) |
| A7 | A5 sem `god` ×5 | medir (playtest) |

## Ressalvas
- **R1:** o catálogo diz "F2: swarm solta 12"; D-107 2a prevalece: 6 por liberação, teto 10.
- **R2 (bloqueia A5):** a sonda do chefe trava na F3 (D-081); corrigir antes.
- **R3:** `boss.gd` tem `HOME`/`MIN_Y`/`MAX_Y` `const` e `Arena.PLAYABLE` é fixo; passar a dados.
- **R4:** `max_hp` 900 é estimativa.
- **R5:** ~10–14 menus/min no chefe com pausa; avaliar no playtest (alavanca `summon_letter_drop`).
- **R6:** relíquias cortam palavras (T1900); se a diferença passar de 1,5×, ajustar a chance de letra antes da vida.
- **R7:** Beda (atril 4) tem menos dano por palavra; aceite ≤ 300 s.
- **R8:** Traça-Mãe fora do `champion_pool`; proposta futura: `burst_count` ×2.
- **R9:** emendar a bible §3.8 ("Cap. 2 tem 9"; "estoura em 3 Traças comuns").

## 7. Medição e ajustes (2026-10-03, F7)
- **A5/A6 (luta):** com 900 PV, 4,5–11,8 min (Anselmo ×5), Beda até 12 min → rules-agent: **550 PV** e cria do enxame com letra **0,50** (`moth_brood.tres`; no lugar de `summon_letter_drop`, com `BossData.letter_drop_mul` 1,0 na luta). Remedido: Anselmo 5,9–9,0 min, Beda 3,9–5,3 min; mediana 25–35 s entre palavras; 8–15 palavras. **Diagnóstico:** toda palavra de ataque acerta; metade das palavras do bot é de apoio (PAX, VITA, AQUA, GLORIA, LUMEN = 0 de dano no chefe só-palavras) → o bot superestima a luta; ~5 palavras de ataque fecham 550 PV. Fica para o playtest (alavanca `max_hp`).
- **EATPAGE:** 0–6 tentativas por luta; o bot quase nunca cancela (não mira o aviso); área chega a 400×220; **fora = 0** em todas (SC-1204 ✅). A trava da sonda do chefe (D-081) não apareceu em 20 lutas da Mãe.
- **A1 (onda 1 sem god):** primeiro Anselmo 3/5, Beda 1/3 → recuo previsto: **sem o grupo de Traças na onda 1** → Anselmo 5/5, Beda 3/3 ✅.
- **A3 (ritmo):** capítulo completo 4/4, nível 14–15, tinta 71–79, 5–6 compras ✅; palavras/min 0,24 (Cap. 1: 0,44) → `letter_drop_mul` ondas 2–9 = 0,60/0,60/0,55/0,50/0,47/0,43/0,41/0,41 e Traça comum `max_alive` 4/4/6/6/6/6 nas ondas 4–9 (menos roubo do atril). Menus por onda voltaram ao nível do Cap. 1; palavras/min seguem ruidosas (0,08–0,62). Último passo do rules-agent (+0,05 nas ondas 4–9: 0,55/0,50/0,47/0,43/0,41/0,41), n=6: capítulo 6/6, nível 14–16, **menus por onda acima do Cap. 1** (3–18), mas palavras/min 0,16/0,16/0,16/0,31/0,39/0,53 (mediana ~0,24). Conclusão: falta conversão letra → palavra (Traças roubando do atril, bot), não letra; parar de subir `letter_drop_mul`. **Aberto para o playtest** (alavanca seguinte: teto de Traças e o `burst_count`).
- **SC-1209:** `?stress=boss2` no desktop: média 60 / p95 55,8; sem `instantiate` além do aquecimento. Chrome: autor.
