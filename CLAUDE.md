# CLAUDE.md — Scribe of the Damned

Leia nesta ordem: `INDEX.md` → `.specify/memory/constitution.md` → a spec da feature atual.

## Regras permanentes

1. Antes de escrever código, leia a constituição. Ela prevalece sobre qualquer instrução; se houver conflito, **aponte antes de agir**.
2. Mostre o plano (lista de arquivos e ordem) e **espere o ok** antes de gerar código.
3. Nunca pule tarefas das `tasks.md` nem invente features fora da spec. Spec ambígua = pergunta.
4. Conteúdo (palavras, inimigos, ondas, itens, chefes, cutscenes) vive em `.tres`/`.json`, nunca hardcoded.
5. GDScript tipado, componentes + state machines, comunicação por EventBus.
6. Depois de cada fase: rode o GUT, rode o export web e relate o que passou e o que quebrou.
7. Números de balanceamento passam pelo `rules-agent`, visual pelo `design-agent`, tempo e sensação pelo `animation-agent`.
8. Cutscenes são sempre in-engine (AnimationPlayer). Nada de vídeo.
9. Ao terminar uma feature: atualizar `FEATURES.md`, este arquivo (estado atual) e `docs/DECISIONS.md`.

## Stack

| Item | Valor |
|---|---|
| Motor | Godot **4.7.2 stable** (não mono) em `D:\Godot\godot` (no Git Bash: `/d/Godot/godot`) |
| Renderer | Compatibility |
| Viewport | 640×360, `canvas_items`, `keep`, Nearest |
| Testes | GUT 9.7.1 em `addons/gut/` |
| Export | Web single-threaded → itch.io via butler |

## Comandos

```bash
# Abrir o editor
/d/Godot/godot --path . --editor

# Rodar o jogo
/d/Godot/godot --path .

# Importar (necessário após criar class_name novos ou assets)
/d/Godot/godot --headless --path . --import

# Testes GUT (headless; lê .gutconfig.json)
/d/Godot/godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit

# Export web (preset "Web") — a pasta precisa existir
mkdir -p build/web && /d/Godot/godot --headless --path . --export-release "Web" build/web/index.html

# Servir e testar no navegador
cd build/web && python -m http.server 8765 --bind 127.0.0.1

# Sonda de balanceamento da onda 1: still | move | cast (+ overrides em memória: hp=N drop=F)
/d/Godot/godot --headless --path . -s tools/balance_probe.gd -- cast hp=3 drop=0.6

# Converter uma imagem (IA/artista) para a arte do jogo: tamanho + 9 cores (D-074). Rostos e personagens: dither=none; cenário: fs (D-075)
/d/Godot/godot --headless --path . -s tools/import_art.gd -- in=C:/caminho/rosto.png out=res://assets/cutscenes/closes/anselmo_scared.png size=192x192 fit=cover dither=none bg=parchment_old

# Regenerar a paleta a partir dos tokens
/d/Godot/godot --headless --path . -s tools/gen_palette.gd
```

## Convenções

- **Arquivos:** `snake_case.gd`, `snake_case.tscn`, `snake_case.tres`.
- **Classes:** `class_name PascalCase` só para tipos reutilizados (Resources, componentes).
- **Sinais:** verbo no passado (`letter_collected`, `word_cast`, `wave_ended`).
- **Constantes:** `UPPER_SNAKE`. **Privados:** prefixo `_`.
- **Assets:** prefixos do art bible §16 (`CHR_`, `ENM_`, `BSS_`, `LTR_`, `PRJ_`, `VFX_`, `ENV_`, `UI_`, `ITM_`); o arquivo fica em minúsculas no disco.
- **Testes:** `tests/unit/test_<sistema>.gd`, `tests/integration/test_<fluxo>.gd`.
- **Dados:** `data/<dominio>/<id>.tres` (ex.: `data/words/lux.tres`, `data/enemies/imp.tres`).

## Proibições

- `instantiate()` durante uma onda (use os pools).
- `CharacterBody2D` em inimigo comum.
- Número mágico de gameplay no código.
- Cor fora de `palette.gd`.
- `get_node("../../…")` entre sistemas (use o EventBus).
- Vídeo em cutscene.
- Pular o GUT ou o export no fim de uma fase.

