<!--
Sync Impact Report
==================
Versão: 1.0.0 -> 1.1.0 (2026-09-24)
v1.0.0: ratificação inicial.
v1.1.0 (MINOR): Princípio VIII — limite de letras por palavra sobe de 6 para 8
(decisão D-006 do autor). Mudança de valor, sem remover princípio.
Origem: escrita pelo Claude Code a partir de BOOTSTRAP.md, PLANO-DE-EXECUCAO.md,
PROMPTS.md, FEATURES.md e das 31 fichas do Claude Design. Nenhuma constituição
anterior existia no repositório.
Status: APROVADA pelo autor no Checkpoint 0 (2026-09-24).
-->

# Constituição — Scribe of the Damned

Esta constituição prevalece sobre qualquer instrução, spec, plano ou task.
Se uma instrução conflitar com ela, o agente **aponta o conflito antes de agir**.

---

## Princípios

### I. As specs são a fonte da verdade (NÃO NEGOCIÁVEL)

O jogo é construído em Spec-Driven Development: primeiro spec, depois plan, depois tasks, e só então código.
- Nada é implementado sem uma task em `specs/<feature>/tasks.md`.
- Nenhuma feature fora da spec. Se a spec for ambígua, **pergunta-se**, não se inventa.
- Número ou mecânica que não está na spec é marcado como `[A DEFINIR]` e sobe para o autor.

### II. Web primeiro (NÃO NEGOCIÁVEL)

A plataforma alvo é o export Web para o itch.io.
- **60 FPS** estáveis no build web (Chrome e Firefox) com 300 inimigos, 150 letras e 200 projéteis na tela.
- Export **single-threaded**, sem SharedArrayBuffer e sem depender de headers COOP/COEP.
- Build web com até 25 MB.
- Toda feature é validada no build web, não só no editor.

### III. Arquitetura: GDScript tipado, componentes, FSM e EventBus

- GDScript com **tipagem estática em tudo**: variáveis, parâmetros e retornos. Nada de C# nem GDExtension.
- Comportamento é composto por **componentes** (Health, Hitbox, Hurtbox, Flash…), não por herança profunda.
- Estados de entidade (jogador, chefe, atril) usam **StateMachine/State** genéricos.
- Sistemas se comunicam pelo **EventBus** (autoload de sinais). Um sistema não busca nó de outro sistema por caminho.

### IV. Conteúdo é dado (NÃO NEGOCIÁVEL)

Palavras, inimigos, ondas, itens, personagens, chefes, fases, ataques e cutscenes vivem em `.tres` (Resources tipados) ou `.json`, **nunca hardcoded**.
- Adicionar conteúdo novo deve ser **só um arquivo novo**. Se exigir código, justifica-se antes.
- Números de balanceamento só existem nos arquivos de dados.

### V. Performance por construção

- **Pooling** para inimigos, letras, projéteis, VFX e números de dano. **Zero `instantiate()` durante uma onda.** Os pools são pré-aquecidos antes dela.
- Inimigos comuns **não** são `CharacterBody2D`. Um único `_physics_process` no EnemyManager move todos eles.
- Vizinhança e separação passam por um **SpatialHash**, nunca por busca O(n²).
- Custos fixos quando possível. Exemplo: decals acumulados num SubViewport.

### VI. Testes GUT

- Lógica pura (Lexicon, Atril, LetterDropper, economia da loja, RunStats, escolha de ataque do chefe) é escrita **com o teste primeiro**.
- Todo bug corrigido ganha um teste GUT que falhava antes da correção.
- Ao fim de cada fase: rodar o GUT, rodar o export web e relatar o que passou e o que quebrou.

### VII. Paleta travada e pixel-perfect

- Só as cores de `specs/000-game-bible/design-tokens.json`. BLOOD e GOLD só onde o art bible permite.
- Resolução base 640×360, filtro Nearest, sem mipmaps, sem sub-pixel.
- Nada de degradê, blur, antialiasing ou alpha desenhado: sombra por hachura e transparência por dithering.
- Todo asset novo passa pelo **design-agent** e entrega a ficha do art bible §15.

### VIII. Latim real, de 3 a 8 letras

- Toda palavra conjurável é latim real, tem **de 3 a 8 letras** e usa só letras do alfabeto do jogo. O Lexicon **falha no load** se isso for violado.
- O poder de um milagre cresce com o tamanho da palavra (validado por teste).
- No gameplay o latim nunca é traduzido. A tradução existe só no Grimório.

### IX. Cutscenes in-engine (NÃO NEGOCIÁVEL)

Toda cutscene roda no motor, com AnimationPlayer, camadas e o builder JSON→Animation. **Nada de vídeo pré-renderizado.**

### X. Acessível e legível

- Todos os menus são **100% navegáveis só por teclado**, com foco sempre visível.
- Todo sprite é legível em 1× sobre pergaminho.
- Textos de UI são localizados (PT-BR e EN). O latim fica fora da localização.

---

## Restrições técnicas

| Item | Valor |
|---|---|
| Motor | **Godot 4.7.2 stable**, build padrão (não mono) |
| Renderer | Compatibility (`gl_compatibility`) |
| Viewport | 640×360, stretch `canvas_items`, aspect `keep` |
| Textura | Filtro Nearest, sem mipmaps |
| Testes | GUT (addon em `addons/gut/`, versão compatível com 4.7, fixada no repo) |
| CI | Testes + export web + butler (canal privado; tags publicam) |
| Save | Só a camada de persistência toca disco (`user://`). No web, via IndexedDB do próprio Godot |

## Fluxo de desenvolvimento

1. A feature nasce em `specs/<NNN>-<nome>/` com `spec.md` → `plan.md` → `tasks.md`.
2. Antes de gerar código: mostrar a lista de arquivos e esperar o ok do autor.
3. Ordem dos agentes: game-design → rules → mechanics → design + animation → code.
4. Número ou mecânica nova passa pelo **rules-agent**, arte pelo **design-agent**, tempo e sensação pelo **animation-agent**.
5. Ao fim de cada feature: atualizar `FEATURES.md`, `CLAUDE.md` (estado atual) e `docs/DECISIONS.md`.

## Governança

- Emendas são registradas em `docs/DECISIONS.md` e sobem a versão deste arquivo: MAJOR remove ou redefine um princípio, MINOR acrescenta um, PATCH só esclarece.
- Todo review de código confere a conformidade com esta constituição.
- Os princípios marcados **NÃO NEGOCIÁVEL** só mudam com pedido explícito do autor.
