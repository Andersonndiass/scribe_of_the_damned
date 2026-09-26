# 005 — Tasks

Legenda: `[P]` = paralelizável · `[TEST-FIRST]` = o teste é escrito e falha antes da implementação.

## Fase 1 — Fundação dos comportamentos
- ✅ **T500** Resources novos: `EnemyBehavior` (base), `EnemyProjectileData`, `PuddleData`, `ChampionTuning`, `ChapterData`; `EnemyData` + `behavior`, `flying`, `dash_contact_damage`; `WaveData` + `champions`, `champion_pool`, `champion_times`.
- ✅ **T501** EnemyManager: arrays de estado + chamadas `tick`/`desired_velocity`; `ChaseBehavior` substitui a perseguição fixa. **Todos os testes da 001 continuam passando.**
- ✅ **T502** Sinais novos no EventBus (data-model §8).

## Fase 2 — Os 4 inimigos novos
- ✅ **T510** [TEST-FIRST] `test_behaviors.gd`: Traça come a letra; Gárgula windup → dash → cooldown; Monge mantém distância e atira; Borrão deixa poça.
- ✅ **T511** `LetterEaterBehavior` + `LetterField.eat_letter_near` (ignora letras magnetizadas) + marca na letra-alvo + devolução das letras comidas ao morrer + Traça (`moth.tres`).
- ✅ **T512** `DasherBehavior` + linha tracejada da telegrafia + Gárgula (`gargoyle.tres`), com contato forte no dash.
- ✅ **T512b** CRUX: `arm_width` e `block_radius` em `crux.tres` (tira a constante do código; Princípio IV).
- ✅ **T513** [TEST-FIRST] `test_enemy_projectiles.gd` → `EnemyProjectileManager` (acerto, bloqueio pela CRUX, expiração, pool fixo).
- ✅ **T514** `RangedBehavior` + telegrafia das páginas + Monge Oco (`hollow_monk.tres`, `prj_page.tres`).
- ✅ **T515** [TEST-FIRST] `test_hazard_field.gd` → `HazardField` + `Player` lento na poça.
- ✅ **T516** `TrailBehavior` + Borrão (`ink_blot.tres`, `puddle_ink.tres`), com poça na morte.
- ✅ **T517** Placeholders dos 4 inimigos + gota dourada no `gen_placeholders.gd`, nos tamanhos do catálogo.

**✅ Checkpoint 005-A — ALCANÇADO (2026-09-25):** os 5 inimigos numa arena de teste (`index.html?roster`).

## Fase 3 — Campeões e tinta dourada
- ✅ **T520** [TEST-FIRST] `test_champions.gd`: multiplicadores, +1 vela, 3–5 gotas, hit-stop de 40 ms.
- 🔶 **T521** Campeão no EnemyManager + `outline.gdshader` + aura + telegrafia de 0.8 s. *(feito; falta o **shake médio** da morte: o jogo ainda não tem câmera/shake, vai para o animation-agent)*
- ✅ **T522** `GoldInkField` + gota pooled + ímã + `GameState.gold_ink`.
- ✅ **T523** HUD `ink_counter.gd` (canto superior direito; entra no teste de área central).

## Fase 4 — As 9 ondas
- ✅ **T530** `wave_01..09.tres` + `chapter_1.tres` (data-model §6).
- ✅ **T531** WaveDirector: sequência do capítulo, campeões agendados, `chapter_completed` + "CAPÍTULO COMPLETO".
- ✅ **T532** Integração `test_chapter1_waves.gd`: as 9 ondas com tempo acelerado, sem erro, zero instantiate (SC-501, SC-504).
- ✅ **T533** Parecer do **rules-agent** sobre a curva das 9 ondas + sonda de balanceamento por onda. → `docs/reviews/T533-curva-cap1.md`

## Fase 5 — Performance e fechamento
- ✅ **T540** Cena de stress "onda 9" (300 misturados + 60 projéteis + 20 poças) + medição no Chrome (SC-503).
- ✅ **T541** Export web, GUT, `FEATURES.md` (005 → Complete), `CLAUDE.md`, `docs/DECISIONS.md`.

**✅ Checkpoint 005 — ALCANÇADO (2026-09-25):** Capítulo 1 jogável da onda 1 à 9. SC-503 no Chrome: média 78–80, p95 60–65.
