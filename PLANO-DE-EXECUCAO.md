# Plano de Execução — Scribe of the Damned
Documento para ser entregue ao Claude Code. Ele executa na ordem, parando em cada ✅ checkpoint.

## Etapa 0 — Memória e agentes (antes de qualquer código)
1. Ler `.specify/memory/constitution.md`, `specs/000-game-bible/spec.md`, `art-bible.md`, `design-tokens.json`, `FEATURES.md` e `specs/001-core-loop/*`.
2. Criar `INDEX.md`: o que é o jogo, mapa de pastas, glossário curto, estado atual e links.
3. Criar `CLAUDE.md`: stack, comandos, convenções, proibições, quando acionar cada agente, checkpoint atual.
4. Criar `AGENTS.md`: catálogo dos 6 agentes, com escopo, fora de escopo, fontes e ordem de acionamento.
5. Criar `docs/DECISIONS.md` (log de decisões) e `docs/GLOSSARIO.md`.
6. Criar os 6 agentes em `.claude/agents/`: game-design, rules, mechanics, design, animation, code.
7. Relatório: o que foi criado e quais lacunas encontrou nas specs.
✅ **Checkpoint 0:** memória e agentes revisados por mim.

## Etapa 1 — Fundação técnica (001, Fases 0 e 1 · T003–T018)
Projeto Godot 4.7 (640×360, Compatibility, Nearest), GUT, estrutura de pastas do plan §3, export web single-threaded, CI com testes + export + butler, `palette.gd` gerado dos tokens, EventBus (15 sinais), StateMachine, PoolManager, SpatialHash + teste, os 7 Resources do data-model, componentes e GameState.
✅ **Checkpoint M0:** build web vazio publicado (privado) e CI verde.

## Etapa 2 — Core loop (001, Fases 2 a 7)
1. Jogador: movimento, estados, i-frames, ataque automático, arena (T020–T025).
2. Inimigos e ondas: EnemyManager em loop único, Diabrete, spawn com telegrafia, WaveDirector (T030–T037). ✅ **M1**
3. Letras, Atril e Lexicon, com **testes antes da implementação**, e LUX (T040–T051). ✅ **M2**
4. As 6 palavras restantes, heresia e purge (T060–T069). ✅ **M3**
5. HUD e degradação da página (T070–T078). ✅ **M4**
6. Performance: stress de 300 inimigos no web, prewarm, zero instantiate na onda (T080–T086). ✅ **M5**

## Etapa 3 — Sistemas (002 a 005, nesta ordem)
- **005** inimigos e as 9 ondas do Cap. 1 (base para testar tudo).
- **002** combos e apócrifos.
- **003** loja, RunStats e itens.
- **004** degradação completa e arenas dos 5 capítulos.
✅ **Checkpoint:** Capítulo 1 jogável até a onda 9, com loja entre ondas.

## Etapa 4 — Chefe e apresentação
- **006** framework de chefes (reutilizado por 012–015) e Asmodeus.
- **007** telas e menus, com navegação 100% por teclado.
- **008** cutscenes in-engine (CutsceneStage, builder JSON, C1-01/03/04 e tutorial).
- **009** áudio.
- **010** personagens e desbloqueios.
✅ **Checkpoint:** Capítulo 1 completo, do menu ao fim do chefe.

## Etapa 5 — Demo (011)
Presets, shell HTML, otimização de tamanho, save no web, CI com butler em tags, QA e publicação.
✅ **Checkpoint:** demo v0.1.0 publicada.

## Etapa 6 — Capítulos 2 a 5 (012 → 013 → 014 → 015)
Um capítulo por vez: inimigo novo, 10 ondas, chefe (reusando o framework) e cutscenes (reusando o sistema da 008).
✅ **Checkpoint final:** campanha completa e `FEATURES.md` 100%.

## Regras de execução (valem para todas as etapas)
1. A constituição prevalece. Conflito com instrução minha: apontar antes de agir.
2. Mostrar o plano de arquivos e esperar meu ok antes de gerar código.
3. Não pular tarefas nem criar features fora da spec. Ambiguidade: perguntar.
4. Conteúdo em `.tres`/`.json`, nunca hardcoded.
5. GDScript tipado, componentes, state machines e EventBus.
6. Fim de cada fase: rodar GUT, rodar export web, relatar o que passou e o que quebrou.
7. Números e mecânicas novas passam pelo `rules-agent`; arte pelo `design-agent`; tempos e feel pelo `animation-agent`.
8. Cutscenes sempre in-engine (AnimationPlayer). Nada de vídeo.
9. Ao fim de cada feature: atualizar `FEATURES.md`, `CLAUDE.md` (estado atual) e `docs/DECISIONS.md`.
