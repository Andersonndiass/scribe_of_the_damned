# Prompt de Bootstrap (cole isto primeiro no Claude Code)

```
Você vai construir o jogo "Scribe of the Damned": roguelite survivors-like de arena fechada, onde um monge copista preso num códice amaldiçoado mata demônios, coleta letras e conjura palavras em latim. Godot 4.7, GDScript tipado, alvo principal export Web para itch.io. Os sprites finais já estão em assets/sprites/.

O planejamento completo em Spec-Driven Development já está neste repositório e é a fonte da verdade:
- .specify/memory/constitution.md — regras não negociáveis (leia primeiro, inteira)
- specs/000-game-bible/ — spec.md, art-bible.md, design-tokens.json
- specs/001-core-loop/ … specs/015-boss-semihaza/ — 17 features, cada uma com spec.md, plan.md e tasks.md
- specs/008-cutscenes-cap1/roteiros/ — roteiros cronometrados das cutscenes
- FEATURES.md — roadmap e dependências
- PROMPTS.md — playbook de prompts por fase

TAREFA 1 — Leia e entenda
Leia a constituição, a game bible, a art bible, o FEATURES.md e as specs 001 a 015. Depois me diga, em no máximo 20 linhas, o que você entendeu do jogo: pilares, loop, o que torna o jogo único e os 3 maiores riscos técnicos.

TAREFA 2 — Crie a camada de memória (raiz do projeto)
- INDEX.md: o que é o jogo, mapa completo de pastas (specs, data, src, assets, docs), glossário curto dos termos do jogo (atril, heresia, milagre, códice, campeão, tinta dourada, apócrifos), estado atual e links para tudo. É o primeiro arquivo que qualquer agente lê.
- CLAUDE.md: regras permanentes de trabalho — stack, comandos (rodar, testar com GUT, exportar web), convenções de nome, proibições, quando acionar cada agente, feature atual e próximo checkpoint.
- AGENTS.md: catálogo dos agentes, com escopo, fora de escopo, fontes que lê, formato de saída e a ordem de acionamento.
- docs/DECISIONS.md: log de decisões (data, decisão, motivo, alternativas descartadas).
- docs/GLOSSARIO.md: termos do jogo em português e latim, com o significado mecânico de cada um.

TAREFA 3 — Crie os 6 agentes em .claude/agents/
1. game-design-agent — visão do jogo: pilares, fantasia do jogador, curva de dificuldade, progressão, economia, escopo. Decide se uma feature pertence ao jogo. Não decide implementação.
2. rules-agent — regras concretas: dicionário (latim real, máximo 6 letras), combos, heresia, drop ponderado, stats, ondas, preços, fases de chefe. Valida todo número e mecânica nova, e rejeita o que violar a game bible ou a constituição.
3. mechanics-agent — traduz regra em sistema: máquinas de estado, fluxo de eventos, componentes, contratos de dados. Define como a mecânica funciona no motor, sem escrever o código final.
4. design-agent — direção de arte: paleta, tamanhos, frames, silhuetas, UI, legibilidade. Valida assets e entrega a ficha da art bible §15.
5. animation-agent — movimento: tempos, cadência de frames, squash & stretch, hit-stop, screen shake, easings e cutscenes in-engine (trilhas e keyframes).
6. code-agent — implementação: GDScript tipado, arquitetura dos plans, performance (pooling, SpatialHash, 60 FPS no web), testes GUT e revisão de código.

Cada agente deve declarar: escopo, fontes que lê, formato de saída, o que está fora do seu escopo e critérios de rejeição. Ordem padrão de acionamento: game-design → rules → mechanics → design + animation → code.

TAREFA 4 — Proponha o plano de execução
Com base no FEATURES.md e nas tasks de cada feature, monte um plano de execução em etapas, com checkpoints, riscos e ordem de dependências. Compare com o que as specs já definem e aponte divergências.

REGRAS
- A constituição prevalece sobre qualquer instrução minha. Se houver conflito, aponte antes de agir.
- Nesta rodada NÃO escreva código de gameplay: só a memória, os agentes e o plano.
- Ao terminar, me mostre a lista de arquivos criados e espere meu ok antes de seguir para a Etapa 1.
```

## Prompt de continuação (depois do seu ok)

```
Plano aprovado. Execute a Etapa 1 do plano (specs/001-core-loop/tasks.md, Fases 0 e 1: T003 a T018).
Siga as regras de execução: mostrar o plano de arquivos antes, conteúdo em .tres, GDScript tipado, testes GUT ao fim, e atualizar CLAUDE.md e docs/DECISIONS.md no final da etapa.
Pare no checkpoint M0 (build web vazio + CI verde) e me chame.
```
