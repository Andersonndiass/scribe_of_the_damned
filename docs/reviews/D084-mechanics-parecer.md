# D-084 — Parecer do mechanics-agent: zona que mata enquanto o ataque está na tela

> 2026-09-30 · Sistema proposto (sem código final).

## Modelo
- **`KillZone`** (RefCounted): descreve a zona e o estado dela.
  - Forma: LINE, CIRCLE, CROSS (com ângulo) ou SCREEN.
  - Estado: IDLE → ACTIVE → (DRAINING, só na SCREEN) → CLOSED.
  - Campos: `life_left`, `cast_id`, `tag`, dano ao campeão (fixo ou fração da vida), `champions_hit` por uid, `drops_left` (REQUIEM) e `kills`.
- **`KillZones`**: lista estática com `register`, `unregister` e `clear`, no mesmo padrão do `ProjectileBlockers`.
- **Cada milagre de ataque** cria a sua zona no `_ready` (o pool já faz o pré-aquecimento). Ela é registrada no `start` e retirada no `finish` e no `_exit_tree`.
- **O `EnemyManager` aplica as zonas uma vez por tick de física**, depois dos milagres (`process_physics_priority`):
  1. Busca os candidatos pela SpatialHash e faz o teste exato de forma.
  2. **Comum:** morre (`damage_at(i, hp[i])` → `kill` → `enemy_killed`, como hoje).
  3. **Campeão:** leva 1 acerto por zona. Por isso ganha um uid estável, porque a remoção por troca muda os slots.
  4. Há um teto de mortes por tick (`max_kills_per_tick` 30, em `data/tuning/kill_zone.tres`). Quem sobrar é aplicado no tick seguinte.
- **O chefe nunca é tocado pela zona.** Ele continua ferido pelas funções atuais, no mesmo ritmo e com o mesmo filtro.
  - As funções de dano passam a ter uma versão só para o chefe: `hit_boss_zone` e `touch_boss_zone`.
- **Custo:** estimado em 0,02 a 0,08 ms por zona com a hash. A SCREEN custa O(n) durante ~0,6 s, igual à varredura de hoje. Medir com `?stress=zones` e o balde `inimigos_zonas`.

## Dados
- **`WordData`:**
  - `kill_zone` (bool): serve de chave para comparar o jogo com e sem a regra na sonda;
  - `champion_hit` (fração);
  - `champion_hit_flat` (PURGO, 10 literais).
- **`ChampionTuning`:** `zone_hit_frac` (o rules-agent propõe 0,4, com o nome `champion_strike_frac`).
- **`duration`:** vira o tempo da zona. `SWEEP_TIME` e `FLASH_TIME`/`RING_TIME` passam para os `.tres`.

## Ordem das fases
1. Contrato e aplicação no `EnemyManager`, com testes.
2. Zonas fixas: LUX, IGNIS, CRUX, FLAMMA, CAECITAS, VAPOR e SANCTUS. As que ainda usam `_process` passam para `_physics_process`.
3. Zonas que se movem: ANGELUS e MARTYRIUM.
4. Varreduras: MORTIS, PURGO e REQUIEM (e MISERERE, se entrar como ataque).
5. Medir: `?stress=zones` e sonda por onda, com o rules-agent reequilibrando em dados.
6. Documentação.

## Riscos
- **Muitas mortes num quadro:** o teto por tick controla.
- **Pool de letras (150):** uma varredura pode passar do pool. O `LetterField` usa `try_acquire`, então as excedentes somem.
- **Várias subidas de nível seguidas:** o jogo pausa a cada uma. Precisa de teste.
- **Morte ligeiramente adiantada:** a posição lógica fica até um passo à frente do desenho.

## Divergência na classificação (autor decide)
- **MISERERE:** o rules-agent quer como ataque (280 de dano na tela toda); o mechanics-agent quer como ferramenta (serve para absolver, como a DOMINUS).
- **LUMEN:** os dois concordam que é ferramenta (ímã e letra-alvo, sem dano).
