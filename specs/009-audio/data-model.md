# 009 — Modelo de dados

## 1. `SoundData` — `data/audio/sfx/<id>.tres`

| Campo | Tipo | Padrão | Nota |
|---|---|---|---|
| `id` | StringName | — | igual ao nome do arquivo |
| `stream` | AudioStream | vazio | vazio = silêncio (placeholder) |
| `bus` | StringName | `SFX` | `SFX` ou `UI` |
| `volume_db` | float | 0 | |
| `pitch_jitter` | float | 0.05 | pitch sorteado em 1 ± jitter |
| `max_voices` | int | 4 | vozes simultâneas deste som |
| `cooldown_ms` | int | 30 | intervalo mínimo entre dois disparos |
| `priority` | int | 1 | 0 baixa (queda de letra) … 3 alta (morte do jogador, combo) |
| `silent_length` | float | 0.2 | quanto a voz fica ocupada sem stream |
| `note` | String | "" | o que gravar (vai para o AUDIO-LIST) |

## 2. `AudioEventMap` — `data/audio/event_map.tres`

`entries: Dictionary[StringName, SoundData]`. Chaves (FR-905, FR-906):

| Chave | Quando |
|---|---|
| `wave_started`, `wave_ended`, `chapter_completed` | ondas e capítulo |
| `enemy_killed` (+ `:imp`, `:moth`, `:gargoyle`, `:hollow_monk`, `:ink_blot`), `champion_killed` | inimigos |
| `player_damaged`, `player_healed`, `player_died` | jogador |
| `letter_dropped`, `letter_dropped:rare`, `letter_collected`, `letter_collected:rare`, `letter_rejected`, `letter_eaten`, `gold_ink_collected` | letras |
| `atril_valid` | o atril passou a VALID (transição, não a cada letra) |
| `word_cast` (+ `:<id>` das palavras), `combo_cast` (+ `:<id>` dos combos), `heresy_committed`, `atril_purged`, `combo_window_opened` | conjuração |

Prioridades iniciais: `player_died`, `combo_cast`, `champion_killed` = 3 · `word_cast`, `heresy_committed`, `player_damaged` = 2 · `enemy_killed`, `letter_collected` = 1 · `letter_dropped`, `letter_eaten` = 0.

## 3. `MusicData` — `data/audio/music/<id>.tres`

| Campo | Tipo | Nota |
|---|---|---|
| `id` | StringName | |
| `layers` | Array[AudioStream] | mesma duração e BPM; vazio = silêncio |
| `bpm` | float | |
| `intensity_thresholds` | PackedFloat32Array | fração do capítulo em que cada camada entra (ex.: 0.0, 0.34, 0.67) |
| `fade_ms` | int | rampa ao ligar/desligar uma camada (padrão 700; animation-agent) |
| `death_fade_ms` | int | rampa quando o escriba morre (padrão 400) |
| `note` | String | o que gravar |

## 4. Constantes (`AudioManager`)

`VOICES_SFX` = 24 · `VOICES_UI` = 4. Aprovados pelo animation-agent (D-054). Valores por evento: tabela `EVENTS` em `tools/gen_audio_data.gd`.
