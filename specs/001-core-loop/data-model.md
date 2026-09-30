# 001 — Data Model

Sete Resources tipados (`class_name`) em `src/data/`. As instâncias ficam em `data/`. **Todos os valores abaixo são iniciais** (rules-agent, D-018): são ajustados em playtest mexendo só nos `.tres`.

## 1. `PlayerData` — `src/data/player_data.gd` · `data/player/anselmo.tres`

| Campo | Tipo | Valor inicial | Uso |
|---|---|---|---|
| `id` | StringName | `&"anselmo"` | |
| `move_speed` | float | 90.0 | px/s (FR-001) |
| `attack_interval` | float | 0.8 | s (FR-002) |
| `attack_range` | float | 160.0 | px |
| `projectile_speed` | float | 220.0 | px/s |
| `projectile_damage` | int | 1 | |
| `start_candles` | int | 3 | FR-003 |
| `max_candles` | int | 8 | teto absoluto |
| `iframes` | float | 1.0 | s |
| `idle_regen_delay` | float | 5.0 | s (FR-004) |
| `idle_regen_interval` | float | 3.0 | s por vela |
| `magnet_radius` | float | 40.0 | px |
| `atril_capacity` | int | 5 | 3..8 |
| `hurtbox_radius` | float | 5.0 | px |

## 2. `WordData` — `src/data/word_data.gd` · `data/words/<id>.tres`

| Campo | Tipo | Notas |
|---|---|---|
| `id` | StringName | `&"lux"` |
| `latin` | String | `"LUX"` (maiúsculas; validado pelo Lexicon) |
| `translation_key` | StringName | só para o Grimório (Princípio VIII) |
| `power_budget` | float | cresce com o tamanho (FR-018) |
| `miracle_scene` | PackedScene | cena pooled do milagre |
| `damage` | float | por acerto ou por tick |
| `tick_interval` | float | 0 = instantâneo |
| `radius` | float | px (área) ou largura (raio) |
| `length` | float | px (raio da LUX, braços da CRUX) |
| `duration` | float | s |
| `stun` | float | s |
| `knockback` | float | px |
| `slow_factor` | float | 0..1 |
| `heal_candles` | int | |
| `kill_hp_threshold` | int | MORTIS |
| `blocks_projectiles` | bool | CRUX |
| `vfx_prefix` | StringName | `VFX_LUX` (art bible §16) |

Valores iniciais:

| Palavra | Letras | power_budget | Parâmetros |
|---|---|---|---|
| LUX | 3 | 1.0 | damage 8 · radius (largura) 10 · length 320 · duration 0.3 |
| PAX | 3 | 1.0 | radius 72 · knockback 80 · stun 1.5 |
| CRUX | 4 | 1.6 | damage 3 · tick 0.25 · length 48 · duration 4.0 · blocks_projectiles |
| VITA | 4 | 1.6 | heal_candles 1 |
| AQUA | 4 | 1.6 | radius 56 · slow_factor 0.5 · duration 4.0 |
| IGNIS | 5 | 2.4 | damage 2 · tick 0.25 · radius 48 · duration 3.0 |
| MORTIS | 6 | 3.5 | kill_hp_threshold 5 · damage 20 · radius 999 (tela) |

Regra testada: `power_budget` estritamente maior para mais letras; empate permitido no mesmo tamanho.

## 3. `LexiconData` — `src/data/lexicon_data.gd` · `data/lexicon/base.tres`

| Campo | Tipo | Notas |
|---|---|---|
| `alphabet` | PackedStringArray | `A C D E F G I L M N O P Q R S T U V X B` |
| `gated_letters` | Dictionary[String, StringName] | `{"B": &"verbum"}`: a letra só cai com a palavra desbloqueada |
| `words` | Array[WordData] | as 7 base |
| `min_length` | int | 3 |
| `max_length` | int | 8 |

## 4. `EnemyData` — `src/data/enemy_data.gd` · `data/enemies/imp.tres`

| Campo | Tipo | Diabrete |
|---|---|---|
| `id` | StringName | `&"imp"` |
| `max_hp` | int | 3 |
| `move_speed` | float | 45.0 |
| `radius` | float | 5.0 |
| `contact_damage` | int | 1 (1 = fraco, 2 = forte; D-012) |
| `separation_weight` | float | 1.0 |
| `telegraph_time` | float | 0.5 |
| `letter_drop_chance` | float | 0.6 |
| `sprite_frames` | SpriteFrames | placeholder 12×12 (animação `move`) |
| `sprite_pivot` | Vector2 | (6, 11) — da ficha 07 |
| `dissolve_size` | int | 12 (§6.1: 12, 16 ou 24) |

## 5. `SpawnGroup` — `src/data/spawn_group.gd` (subrecurso do WaveData)

| Campo | Tipo | Notas |
|---|---|---|
| `enemy` | EnemyData | |
| `start_time` | float | s desde o início da onda |
| `end_time` | float | s |
| `spawn_rate_start` | float | inimigos/s |
| `spawn_rate_end` | float | interpolação linear |
| `max_alive` | int | teto deste grupo |

## 6. `WaveData` — `src/data/wave_data.gd` · `data/waves/chapter_1/wave_01.tres`

| Campo | Tipo | Onda 1 |
|---|---|---|
| `chapter` | int | 1 |
| `index` | int | 1 |
| `duration` | float | 60.0 |
| `groups` | Array[SpawnGroup] | Diabrete: 0–20s de 0.5→1.0/s; 20–60s de 1.0→2.0/s; max_alive 60 |
| `min_spawn_distance` | float | 96.0 |
| `degradation_stage` | int | 0..3 |

## 7. `DropTuning` — `src/data/drop_tuning.gd` · `data/tuning/drop_tuning.tres`

| Campo | Tipo | Valor inicial |
|---|---|---|
| `base_weights` | Dictionary[String, float] | frequência do latim: E I A U T S R N O M C L = 1.0 · P D V G F Q X = 0.5 · B = 0.3 |
| `target_bonus` | float | 25.0 (D-082; era 10.0: letra-alvo no meio da palavra 43% → 64%) |
| `rare_chance` | float | 0.05 (só vogais) |
| `rare_power_bonus` | float | 1.5 |
| `letter_lifetime` | float | 12.0 (D-082; era 8.0) · `selective_magnet` = true (D-082) |
| `blink_time` | float | 2.0 |
| `purge_scatter_radius` | float | 20.0 |
| `purge_pickup_lock` | float | 0.3 |
| `heresy_stun` | float | 0.5 |
| `heresy_pool_time` | float | 2.0 |
| `heresy_pool_radius` | float | 64.0 |
| `hint_count` | int | 3 |

## Estado em tempo de execução (não é Resource)

- **`GameState`** (autoload): `candles: int`, `max_candles: int`, `atril_capacity: int`, `wave_index: int`, `unlocked_words: Array[StringName]`, `rng: RandomNumberGenerator` (com seed para testes). Na 003 ele passa a delegar ao RunStats.
- **`Atril`** (RefCounted, lógica pura): `letters: PackedStringArray`, `rare_flags: Array[bool]`, `capacity: int`, `state: int`.
