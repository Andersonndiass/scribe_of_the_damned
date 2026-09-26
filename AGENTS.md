# Agentes — Scribe of the Damned

Seis agentes especializados, definidos em `.claude/agents/`. Cada um tem escopo fechado e **rejeita** o que sai dele.

## Ordem de acionamento

```
game-design ──► rules ──► mechanics ──► design ─┐
                                    └─► animation ─┴──► code
```

1. **game-design** decide *se* algo pertence ao jogo.
2. **rules** fixa *quanto*: números e regras concretas.
3. **mechanics** define *como funciona no motor*: estados, eventos e dados.
4. **design** e **animation** (em paralelo) definem *como parece* e *como se move*.
5. **code** implementa e testa.

Nem toda mudança passa por todos. Ajuste de número: rules → code. Sprite novo: design → animation → code.

## Catálogo

| Agente | Escopo | Fora de escopo | Fontes que lê | Saída |
|---|---|---|---|---|
| `game-design-agent` | Pilares, fantasia, curva de dificuldade, progressão, economia, escopo. Decide se uma feature pertence ao jogo | Números exatos, implementação, arte | constituição, `000/spec.md`, `FEATURES.md` | Parecer ACEITA / REJEITA / AJUSTAR, com o pilar afetado |
| `rules-agent` | Dicionário (latim real, 3 a 8 letras), combos, heresia, drop ponderado, stats, ondas, preços, fases de chefe. Valida todo número | Implementação, arte, decidir escopo | constituição, `000/spec.md`, specs da feature, `data/` | Tabela de regras e números + parecer de validação |
| `mechanics-agent` | Traduz regra em sistema: FSM, fluxo de eventos, componentes, contratos de dados (Resources) | Código final, números, arte | `plan.md`, `data-model.md`, EventBus, regras do rules-agent | Diagrama de estados + sinais + campos de Resource |
| `design-agent` | Paleta, tamanhos, frames, silhuetas, UI, legibilidade. Valida assets | Tempos, código, regras | `art-bible.md`, `design-tokens.json`, `ASSET-CATALOG.md`, fichas | Ficha §15 + checklist aprovado/reprovado |
| `animation-agent` | Tempos, cadência, squash & stretch, hit-stop, shake, easing, cutscenes in-engine | Paleta, números de gameplay, código final | `art-bible.md` §14, fichas, roteiros de cutscene | Tabela de tempos e keyframes / trilhas de AnimationPlayer |
| `code-agent` | GDScript tipado, arquitetura dos plans, performance (pooling, SpatialHash, 60 FPS web), GUT, revisão | Inventar regra, número ou arte | constituição, `CLAUDE.md`, `plan.md`, `tasks.md` | Código + testes + relatório GUT/export |

## Regras comuns a todos

- A constituição prevalece. Um conflito é apontado, nunca resolvido em silêncio.
- Um agente não faz o trabalho de outro: devolve a questão ao agente certo.
- Toda decisão relevante vai para `docs/DECISIONS.md`.
- `[A DEFINIR]` na spec é perguntado ao autor, nunca preenchido por conta própria.
