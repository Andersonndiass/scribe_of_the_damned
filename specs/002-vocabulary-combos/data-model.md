# 002 — Data Model

Valores **[INICIAL]**, já com os pareceres de 2026-09-26 aplicados.

## 1. `WordData` (campos novos)

| Campo | Tipo | Uso |
|---|---|---|
| `group` | StringName | `&"base"`, `&"apocrypha"`, `&"oration"` |
| `requires_unlock` | bool | apócrifos: true |
| `combo_eligible` | bool | false para GLORIA e PURGO (FR-204) |
| `buff_mul` | float | GLORIA: 1.5 |
| `magnet_mul` | float | LUMEN: 2.0 |
| `target_weight_mul` | float | LUMEN: 2.0 |
| `charges` | int | FIDES: 1 |
| `kill_batch_per_frame` | int | 30 (PURGO, MORTIS, DOMINUS, MISERERE, Réquiem) |
| `guaranteed_drop_cap` | int | 40 (Réquiem) |
| `hit_cooldown` | float | ANGELUS, Martírio: 0.2–0.25 s por inimigo |
| `speed_mul` | float | SPIRITUS: 1.5 |
| `clear_projectiles` | bool | SALVATOR |
| `forgive_heresy` | bool | MISERERE |

## 2. As 11 palavras novas (`data/words/`)

| Palavra | Letras | Grupo | power_budget | Parâmetros |
|---|---|---|---|---|
| FIDES | 5 | apócrifo | 2.4 | charges 1 · dura até ser consumido ou o fim da onda |
| LUMEN | 5 | apócrifo | 2.4 | duration 10 · magnet_mul 2.0 · target_weight_mul 2.0 |
| PURGO | 5 | apócrifo | 2.4 | kill_hp_threshold 999 (comuns) · damage **10** (campeão/chefe) · kill_batch_per_frame 30 |
| GLORIA | 6 | apócrifo | 3.5 | duration 6 · buff_mul 1.5 |
| VERBUM | 6 | apócrifo | 3.5 | repete a última palavra base ou apócrifa (não oração, não combo, não VERBUM) |
| SANCTUS | 7 | oração | 5.0 | radius 90 · damage 3 · tick 0.25 · slow 0.5 · duration 6 |
| DOMINUS | 7 | oração | 5.0 | stun 3 · damage **20** (tela toda, em lotes) |
| ANGELUS | 7 | oração | 5.0 | orbit_count 3 · radius **40** · damage 4 · hit_cooldown 0.2 · duration 10 · rotation_speed 1.0 · width 8 (alcance da pena; D-056) |
| SPIRITUS | 8 | oração | 7.0 | duration 6 · speed_mul 1.5 · damage 3 por toque · hit_cooldown 0.25 · radius 10 (toque; D-056) · intangível a corpos (projéteis e heresia ainda doem) |
| SALVATOR | 8 | oração | 7.0 | heal_candles **3** · clear_projectiles · sem invulnerabilidade |
| MISERERE | 8 | oração | 7.0 | damage 40 (tela toda, em lotes) · apaga poças de heresia e letras corrompidas · forgive_heresy (a próxima) |

Base (inalteradas): LUX/PAX 1.0 · CRUX/VITA/AQUA 1.6 · IGNIS 2.4 · MORTIS 3.5.

## 3. `ComboData` — `data/combos/*.tres`

| Campo | Tipo |
|---|---|
| `id` | StringName |
| `word_a`, `word_b` | WordData (ordem não importa) |
| `miracle_scene` | PackedScene |
| `power_budget` | float |
| parâmetros | damage, radius, duration, tick_interval, stun… (como WordData) |

| Combo | Par | power | Parâmetros |
|---|---|---|---|
| Vapor | AQUA+IGNIS | 3.0 | radius 80 · duration 4 · damage 1 · tick 0.5 · stealth_aggro_mul 0 (fora da nuvem) |
| Chama Radiante | LUX+IGNIS | 3.0 | damage 8 (raio) + fogo 2/0.25 s por 3 s · line 160 × 20 |
| Cegueira | LUX+PAX | 2.2 | radius 140 · damage 6 · stun 2.5 (sem cancelar contato) |
| Martírio | CRUX+LUX | 3.0 | damage 2 · hit_cooldown 0.25 · length 160 · duration 3 · rotation_speed 1 volta/s |
| Réquiem | MORTIS+PAX | 4.5 | kill_hp_threshold 5 · damage 20 · drop 100% até guaranteed_drop_cap 40 |

## 4. `ComboTuning` — `data/tuning/combo.tres`
`window` = 2.5 s (conta a partir da 1ª letra da próxima palavra) · `max_open` = 8 s · `hint_highlight` = true (D-044).

`ComboData.display_name`: VAPOR, FLAMMA, CAECITAS, MARTYRIUM, REQUIEM (D-045).

## 5. Estado em runtime
- `GameState.unlocked_words` (já existe) + `unlock_word(id)`.
- `Caster`: `last_word: WordData`, `last_cast_time: float`, `combo_open: bool`.
- `PlayerBuffs` (novo, no Player): `shield_charges`, `lumen_left`, `gloria_left`, `spiritus_left`, `forgive_heresy`.
- EnemyManager: `guaranteed_drop: PackedByteArray` (Réquiem) e alvo oculto enquanto o escriba está no Vapor.

## 6. EventBus (sinais novos)
| Sinal | Parâmetros |
|---|---|
| `combo_cast` | `combo: ComboData, power: float` |
| `combo_window_opened` | `word: WordData, duration: float` |
| `word_unlocked` | `word: WordData` |
