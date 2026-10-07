# 012 — Tasks (Capítulo 2: A Mãe das Traças)

> Pareceres: `docs/reviews/T1200-rules-parecer.md` (números) e `docs/reviews/T1200-mechanics-parecer.md` (sistemas). Decisões: D-102, D-107.
> Conciliação: o Eat_Page roda por **relógio** (`PhaseData.timed_attack/timed_interval/timed_first_delay`, rules §4), não por peso; os números são do rules-agent, a arquitetura do mechanics-agent.
> Cada fase: GUT inteiro + export web + commit.

## F1 — Capítulo, liberação e abertura
- [x] T1201 `data/chapters/chapter_2.tres`, `data/waves/chapter_2/wave_01..09.tres` (rules §2), `data/arena/chapter_2.tres` (biblioteca roída: peças do Cap. 1 + mais furos) + camadas placeholder em `assets/arena/chapter_2/`.
- [x] T1202 `data/ui/chapters.json` `unlock_after`; `Progress.is_chapter_open(n)`; `chapter_screen.gd` abre o Cap. 2 depois de vencer o Cap. 1.
- [x] T1203 `pending_intro`: abertura do escriba só no Cap. 1; `c2_00.json` (virada de página, `ENV_PAGE_TURN` placeholder).
- [x] T1204 `screen_router.gd` `?chapter=N` (+ `?boss`, `?char=`); zera `run_counts`.
- [x] Testes: `test_chapter_2_data`, `test_chapter_unlock`, `test_pending_intro`.

## F2 — Traça-Mãe pequena
- [x] T1210 `BurstOnDeathBehavior`, fila de estouro no `EnemyManager` (`queue_burst/_flush_bursts`), sinal `brood_burst`, `burst_grace`.
- [x] T1211 `data/enemies/moth_mother.tres` (rules §3) + sprite placeholder (ficha 12, design-agent).
- [x] Testes: `test_burst_on_death`.

## F3 — Imunidade (só palavras ferem)
- [x] T1220 `BossData.words_only`, `immune_feedback_interval`; `BossDamageFilterData.non_word_tags`; filtro e `last_block`; `boss_immune_hit`; chefe fora da mira das armas.
- [x] T1221 Retorno visual "imune" (design + animation).
- [x] Testes: `test_boss_damage_filter` (SC-1202), `test_boss_immune_feedback`, `test_weapon_targeting_immune`.

## F4 — A Mãe (sem Eat_Page)
- [x] T1230 `mae_tracas.tres` + 3 fases + `wing_gust`, `swarm_f1`, `swarm_f2`, `dust_cloud` (rules §4); cria do enxame `moth_brood.tres` (Traça com chance 0,35) + `BossData.letter_drop_mul` 1,0 na luta (no lugar de `summon_letter_drop`); `BossData.sprite_size/phase_overlays/max_y` (tira as `const` de `boss.gd`).
- [x] T1231 `GustAttack`, `DustAttack`, `Player.shove`.
- [x] T1232 Sprite placeholder 80×64 (ficha 17, design-agent + pixel-art-gen).
- [x] Testes: telegrafia ≥ 600 ms (SC-1206), vento sem atravessar parede, poça, teto do enxame, sem exposição.

## F5 — Eat_Page e área que encolhe
- [x] T1240 `PlayArea`; `EatPageAttack` (aviso 2,5 s, cancelamento por palavra/atordoamento, passo 48/46, mínimo 400×220, só F3 por relógio 15 s); sinais `page_bite_*`, `play_area_changed`.
- [x] T1241 Usuários da área: Player (`push_inside`), paredes do Arena, EnemyManager, ObstacleMap (peças da faixa somem), Boss `_drift`, SummonAttack, tinta/cera; `EatenEdgeView`.
- [x] Testes: `test_play_area` (SC-1203), `test_eat_page_cancel`, `test_eat_page_obstacles`, `test_eat_page_push`.

## F6 — Cutscenes e fim do capítulo
- [x] T1250 `c2_01.json` e `c2_02.json` com `@player` e variantes (story-agent); verbete da Traça-Mãe pequena; i18n.
- [x] T1251 Vitória → `chapter_completed(2)`, Cap. 3 selado "em breve".
- [x] Testes: `test_chapter_2_flow` (SC-1201), cutscenes com os 5 escribas (SC-1210).

## F7 — Sonda, stress e fechamento
- [x] T1260 Trava da sonda do chefe na F3 (D-081, R2): não apareceu em 20 lutas da Mãe (Asmodeus não remedido).
- [x] T1261 Sonda `chapter=2`, `fight`, linha `EATPAGE`; `?stress=boss2`.
- [x] T1262 Baterias A1–A6 (rules §6); ajustes pelo rules-agent.
- [x] T1263 Áudio dos ataques novos no manifesto (audio-agent; geração pelo autor).
- [x] T1264 Game bible §3.8 (R9), FEATURES, CLAUDE.md, DECISIONS, README.
