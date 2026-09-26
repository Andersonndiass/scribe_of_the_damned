# 005 — Plan

## 1. Arquitetura

- **Comportamentos stateless** (`src/enemies/behaviors/*.gd`): cada um lê e escreve o estado do inimigo nos arrays do EnemyManager (`state`, `state_timer`, `aim`) e devolve a velocidade desejada. O manager continua dono da separação, da integração, do contato e do laço único com steering escalonado (D-039). Timers de telegrafia e ações que precisam de precisão (fim do windup, disparo) correm **todo tick**, fora do escalonamento, via `behavior.tick(m, i, dt)`, barato e sem separação.
- **Projéteis inimigos**: `EnemyProjectileManager` (arrays: pos, vel, vida, dado) + um único `_draw`. Colisão por distância com o corpo do jogador e checagem de `ProjectileBlockers`. É o padrão do EnemyManager aplicado a tiros (lição do T085).
- **Poças**: `HazardField` (arrays: retângulo, tempo) + um `_draw`. Expõe `slow_at(pos) -> float`, que o Player consulta ao se mover. Sem Area2D.
- **Campeões**: flag por slot no EnemyManager; HP, velocidade e raio multiplicados no spawn; o EnemyRenderer usa material de contorno (shader `outline.gdshader`, 1px BLOOD) e desenha a aura. O telegraph de campeão usa 0.8 s e anel maior.
- **Tinta dourada**: `GoldInkField`, igual ao LetterField mas mais simples (pool de gotas, ímã, soma em `GameState.gold_ink`). HUD `HudInk` no canto superior direito.
- **WaveDirector**: agenda os campeões (`champion_times`) e segue a lista das 9 ondas do capítulo (`ChapterData.waves`); ao fim da 9, emite `chapter_completed`.

## 2. Arquivos

```
src/enemies/behaviors/enemy_behavior.gd          (base)
src/enemies/behaviors/chase_behavior.gd
src/enemies/behaviors/letter_eater_behavior.gd
src/enemies/behaviors/dasher_behavior.gd
src/enemies/behaviors/ranged_behavior.gd
src/enemies/behaviors/trail_behavior.gd
src/enemies/enemy_projectile_manager.gd
src/enemies/hazard_field.gd
src/enemies/champion_aura.gd                     (desenho da aura, 1 nó para todos)
src/letters/gold_ink_field.gd  +  gold_ink.tscn/.gd
src/ui/hud/ink_counter.gd
src/data/enemy_projectile_data.gd · puddle_data.gd · champion_tuning.gd · chapter_data.gd
assets/shaders/outline.gdshader
data/behaviors/*.tres · data/enemies/{moth,gargoyle,hollow_monk,ink_blot}.tres
data/projectiles/prj_page.tres · data/hazards/puddle_ink.tres · data/tuning/champion.tres
data/waves/chapter_1/wave_01..09.tres · data/chapters/chapter_1.tres
tools/gen_placeholders.gd (+ 4 inimigos, gota dourada)
tests/unit/test_behaviors.gd · test_enemy_projectiles.gd · test_hazard_field.gd · test_champions.gd
tests/integration/test_chapter1_waves.gd
src/debug/stress_scene (modo "onda 9")
```

## 3. Mudanças em código da 001

- `EnemyManager`: arrays novos (state, state_timer, aim, champion, max_hp_of); `spawn(data, pos, champion := false)`; chama `behavior.tick` todo tick e `behavior.desired_velocity` no tick de steering; contato usa `dash_contact_damage` quando `state == DASH`.
- `EnemyRenderer`: material de contorno para campeões; escala do placeholder ×1.5.
- `LetterField`: `eat_letter_near(pos, r) -> bool` (Traça).
- `Player.move`: multiplica a velocidade por `HazardField.slow_at(pos)`.
- `WaveDirector`: campeões e sequência do capítulo.
- `Main`: pools e nós novos; o loop de ondas segue o `ChapterData`.

## 4. Riscos

| Risco | Mitigação |
|---|---|
| Custo de chamar o comportamento por inimigo no web | Chamadas só no tick de steering (metade por tick) + `tick` enxuto; medir com a cena de stress da onda 9 (SC-503) |
| A Traça comer todas as letras e travar o ciclo de palavras | `seek_radius` e HP 1 no `.tres`; observar no playtest (C-004) |
| O dash da Gárgula atravessar o jogador sem chance de reação | windup de 0.6 s com a linha tracejada; dash com direção travada no início do windup |
| Arte placeholder dos campeões (escala 1.5× em vez de redesenho) | Aceitável até a arte gerada por script (D-024) |
