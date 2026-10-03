# T1200 — Parecer do mechanics-agent: 012 Capítulo 2 (resumo)

> 2026-10-03 · Skills: game-development + 2d-games. Fontes: spec 012, D-102/D-107, constituição III–V, `src/bosses`, `enemy_manager.gd`, `src/arena`, `main.gd`, `chapter_screen.gd`, `screen_router.gd`, `cutscene_*`, `progress.gd`, `balance_probe.gd`.

## Achados no código
1. `EnemyManager.kill()` chama `on_death()` antes de `_remove(i)`: estourar ali corrompe os laços → **fila de estouro** esvaziada no fim do `_physics_process`.
2. `pending_intro()` põe `intro_<id>` em qualquer capítulo → só no cap. 1.
3. `Arena.PLACEHOLDER_PAGE` fixo no c1: resolvido gravando as camadas em `assets/arena/chapter_2/` (o `layer_dir` já prioriza).
4. `Boss` tem 64×64 e overlays fixos; a Mãe é 80×64 → `sprite_size`, `phase_overlays` em dados.
5. As armas miram por `EnemyQuery.nearest*`, que devolve o chefe → chefe `words_only` sai da consulta das armas.
6. `ArenaData.PLAYABLE`/`Arena.PLAYABLE` usados em ObstacleMap, Boss, SummonAttack, EnemyManager → passam a ler `PlayArea.rect`.
7. Armas, projéteis e Ímã Reverso marcam `&"auto"`; nenhuma poção fere hoje → imunidade = lista de tags.

## Estados
- **Capítulo:** `BLOQUEADO --chapter_completed(1) [run_counts]--> ABERTO` (latch em `Progress.chapters_won`); confirmar → `c2_00` (virada de página) → jogo.
- **Chefe:** FSM da 006 sem estado novo. `Telegraph(eat_page) --take(palavra, amount>0) [cancel_by_word]--> Recover` (`page_bite_cancelled`). Cancelamento olhado **antes** do filtro. Mordida em andamento termina no alvo (nunca volta).
- **EatPage:** `off → telegraph (faixa travada) → active (peças da faixa somem, borda anda) → off (área gravada)`.
- **Traça-Mãe:** `vivo → fila de estouro → flush → N traças | abafadas (zona letal)`.

## Sinais novos (EventBus)
`boss_immune_hit(position, tag)` · `page_bite_warned(side, strip)` · `page_bite_cancelled(side, reason)` · `page_bite_started(side, strip, target)` · `play_area_changed(rect)` · `page_bite_finished(rect)` · `brood_burst(position, spawned, smothered)`.

## Peças novas
- `PlayArea` (static): `rect`, `reset()`, `shrink_to(r)` = interseção (nunca cresce), `push_inside`, `strip`, `target`, `can_shrink`.
- `BurstOnDeathBehavior` + `EnemyManager.queue_burst/_flush_bursts` (fila fixa; flush depois das zonas; `n = min(burst_count, burst_max_alive - vivas, CAPACITY - count)`; dentro de zona letal viva → 0, abafadas).
- `GustAttack` (cone travado, `Player.shove`), `DustAttack` (poça), `SummonAttack` reusado, `EatPageAttack` (`is_available` = `can_shrink`), `EatenEdgeView` (um `_draw` por sinal), `Player.shove(v, t)`.
- **Área viva:** Player → `push_inside` depois do `move_and_slide` (+ `nearest_free`); paredes do Arena reposicionadas no `page_bite_finished`; inimigos `world_rect = rect` + `_place` em todos; ObstacleMap refeito 1×/mordida só com peças que cabem e sem fresta; chefe `_drift` limitado; câmera fixa; tinta/cera puxadas para dentro.
- **Imunidade:** `BossDamageFilter.apply`: `words_only` e tag em `non_word_tags = [auto, relic, potion]` → 0, `last_block = &"immune"`; `boss_immune_hit` no máximo 1 por `immune_feedback_interval`; `BossHurtbox.is_weapon_target()` = `not words_only`.

## Contratos de dados (campos novos)
ChapterData `chapter_2.tres` (`intro_cutscenes [c2_00]`, `boss_cutscene c2_01`, `outro_cutscene c2_02`); `data/ui/chapters.json` `unlock_after`; BossData `words_only`, `immune_feedback_interval`, `sprite_size`, `phase_overlays`; PhaseData `letter_drop_mul`; BossDamageFilterData `non_word_tags`; AttackData `cancel_by_word`, `bite_depth`, `bite_sides`, `bite_min_size`, `push_speed`, `push_time`, `hazard`; BurstOnDeathBehavior `burst_enemy`, `burst_count`, `burst_max_alive`, `burst_radius`; tuning `burst_queue_size`.

## Fases e testes
- **F1 capítulo/seleção/abertura:** `test_chapter_2_data`, `test_chapter_unlock`, `test_pending_intro`.
- **F2 Traça-Mãe:** `test_burst_on_death` (N, teto, CAPACITY, sem nós novos, zona abafa, morte em massa, `dissolve_all`).
- **F3 imunidade:** `test_boss_damage_filter` (SC-1202), `test_boss_immune_feedback`, `test_weapon_targeting_immune`.
- **F4 Mãe sem Eat_Page:** telegrafia ≥ 600 ms (SC-1206), vento sem atravessar parede, poça, teto do enxame, sem exposição.
- **F5 Eat_Page:** `test_play_area` (SC-1203), `test_eat_page_cancel`, `test_eat_page_obstacles`, `test_eat_page_push` (integração).
- **F6 cutscenes/fim:** `test_chapter_2_flow` (SC-1201), cutscenes com os 5 falantes (SC-1210).
- **F7 sonda/stress:** `chapter=2`, `fight`, linha `EATPAGE`, `?stress=boss2`; GUT + export; Cap. 1 sem regressão (SC-1211).

## Riscos
Estouro em slots SoA (sem nós); `play_area_changed` por frame só ~1 s por mordida; ObstacleMap refeito 1×/mordida; paredes por `set_deferred`; `boss_immune_hit` com intervalo; zero `instantiate()`.
