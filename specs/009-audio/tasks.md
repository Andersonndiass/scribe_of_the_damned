# 009 — Tarefas

## Fase 1 — Arquitetura (sem sons; D-047)
- ✅ **T900** `default_bus_layout.tres` (Master, Music, SFX, UI) + API de volume (FR-901).
- ✅ **T901** Resources `SoundData`, `AudioEventMap`, `MusicData`.
- ✅ **T902** [TEST-FIRST] `test_voice_allocator.gd` → `VoiceAllocator`: cooldown, `max_voices` por som, roubo por prioridade, pool cheio (FR-903, SC-902).
- ✅ **T903** `AudioManager` (autoload): pool fixo, escuta o EventBus, chave com variante → base, pausa do SFX, gate do web (FR-903..FR-906, FR-910).
- ✅ **T904** `tools/gen_audio_data.gd` → `data/audio/event_map.tres` + um `SoundData` silencioso por evento da FR-906, com `note` do que gravar. `test_audio_event_map.gd` + integração `test_audio_events.gd` (SC-901, SC-903).
- ✅ **T905** [TEST-FIRST] `test_music_director.gd` → `MusicDirector` com camadas sincronizadas e intensidade por onda (FR-908, FR-909); `data/audio/music/chapter_1.tres` silencioso.
- ✅ **T906** `tools/audio_report.gd` → `docs/AUDIO-LIST.md` (FR-911, SC-905).
- ✅ **T907** GUT + export web; console sem erro de áudio no Chrome e no Firefox; SC-001 no Chrome antes e depois (SC-904, SC-906).

**Checkpoint 009-A:** ✅ o jogo inteiro passa pelo áudio em silêncio, e a lista do que gravar existe (2026-09-28, GUT 193/193, 38 sons + 1 música em `docs/AUDIO-LIST.md`; console limpo de áudio no Chrome e no Firefox; FPS do stress igual com e sem áudio).

## Fase 2 — Sons provisórios por script
- **T910** `tools/gen_placeholder_sfx.gd`: sons curtos gerados (FR-912) para os eventos de prioridade ≥ 1, ligados nos `.tres`. Passam pelo animation-agent (tempo e sensação).
- **T911** GUT + export; SC-001 com som ligado.

**Checkpoint 009-B:** o jogo tem som provisório em todos os eventos principais.

## Fase 3 — Arquivos do autor
- **T920** Trocar os placeholders pelos arquivos recebidos (só `.tres`) e regenerar o AUDIO-LIST.