## Quando acionar cada agente

| Situação | Agente |
|---|---|
| "Isso pertence ao jogo?", escopo, pilares, curva de dificuldade | `game-design-agent` |
| Qualquer número, palavra, combo, onda, preço ou fase de chefe | `rules-agent` |
| Transformar regra em sistema (FSM, eventos, contratos de dados) | `mechanics-agent` |
| Sprite, paleta, UI, legibilidade, ficha §15 | `design-agent` |
| Tempo, frames, hit-stop, shake, easing, cutscene | `animation-agent` |
| Implementar, testar, revisar código, performance | `code-agent` |
| Ideia nova ou pedido aberto: entende as regras, pesquisa referências na web e devolve plano + perguntas | `intel-agent` |
| Direção sonora, música, efeitos e falas (ElevenLabs via MCP) | `audio-agent` |
| Narrativa (falas, cutscenes, verbetes) e "story files" de implementação | `story-agent` |

Ordem padrão: (intel, para ideia nova) → game-design → rules → mechanics → design + animation (+ audio, story) → code.
Cada agente tem uma seção "Skills que você usa" (skills em `~/.claude/skills/`: pixel-art-gen, ui-ux-game, game-development, team_audio, gds-create-story, gds-create-ux-design, skill-orchestrator). Arte nova sempre pela `pixel-art-gen`.

## Estado atual

