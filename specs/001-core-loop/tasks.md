# 001 — Tasks

Legenda: `[P]` = pode rodar em paralelo · `[TEST-FIRST]` = o teste é escrito e falha **antes** da implementação · ✅ feito · ⏸ adiado.
Numeração preservada do `PROMPTS.md`.

## Fase 0 — Setup

- ✅ **T000** `AGENTS.md` na raiz (Etapa 0).
- ✅ **T001** `.claude/agents/rules-agent.md` (Etapa 0).
- ✅ **T002** `.claude/agents/design-agent.md` (Etapa 0, junto com os outros 4 agentes).
- ✅ **T003** Configurar o `project.godot` conforme o plan §2: viewport, stretch, Nearest, snap, Compatibility, input map; remover Jolt e d3d12.
- ✅ **T004** Instalar o GUT em `addons/gut/` (versão compatível com 4.7), com `.gutconfig.json` apontando para `res://tests`.
- ✅ **T005** Preset de export `Web` single-threaded (`export_presets.cfg`); confirmar que o template 4.7.2 está instalado.
- ⏸ **T006** CI (testes + export + butler). **Adiado pela D-021** (sem git e sem itch por enquanto).
- ✅ **T007** Criar a estrutura de pastas do plan §3 (com `.gdignore` em `build/`), `.gitignore` e `.gitattributes` prontos para quando houver git.
- ✅ **T008** `tools/gen_palette.gd`: lê `specs/000-game-bible/design-tokens.json` e gera `src/core/palette.gd` (constantes `Color`).

**✅ Checkpoint M0 — ALCANÇADO (2026-09-24):** o projeto abre, o GUT roda (0 testes, verde) e o export web gera `build/web/index.html`, que abre no navegador com a página vazia.

## Fase 1 — Fundações de código

- ✅ **T010** `src/core/event_bus.gd` com os 15 sinais do plan §4.3, todos tipados.
- ✅ **T011** [P] `src/core/state_machine.gd` + `state.gd` (plan §4.4).
- ✅ **T012** [P] `src/core/pool_manager.gd` (plan §4.5) + `tests/unit/test_pool_manager.gd`.
- ✅ **T013** [P] [TEST-FIRST] `tests/unit/test_spatial_hash.gd` (1000 pontos contra força bruta).
- ✅ **T014** `src/core/spatial_hash.gd`, fazendo o T013 passar.
- ✅ **T015** Os 7 Resources do `data-model.md` em `src/data/`.
- ✅ **T016** [P] Componentes `health.gd`, `hitbox.gd`, `hurtbox.gd`.
- ✅ **T017** [P] `flash.gd` + `assets/shaders/hit_flash.gdshader` (60ms, flash CHALK).
- ✅ **T018** `src/core/game_state.gd` (autoload) + `hitstop.gd` (autoload que escuta `hitstop_requested`).

**Relatório:** saída do GUT.

## Fase 2 — Jogador e arena

- ✅ **T020** `tools/gen_placeholders.gd`: gera PNGs de placeholder nos tamanhos do `ASSET-CATALOG.md` (Anselmo 16×16, Diabrete 12×12, letras 10×10, InkDrop, HUD) com cores da paleta.
- ✅ **T021** `src/arena/arena.tscn`: página 640×360, paredes na margem de 24px, camada de decals (SubViewport).
- ✅ **T022** `src/player/player.tscn`: movimento de 8 direções a 90 px/s lido de `data/player/anselmo.tres` (FR-001).
- ✅ **T023** FSM do jogador (Idle, Run, Stunned, Hurt, Dead) + velas, i-frames e regeneração parado (FR-003, FR-004, FR-005).
- ✅ **T024** `auto_attack.gd` + `ink_drop.tscn` pooled (FR-002). Por enquanto mira num alvo de teste; liga no EnemyManager na Fase 3.
- ✅ **T025** Squash & stretch (corrida 1.1/0.9, dano 1.2/0.8) e flash de acerto.

**✅ Checkpoint — ALCANÇADO (2026-09-24):** o Anselmo anda em 8 direções, colide com a margem e dispara a cada 0.8s.

## Fase 3 — Inimigos e ondas

- ✅ **T030** `enemy_manager.gd`: arrays de estado, loop único, steering (plan §4.8, FR-007).
- ✅ **T031** Separação via SpatialHash + `nearest()` para o AutoAttack.
- ✅ **T032** `data/enemies/imp.tres` + `enemy_renderer.gd` (Sprite2D pooled na primeira versão).
- ✅ **T033** Contato com o jogador: dano pelo nível (1 fraco / 2 forte) respeitando os i-frames (FR-003).
- ✅ **T034** `spawn_telegraph.tscn` pooled + spawn a pelo menos `min_spawn_distance` do jogador (FR-009).
- ✅ **T035** `data/waves/chapter_1/wave_01.tres` com os grupos do data-model §6.
- ✅ **T036** `wave_director.gd`: lê o WaveData, interpola o ritmo, emite `wave_started`/`wave_ended` e dissolve os restantes (FR-010).
- ✅ **T037** Morte: dissolução §6.1 (placeholder de 6 frames), decal e `enemy_killed`. Integração `test_wave_flow.gd`.

**✅ Checkpoint M1 — ALCANÇADO (2026-09-24):** matar Diabretes numa onda de 60s.

