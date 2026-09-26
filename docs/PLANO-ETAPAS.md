# Plano de execução revisado

> 2026-09-24. Parte do `PLANO-DE-EXECUCAO.md` do autor e o ajusta à realidade do repositório.
> Divergências numeradas **DV-xx**; riscos, **R-xx**.

## Divergências entre o plano original e o repositório

| ID | Divergência | Impacto | Proposta |
|---|---|---|---|
| DV-01 | O `FEATURES.md` marca 001–015 como "Tasked ✅", mas **não existe nenhum spec, plan ou tasks** no repo | Nenhuma etapa de código pode seguir o Princípio I | Nova **Etapa 0.5**: escrever as specs *just-in-time*, uma feature antes de implementá-la. Começar pela 001 |
| DV-02 | O PROMPTS e o PLANO citam IDs de tasks (T000–T086, FR-013, FR-202, FR-306, SC-001/002/202/401/702) | Os prompts do autor dependem desses números | Ao escrever a spec 001, **preservar essa numeração** (ex.: T020–T025 = jogador e arena, T040–T051 = letras, atril e LUX) |
| DV-03 | O PROMPTS A1 manda criar AGENTS.md, rules-agent e design-agent nas T000–T002 | Já feito na Etapa 0 (com os 6 agentes) | T000–T002 ficam marcadas como concluídas |
| DV-04 | `assets/sprites/` não existe; as fichas não trazem pixels (estão em `scribe-*.js`) | Não há arte real para B1 em diante | Placeholders no tamanho exato do catálogo + ferramenta `tools/render_sheets.mjs` (Node) que converte os `scribe-*.js` em PNG quando o autor exportar |
| DV-05 | **O diretório não é um repositório git** | Não há CI (T006) nem butler | ✅ Decidido (D-021): sem git, CI nem itch por enquanto. T006 adiada; M0 = build web local + GUT verde |
| DV-06 | Hex da paleta desconhecidos | `palette.gd` (T008) sairia com cores provisórias | Seguir com os provisórios (D-004) e trocar quando o `colors.css` chegar; é uma troca de um arquivo só |
| DV-07 | O `project.godot` atual tem `aspect="expand"`, driver d3d12 e Jolt 3D | Viola o Princípio VII (`keep`) | T003 corrige: `keep`, Nearest, Compatibility, sem 3D |
| DV-08 | Godot 4.7.2 em vez de 4.3 | GUT e preset web precisam ser compatíveis | T004 fixa uma versão do GUT testada no 4.7; T005 confere o template web do 4.7.2 (single-threaded) |
| DV-09 | VERBUM usa B, que está reservado (C-001) | Afeta a 002 | ✅ Resolvido (D-015): B ativado, só cai depois de VERBUM |
| DV-10 | Não há roteiros de cutscene nem áudio | Afeta a 008 e a 009 | Escrever os roteiros na spec 008; áudio com placeholders silenciosos (já previsto no PROMPTS D4) |
| DV-11 | Não há ficha 03 (Tomé) nem 32 e 33 | Tomé sem sprite na 010 | Placeholder; pedir as fichas |

## Riscos técnicos principais

| ID | Risco | Mitigação |
|---|---|---|
| R-01 | **60 FPS no web com 300 inimigos + 150 letras + 200 projéteis** (single-threaded, Compatibility) | EnemyManager em loop único, SpatialHash, pools pré-aquecidos; cena de stress cedo (Etapa 2.6); MultiMesh se medir abaixo da meta |
| R-02 | **Drop ponderado divertido e justo**: o jogador precisa conseguir formar palavras sem que o jogo pareça "roubado" | LetterDropper com teste estatístico de seed fixa; pesos em `.tres`; o rules-agent valida; playtest no M2 |
| R-03 | **Pipeline de arte**: 31 fichas sem pixels, ~800+ frames para gerar | Renderizar os `scribe-*.js` em PNG por script, sem redesenho manual; o design-agent confere dimensões e paleta automaticamente |
| R-04 | Builder JSON→Animation das cutscenes (tolerância de 1 frame) | Construído na 008 com teste que compara cada `t=` do roteiro |
| R-05 | Specs escritas pelo Claude divergirem da intenção do autor | Marcações [INFERIDO]/[A DEFINIR] + checkpoint de aprovação a cada spec |