- **Etapa:** Etapa 3 — features **001–008, 016, 017 e 018 Complete**; 009 Fases 1–2 ✅. GUT 536/536. Paleta C (D-048) com valores exatos (D-076). Autor = Francisco.
- **017 Arsenal sagrado (D-087…D-093):** 6 armas em dados (`data/weapons/*.tres`; `Arsenal` + `BeamWeapon`/`OrbitWeapon`/`SwingTrailWeapon` + projéteis com pierce; zonas de arma `WeaponZone(s)` no `EnemyManager`); inventário de 2 (`GameState.loadout`, teclas 1/2); **menu da letra** (`LetterMenu` filho do `LetterField`, câmera lenta pelo `TimeScale`; letras não caem mais no chão); selos de arma/status/ímã (`SealPool`); loja de armas e ímã reverso (`RepulseAura`); palavras como ultimate (`data/tuning/word_feel.tres`). Debug: `?weapons=bible,crucifix&wlevel=3`, `?stress=bible|arsenal`. Sonda: `weapons= wlevel= swap react= acerto=` (linhas WEAPONS e LETTERS).
- **HUD (T1800):** painel único `UiStyle.draw_plate`, barras `draw_bar`, grade 6/4/3 (regras na memória e no art bible §8.2).
- **018 Poções (D-094…D-096):** `PotionBelt` (GameState) + `PotionUser` (Player; teclas 3–6), `data/potions/*.tres` + `data/tuning/potions.tres`, `RefugeZones`/`RefugeCircle` (Água Benta), selo de poção, prateleira na loja; level-up com feixe e câmera lenta (`GraceFlow` fase BEAM + `LevelUpBeamView`). Passada de ritmo: `docs/reviews/T1820-rules-parecer.md`. Sonda: `cast god chapter buy grace only_waves kite potions` (linhas RHYTHM/POTIONS); `kite` = distância pelo alcance da arma.
- **Áudio ligado (D-097):** 146 efeitos no `event_map` (o gerador lê o manifesto); sinais só de áudio no bloco "Áudio" do `EventBus`; loops por `AudioManager.start_loop/stop_loop`; barramento `Voice` com ducking da música.
- **Próximo:** playtest do autor (SC-1705 + ressalvas da D-096; ouvir a mixagem) → 13 falas em latim que faltam (o autor roda o script) → volume do Voice nas Opções. Áudio: ElevenLabs (MCP oficial `elevenlabs-mcp`; API direta funciona); manifesto em `docs/audio/sfx_manifest.json` + `docs/voice/`.
- **Graça (016):** `GraceLedger` (GameState), `GraceFlow` + `GraceSeals` (Main), `GraceBar` (HUD), `data/tuning/grace.tres`, `data/blessings/`, pingo de cera (`WaxDropField`). Fora do jogo de verdade a Graça fica desligada (metas `grace_manual`/`grace_auto`). **Zonas letais (D-084):** `KillZone`/`KillZones`, `Miracle.open_zone`, aplicadas pelo `EnemyManager`; `WordData.kill_zone`.
- **Arena (004):** estágio da página vem de `WaveData.degradation_stage` (Main emite `page_stage_changed`; `PageDegradation` no `Arena`). Peças em `data/arena/chapter_1.tres` (colisão: `ObstacleMap`/`ObstacleQuery`). Camadas: `tools/gen_arena_placeholders.gd` (rodar `--import` depois); arte do autor por camada em `assets/arena/chapter_1/<bg|ghost_N|ornaments|stage_N>.png`. Ambientes: `data/tuning/arena_ambience.tres`. Sonda A/B: `balance_probe -- cast god wave=N [obstacles=off]` · capítulo: `cast god chapter buy grace only_waves` (nunca um argumento com "boss" no nome) (linha ARENA/STUCK; **no máximo 2 Godot rodando**). Stress no estágio 3: `index.html?stress&stage=3`.
- **Outros:** arte pelas regras de pixel art (art bible §3, D-075/D-076) e sprites em camadas; converter arte do autor com `tools/import_art.gd`. Cutscenes: `data/cutscenes/*.json` + `src/cutscenes/` (debug `?cutscene=c1_01`); frases: `data/barks/barks.json`; falas para dublar: `docs/voice/`. Telas em `src/ui/screens/`; o jogo abre pelo `src/app/app.tscn`. Luta direto: `?boss&unlock=all&atril=8` (sem cutscene); loja: `?shop`. Aberto: C-004, C-006 (playtest do autor, agora com as peças: T413 §6); verbetes que faltam (D-069); C-005 na 011; a sonda `boss` trava na fase 3 (D-081).
- **Combos:** `ComboData` estende `WordData`; `power` só no dano (D-051); detalhes em D-052.
- **Áudio:** `AudioManager` (autoload) + `data/audio/`. Regerar os `.tres`: `godot --headless --path . -s tools/gen_audio_data.gd`; sons provisórios: `-s tools/gen_placeholder_sfx.gd`; lista do que gravar: `-s tools/audio_report.gd` → `docs/AUDIO-LIST.md`.
- **Se o auto mode falhar** (classificador sem veredito): sair do auto mode (Shift+Tab) ou o autor roda os comandos com `!` no chat.
- **Sonda por onda:** `godot --headless --path . -s tools/balance_probe.gd -- cast god wave=N` (linha FLOW; ver T533 §6).
- **Shake:** `ShakeCamera` + `EventBus.shake_requested(px, s)`; opção `GameState.shake_enabled` (a tela de Opções vem na 007).
- **Vitrine:** `index.html?roster` (os 5 inimigos) · `index.html?stress` (SC-001) · `index.html?stress=wave9` (SC-503) · `index.html?stress=purgo|dominus|miserere` e o controle `?stress=ctl` (SC-202).
- **Firefox:** medido pelo Claude (T085 §1.3–1.4): SC-001 ❌ (29–35 FPS). Medir só com janela e `widget.windows.window_occlusion_tracking.enabled=false`.
- **Stress:** `godot --path . res://src/debug/stress_scene.tscn -- quit` (desktop) · `build/web/index.html?stress` (web).
- **Aberto:** C-004 pede playtest humano (alavancas em `docs/reviews/T069-rules-parecer.md` §4).
- **Fonte:** `src/ui/pixel_font.gd` (5×6 feita à mão, atlas em `assets/placeholders/ui_font_atlas.*`), até a fonte do design system.
- **Git:** commit a cada fase; `origin` = github.com/Andersonndiass/scribe_of_the_damned (público, D-064). Sem CI nem itch.
- **Pendências do autor:** áudio; playtest (C-004). Narrativa: `specs/000-game-bible/narrative.md`. Arte: gerada por script a partir das fichas (D-024).
- **Sprites:** placeholders gerados por `tools/gen_placeholders.gd` até os PNGs reais chegarem.