## Fase 4 — Letras, Atril e Lexicon

- ✅ **T040** [TEST-FIRST] `tests/unit/test_lexicon.gd`.
- ✅ **T041** `src/letters/lexicon.gd` (trie + validação de 3 a 8 letras que falha no load) + `data/lexicon/base.tres` + os 7 `data/words/*.tres`.
- ✅ **T042** [TEST-FIRST] `tests/unit/test_atril.gd`.
- ✅ **T043** `src/letters/atril.gd` (FR-015, FR-016).
- ✅ **T044** [TEST-FIRST] `tests/unit/test_letter_dropper.gd` (estatístico, seed fixa; SC-005).
- ✅ **T045** `src/letters/letter_dropper.gd` + `data/tuning/drop_tuning.tres` (FR-013).
- ✅ **T046** `letter.tscn` pooled: vida de 8s, pisca-pisca nos últimos 2s, indicador de letra-alvo, visual da letra rara.
- ✅ **T047** Ímã: tween QUAD_IN dentro do raio e coleta → `Atril.push` → `letter_collected` / `letter_rejected` (a recusada fica no chão).
- ✅ **T048** `tests/unit/test_word_power.gd` (poder cresce com o tamanho; FR-018).
- ✅ **T049** `caster.gd` + `miracle.gd` (base) + hitstop de 60ms + flash de 8×8 na pena (FR-017).
- ✅ **T050** Milagre **LUX**.
- ✅ **T051** Input de cast ligado + integração `test_cast_lux.gd`.

**✅ Checkpoint M2 — ALCANÇADO (2026-09-24):** coletar L, U, X e conjurar LUX.

## Fase 5 — Palavras base, heresia e purge

- ✅ **T060** [P] Milagre **PAX**.
- ✅ **T061** [P] Milagre **CRUX** (com bloqueio de projéteis; o teste usa um projétil inimigo de mentira, porque os de verdade chegam na 005).
- ✅ **T062** [P] Milagre **VITA**.
- ✅ **T063** [P] Milagre **AQUA**.
- ✅ **T064** [P] Milagre **IGNIS** (com decal queimado na página).
- ✅ **T065** [P] Milagre **MORTIS** (em lotes de 50 por frame; o teste usa atril 6).
- ✅ **T066** Estado de rara: multiplicador de 1.5 por vogal rara aplicado ao `power` (FR-018).
- ✅ **T067** **Heresia** (FR-019): stun, poça de aggro que o EnemyManager usa como alvo, atril limpo, `heresy_committed`.
- ✅ **T068** **Purge** (FR-020): anel de letras no chão, trava de 0.3s, `atril_purged`.
- ✅ **T069** Parecer do **rules-agent** sobre os números das 7 palavras, da heresia e do drop; mostrar ao autor.

**✅ Checkpoint M3 — ALCANÇADO (2026-09-24).** Parecer: `docs/reviews/T069-rules-parecer.md`.

## Fase 6 — HUD e degradação

- ✅ **T070** `hud.tscn` com o layout do plan §4.11; conferir o retângulo seguro com o design-agent.
- ✅ **T071** Velas: até 8, acesa/apagada, pulso quando HP=1.
- ✅ **T072** Atril: espaços iguais à capacidade e estados EMPTY, FILL, PARTIAL, VALID, FULL_REJECT + animações CAST, PURGE, HERESY (art bible §8.3).
- ✅ **T073** Dicas: até 3 palavras possíveis para o prefixo (FR-023).
- ✅ **T074** Tab: lista das palavras conhecidas, destacando as que cabem (FR-024).
- ✅ **T075** Timer + "Onda N".
- ✅ **T076** Degradação da página: 4 estágios + decals acumulados no SubViewport (FR-026).
- ✅ **T077** Pausa mínima com Esc (FR-025).
- ✅ **T078** Game Over mínimo + reiniciar (FR-005).

**✅ Checkpoint M4 — ALCANÇADO (2026-09-24):** uma onda completa jogável.

## Fase 7 — Performance

- ✅ **T080** `src/debug/stress_scene.tscn`: 300 inimigos + 150 letras + 200 projéteis, com `fps_probe.gd` (média e p95 em 30s).
- ✅ **T081** Prewarm de todos os pools antes da onda 1; contador de instantiate zerado no início da onda.
- ✅ **T082** *(revisado, D-038/D-039: laços sem alocação + steering escalonado com interpolação, em vez de MultiMesh)* **Condicional:** se o SC-001 falhar, migrar o EnemyRenderer para MultiMesh e mostrar o antes e depois.
- ✅ **T083** Integração `test_zero_instantiate.gd` (SC-002).
- ✅ **T084** *(Chrome: média 86–90, p95 67–68 ✅ · Firefox: medir no computador do autor)* Medir no build web, no Chrome e no Firefox; registrar a máquina e os números.
- ✅ **T085** Relatório de profiling: os 5 maiores custos por frame.
- ✅ **T086** `FEATURES.md`: 001 → **Complete**; atualizar `CLAUDE.md` e `docs/DECISIONS.md`.

**✅ Checkpoint M5 — ALCANÇADO (2026-09-25):** SC-002 ✅ · SC-001 ✅ no Chrome (Firefox pendente). Ver `docs/reviews/T085-performance.md`.
