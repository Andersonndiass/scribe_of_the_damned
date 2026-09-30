# 004 — Tarefas

> Spec: `spec.md` (aprovada, D-078). Números dos obstáculos: rules-agent (2026-09-29). Sistema: mechanics-agent (2026-09-29).

## Fase 1 — Dados e regras (sem visual)
- ✅ **T400** [TEST-FIRST] `tests/unit/test_page_degradation.gd`: `PageDegradation` (máquina de estados STEADY → THREATENED → TRANSITIONING): o estágio segue o dado, **nunca volta** no capítulo (SC-401), só muda no fim da onda (SC-402), ameaça só quando o próximo estágio é maior; entrada direta (`?boss`, sonda `wave=N`, testes) aplica na hora.
- ✅ **T401** Dados: `WaveData.degradation_stage` das 9 ondas = 0, 0, 1, 1, 2, 2, 3, 3, 3; `ChapterData` ganha `arena` e `boss_stage` (3) e valida "não decrescente"; `WaveTuning` (`closing_warning` 10 s); sinais `wave_closing`, `page_stage_changed`, `page_degraded`, `arena_layout_changed`. O `Main` passa a mandar no estágio (fim da onda, `start_wave`, `start_boss`); o loop antigo do `arena.gd` sai; o teste do loop em `test_hud.gd` vira o SC-401.
- ✅ **T402** [TEST-FIRST] `tests/unit/test_arena_layout.gd`: `ObstacleTypeData`/`ObstacleData`/`ArenaData` (`data/arena/chapter_1.tres`, 7 peças do rules-agent: 4 furos, vitral, altar, banco; folga 0 ou ≥ 40 px); sem sobreposição; área livre **conexa** por flood fill para o escriba e para o maior inimigo campeão (SC-406); o `HOME` do chefe e o nascimento do escriba livres.
- ✅ **T403** `ObstacleMap` + `ObstacleQuery` (grade de 16 px pré-calculada; `constrain`, `blocks`, `is_free`, `nearest_free`, `clip_segment`) e a tabela "o que bloqueia o quê" em dados (valores do rules-agent: escriba e inimigos que andam = todos; Traça voa por cima; projéteis do jogador, palavras e ataques do chefe passam; tiros do Monge param no vitral e no altar; o dash da Gárgula para em todos).

**Checkpoint 004-A:** ✅ a página segue o capítulo por teste; o layout é válido e conexo (2026-09-29, GUT 396/396).

## Fase 2 — Colisão e nascimentos
- ✅ **T410** Escriba: corpos de colisão dos obstáculos (criados no setup, nada na onda). Inimigos: `EnemyManager._constrain` (empurra para fora com deslize; voadores isentos); contato não atravessa o banco; Gárgula para o dash e a telegrafia mostra o caminho cortado; tiros do Monge param onde a tabela manda.
- ✅ **T411** Nascimentos: spawn de inimigos e invocação do chefe nunca dentro (inflado pelo raio); letras, letra de segurança do chefe e tinta dourada empurradas para fora (6 px / 2 px, nunca descartadas).
- ✅ **T412** [TEST] `tests/integration/test_obstacles.gd`: inimigo do outro lado de cada obstáculo chega ao escriba; nada nasce ou cai dentro (10 mil sorteios); contato através do banco não fere; dash para na borda.
- ✅ **T413** Sonda: `balance_probe` com `obstacles=off`, `stage=N` e a métrica STUCK; comparação A/B (9 ondas, sem god, chefe) nas faixas do rules-agent (SC-407). Se sair da faixa, a alavanca é a posição dos obstáculos, não os números.

**Checkpoint 004-B:** ✅ obstáculos jogáveis e o balanceamento dentro das faixas (2026-09-29, GUT 405/405; SC-407 com ressalva, `docs/reviews/T413-rules-parecer.md`).

## Fase 3 — Visual em camadas
- ✅ **T420** Pareceres: design-agent (formas de cada estágio no tema da rasura, cor das brasas sem BLOOD, texto-fantasma, ornamentos, sombra e borda dos obstáculos, **conferir o altar e os furos de cima sob o HUD** — se colidir, trocar altar e banco de lugar), animation-agent (revelação do estágio, ameaça dos 10 s, poeira e brasas).
- ✅ **T421** `tools/gen_arena_placeholders.gd` → camadas 640×360 (fundo, texto-fantasma, ornamentos, estágio 1, 2, 3) e os obstáculos por tipo, pelas regras de pixel art (D-075/D-076), no teste de paleta byte a byte; arte do autor por camada em `assets/arena/chapter_1/`.
- ✅ **T422** `Arena` montado em camadas (Sprite2D em cache, decals mantidos), `StageReveal` (revelação em degraus) e ambientes (poeira no estágio ≥ 2, brasas no 3, ameaça na moldura).
- ✅ **T423** [TEST] SC-403 (nada na área central; só tons baixos na área jogável; sem BLOOD) e SC-404 (paleta).

**Checkpoint 004-C:** ✅ a página se gasta onda a onda, legível, com os obstáculos à vista (2026-09-29, GUT 412/412; D-080: altar e banco fora do HUD, SC-407 remedido e dentro das faixas).

## Fase 4 — Fechamento
- ✅ **T430** GUT, export web, SC-001 no estágio 3 com os obstáculos (SC-405), `FEATURES.md`, `CLAUDE.md`, `docs/DECISIONS.md`, push.