## Etapas

### Etapa 0 — Memória e agentes ✅ (aprovada no Checkpoint 0)
Constituição, game bible, art bible, tokens, INDEX, CLAUDE, AGENTS, DECISIONS, GLOSSARIO e os 6 agentes.
**✅ Checkpoint 0:** o autor revisa e responde às perguntas abertas da game bible §7.

### Etapa 0.5 — Spec 001 ✅ (entregue, aguardando o Checkpoint 0.5)
Escrever `specs/001-core-loop/` com `spec.md`, `plan.md` (§3 pastas, §4.3 os 15 sinais, §4.8 inimigos), `data-model.md` (7 Resources) e `tasks.md` (T000–T086), preservando a numeração dos prompts.
Pré-requisito: respostas às perguntas 1–4 da game bible §7 (atril, velas, efeito das 7 palavras, heresia).
**✅ Checkpoint 0.5:** spec 001 aprovada.

### Etapa 1 — Fundação técnica (001, T003–T018)
- **T003** `project.godot`: 640×360, `canvas_items`/`keep`, Nearest, Compatibility.
- **T004** GUT em `addons/gut/`. **T005** preset Web single-threaded.
- **T006** CI (GitHub Actions: GUT + export + butler privado). ⚠️ Depende da DV-05.
- **T007** estrutura de pastas. **T008** `tools/gen_palette.gd` → `src/core/palette.gd`.
- **T010–T018** EventBus (15 sinais), StateMachine/State, PoolManager, SpatialHash + teste com 1000 pontos, os 7 Resources, componentes (Health, Hitbox, Hurtbox, Flash + shader) e GameState.
**✅ M0:** build web vazio abrindo, GUT verde, CI verde.

### Etapa 2 — Core loop (001, fases 2–7)
1. Jogador e arena (T020–T025).
2. Inimigos e ondas (T030–T037). **✅ M1**
3. Letras, Atril e Lexicon, com teste antes (T040–T051). **✅ M2** (conjurar LUX)
4. As 6 palavras, heresia e purge (T060–T069). **✅ M3**
5. HUD e degradação (T070–T078). **✅ M4**
6. Performance e stress (T080–T086). **✅ M5**

### Etapa 3 — Sistemas (spec → implementação, nesta ordem): 005 → 002 → 003 → 004
Antes de cada uma: escrever a spec, aprovar e depois implementar. A 002 depende da C-001 (VERBUM).
**✅ Checkpoint:** Cap. 1 jogável até a onda 9, com loja.

### Etapa 4 — Chefe e apresentação: 006 → 007 → 008 → 009 → 010
**✅ Checkpoint:** Cap. 1 completo, do menu ao fim do chefe.

### Etapa 5 — Demo (011)
**✅ Checkpoint:** demo v0.1.0 publicada (≤25 MB).

### Etapa 6 — Capítulos 2–5 (012 → 013 → 014 → 015)
**✅ Checkpoint final:** campanha completa.

## Ordem de dependências

```
000 ─► 001 ─┬─► 005 ─┐
            ├─► 002 ─┼─► 006 ─► 012 ─► 013 ─► 014 ─► 015
            ├─► 003 ─┼─► 010
            ├─► 004  │
            └─► 007 ─┴─► 008 · 009 ─► 011 (demo)
```

## O que o autor precisa fornecer (em ordem de urgência)

1. **Checkpoint 0:** aprovar ou corrigir a constituição e a game bible, e responder à §7 (perguntas 1–4 bloqueiam a spec 001).
2. **Git:** autorizar `git init` e informar o remoto no GitHub (bloqueia T006).
3. **Export do Claude Design** com `scribe-*.js` e `_ds/` (bloqueia a arte real e os hex da paleta).
4. Conta ou projeto no itch e `BUTLER_API_KEY` (bloqueia o M0 publicado).
