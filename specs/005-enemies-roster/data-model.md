# 005 — Data Model

Todos os valores são **[INICIAL]**, já com o parecer do rules-agent (2026-09-25) aplicado. Ajustes só nos `.tres`.

## 1. `EnemyData` (estende o da 001)

| Campo novo | Tipo | Uso |
|---|---|---|
| `behavior` | EnemyBehavior | comportamento stateless (FR-501) |
| `flying` | bool | ignora obstáculos (Traça) |
| `dash_contact_damage` | int | dano de contato durante o dash (Gárgula: 2) |

| Inimigo | HP | Velocidade | Raio | Contato | Drop de letra | Sprite (placeholder) | Pivot | Dissolução |
|---|---|---|---|---|---|---|---|---|
| Diabrete | 2 | 45 | 5 | 1 | 0.6 | 12×12 | (6,11) | 12 |
| Traça Gigante | 1 | 55 | 5 | 1 | 0.3 | 16×12 | (8,11) | 16 |
| Gárgula | 5 | 35 (andando) | 6 | 1 (2 no dash) | 0.8 | 16×16 | (8,15) | 16 |
| Monge Oco | 4 | 40 | 6 | 1 | 0.8 | 16×24 | (8,23) | 24 |
| Borrão | 3 | 28 | 6 | 1 | 0.7 | 14×10 | (7,9) | 12 |

## 2. Comportamentos (`src/enemies/behaviors/`, instâncias em `data/behaviors/`)

Base `EnemyBehavior` (Resource):
`func desired_velocity(m: EnemyManager, i: int, target: Vector2, dt: float) -> Vector2`, chamado só nos ticks de steering do inimigo, com `dt` já multiplicado. O estado do inimigo vive em `m.state[i]`, `m.state_timer[i]` e `m.aim[i]`.

| Resource | Campos | Valores iniciais |
|---|---|---|
| `ChaseBehavior` | — | usa `move_speed` |
| `LetterEaterBehavior` | `seek_radius`, `eat_radius`, `eat_time`, `max_eaten`, `idle_speed_mul`, `flee_speed_mul` | 160 · 6 · 0.4 s · 1 · 0.4 · 1.2 |
| `DasherBehavior` | `trigger_range`, `windup`, `dash_speed`, `dash_time`, `cooldown` | 90 · 0.6 s · 220 · 0.5 s · 2.5 s (direção travada no início do windup) |
| `RangedBehavior` | `keep_min`, `keep_max`, `fire_interval`, `windup`, `projectile` (EnemyProjectileData) | 110 · 150 · 2.2 s · 0.4 s · `prj_page` |
| `TrailBehavior` | `trail_interval`, `puddle` (PuddleData) | **2.5 s** · `puddle_ink` (teto de 24 poças, pool) |

## 3. `EnemyProjectileData` — `data/projectiles/prj_page.tres`

| Campo | Valor |
|---|---|
| `speed` | 90 |
| `radius` | 3 |
| `damage` | 1 (fraco) |
| `lifetime` | 4 s |
| `size` | 6×6 (≤ 10×10) |

## 4. `PuddleData` — `data/hazards/puddle_ink.tres`

| Campo | Valor |
|---|---|
| `size` | 24×10 (ficha 11) |
| `duration` | 3 s |
| `player_slow_factor` | 0.6 |

## 4b. CRUX (`data/words/crux.tres`), correção do Princípio IV

| Campo novo | Valor | Motivo |
|---|---|---|
| `arm_width` | 6 | hoje está como constante em `crux.gd` |
| `block_radius` | 16 | a cruz bloqueia tiros a até 16 px do centro, além dos braços (rules-agent) |

## 5. `ChampionTuning` — `data/tuning/champion.tres`

| Campo | Valor |
|---|---|
| `hp_mul` | 4.0 |
| `speed_mul` | 1.1 |
| `radius_mul` | 1.5 |
| `spawn_telegraph` | 0.8 s |
| `gold_drops_min` / `max` | 3 / 5 |
| `heal_candles` | 1 |
| `death_hitstop_ms` | 40 |

## 6. Ondas do Capítulo 1 (`WaveData` ganha `champions`, `champion_pool`, `champion_times`)

| Onda | Duração | Grupos (inimigo: ritmo início→fim /s, máx. vivos) | Campeões |
|---|---|---|---|
| 1 | 60 s | Diabrete 0.5→2.0, 60 | 0 |
| 2 | 65 s | Diabrete 0.8→2.0, 60 · **Traça** 0.1→0.3, 8 | 0 |
| 3 | 70 s | Diabrete 1.0→2.2, 70 · Traça 0.15→0.35, 10 | 1 (Diabrete) |
| 4 | 75 s | Diabrete 1.0→2.2, 70 · Traça 0.15→0.35, 10 · **Borrão** 0.1→0.3, 10 | 1 |
| 5 | 80 s | Diabrete 1.2→2.4, 80 · Traça 0.3, 12 · Borrão 0.2, 10 · **Gárgula** 0.05→0.15, 5 | 1 |
| 6 | 80 s | Diabrete 1.2→2.4, 80 · Traça 0.3, 12 · Borrão 0.2, 10 · Gárgula 0.1, 6 · **Monge** 0.05→0.15, 5 | 1 |
| 7 | 85 s | Diabrete 1.4→2.6, 90 · Traça 0.35, 14 · Borrão 0.25, 12 · Gárgula 0.15, 8 · Monge 0.15, 8 | 1 |
| 8 | 90 s | Diabrete 1.6→2.8, 100 · Traça 0.4, 15 · Borrão 0.3, 14 · Gárgula 0.2, 10 · Monge 0.2, 10 | 1 |
| 9 | 90 s | Diabrete 1.8→3.0, 110 · Traça 0.4, 16 · Borrão 0.3, 15 · Gárgula 0.25, 12 · Monge 0.25, 12 | 1 |

O pool de campeões de cada onda inclui só os inimigos já apresentados até ela, **exceto a Traça**. A onda 1 continua com o `.tres` atual (2 grupos), que é a linha de base medida na C-004.

## 7. Estado em runtime (EnemyManager, arrays novos)

`state: PackedInt32Array` · `state_timer: PackedFloat32Array` · `aim: PackedVector2Array` · `champion: PackedByteArray` · `max_hp_of: PackedInt32Array`. `GameState.gold_ink: int`.

## 8. EventBus (sinais novos)

| Sinal | Parâmetros |
|---|---|
| `letter_eaten` | `letter: String, position: Vector2` |
| `champion_killed` | `data: EnemyData, position: Vector2` |
| `gold_ink_collected` | `amount: int, total: int` |
| `chapter_completed` | `chapter: int` |
