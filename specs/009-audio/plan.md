# 009 — Plano

## Arquitetura

- **Barramentos:** `default_bus_layout.tres` com `Master`, `Music`, `SFX`, `UI` (FR-901).
- **AudioManager** (autoload, `process_mode = ALWAYS`): cria no `_ready` um pool de `AudioStreamPlayer` (`VOICES` = 24 de SFX + 4 de UI). Cada voz guarda o id do som, a prioridade e o instante em que começou. `play(id)` aplica as regras da FR-903. Um `Dictionary` por id guarda o último instante tocado (cooldown) e as vozes ativas. Escuta o EventBus e resolve a chave pelo `AudioEventMap` (variante → base). As vozes de `SFX` pausam com a árvore; as de `UI`, não.
- **Lógica pura testável:** `VoiceAllocator` (RefCounted) decide qual voz usar ou roubar, sem nós. O `AudioManager` só aplica a decisão aos players.
- **MusicDirector** (filho do AudioManager): um `AudioStreamPlayer` por camada, todos iniciados no mesmo frame; ligar ou desligar é tween de `volume_db` (FR-908). A intensidade vem de `wave_started` (índice ÷ total de ondas do capítulo) e `player_died`.
- **Web gate** (FR-910): no web, `_unlocked = false` até o primeiro `InputEventKey`/`InputEventMouseButton`/`InputEventScreenTouch` pressionado; `play` antes disso retorna sem tocar.
- **Sem stream:** o caminho inteiro roda (voz reservada pelo tempo de `silent_length`), para que o comportamento com e sem arquivo seja o mesmo.

## Arquivos

```
default_bus_layout.tres
src/audio/audio_manager.gd (autoload) · src/audio/voice_allocator.gd · src/audio/music_director.gd
src/data/sound_data.gd · src/data/music_data.gd · src/data/audio_event_map.gd
data/audio/event_map.tres · data/audio/sfx/*.tres (um por evento da FR-906) · data/audio/music/chapter_1.tres
tools/audio_report.gd → docs/AUDIO-LIST.md
[Fase 2] tools/gen_placeholder_sfx.gd → assets/audio/placeholders/*.wav
tests/unit/test_voice_allocator.gd · test_audio_event_map.gd · test_music_director.gd
tests/integration/test_audio_events.gd
```

## Riscos

| Risco | Mitigação |
|---|---|
| Spam de som com 300 mortes | `max_voices` + `cooldown_ms` por som (FR-903); teste SC-902 |
| Camadas de música fora de sincronia no web | todas começam no mesmo frame e nunca param, só mudam de volume |
| Erro de AudioContext no web | gate do primeiro input (FR-910); medir no Chrome e no Firefox |
| Custo no web | pool fixo e sem nós novos; medir o SC-001 antes e depois (SC-906) |
