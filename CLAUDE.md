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

Ordem padrão: game-design → rules → mechanics → design + animation → code.

## Estado atual

- **Etapa:** Etapa 3 — features **001, 005, 002 e 003 Complete**; 009 Fases 1–2 ✅ (áudio com sons provisórios). GUT 287/287. Paleta C (D-048). Chrome: SC-001 87–91 / p95 67–70.
- **Feature atual:** 006 chefe Asmodeus (Fases 1–2 ✅: framework e luta jogável; falta a Fase 3: câmera/shake, sonda do chefe, stress). 009 espera os arquivos do autor.
- **Próximo:** 006 Fase 3 (T620 shake, T621 sonda do chefe e calibração do HP, T622 stress `?stress=boss` e fechamento). Luta direto: `index.html?boss&unlock=all&atril=8`. Dano no chefe: `DamageSource` (marca em `Miracle.dmg()`/`begin_hit()`), `EnemyManager.boss_target`. Loja direto: `index.html?shop`. Sonda do capítulo com loja: `balance_probe -- cast god chapter buy`. Números do escriba: `RunStats.of(data)` (nunca `PlayerData` direto). Playtest: `index.html?unlock=all&atril=8`. Aberto: C-004 (playtest do autor); C-005 adiada para a 011 (D-050).
- **Combos:** `ComboData` estende `WordData`; `power` só no dano (D-051); detalhes em D-052.
- **Áudio:** `AudioManager` (autoload) + `data/audio/`. Regerar os `.tres`: `godot --headless --path . -s tools/gen_audio_data.gd`; sons provisórios: `-s tools/gen_placeholder_sfx.gd`; lista do que gravar: `-s tools/audio_report.gd` → `docs/AUDIO-LIST.md`.
- **Se o auto mode falhar** (classificador sem veredito): sair do auto mode (Shift+Tab) ou o autor roda os comandos com `!` no chat.
- **Sonda por onda:** `godot --headless --path . -s tools/balance_probe.gd -- cast god wave=N` (linha FLOW; ver T533 §6).
- **Pendente de sensação:** screen shake (morte de campeão) — o jogo ainda não tem câmera com shake.
- **Vitrine:** `index.html?roster` (os 5 inimigos) · `index.html?stress` (SC-001) · `index.html?stress=wave9` (SC-503) · `index.html?stress=purgo|dominus|miserere` e o controle `?stress=ctl` (SC-202).
- **Firefox:** medido pelo Claude (T085 §1.3–1.4): SC-001 ❌ (29–35 FPS). Medir só com janela e `widget.windows.window_occlusion_tracking.enabled=false`.
- **Stress:** `godot --path . res://src/debug/stress_scene.tscn -- quit` (desktop) · `build/web/index.html?stress` (web).
- **Aberto:** C-004 pede playtest humano (alavancas em `docs/reviews/T069-rules-parecer.md` §4).
- **Fonte:** `src/ui/pixel_font.gd` (5×6 feita à mão, atlas em `assets/placeholders/ui_font_atlas.*`), até a fonte do design system.
- **Git local** (D-047 9B), commit a cada fase; sem GitHub, CI nem itch.
- **Pendências do autor:** áudio; playtest (C-004). Narrativa: `specs/000-game-bible/narrative.md`. Arte: gerada por script a partir das fichas (D-024).
- **Sprites:** placeholders gerados por `tools/gen_placeholders.gd` até os PNGs reais chegarem.
