# Playbook de Prompts — Scribe of the Damned
Sequência de prompts para o **Claude Code** construir o jogo inteiro a partir das specs já escritas.

**Como usar:** um prompt por vez, na ordem. Em todo prompt vale a **Regra da Casa** abaixo. Pare em cada ✅ checkpoint, jogue/teste, e só então avance.

---

## Regra da Casa (cole no CLAUDE.md do projeto, uma vez)
```
REGRAS PERMANENTES DESTE PROJETO

1. Antes de escrever código, leia .specify/memory/constitution.md. Ela prevalece sobre qualquer instrução minha que a contrarie; se houver conflito, aponte antes de agir.
2. Sempre me mostre o plano de execução (lista de arquivos e ordem) e espere meu ok antes de gerar código.
3. Nunca pule tarefas das tasks.md nem invente features fora da spec. Se a spec estiver ambígua, pergunte.
4. Conteúdo (palavras, inimigos, ondas, itens, chefes, cutscenes) vive em .tres/.json, nunca hardcoded.
5. GDScript tipado, componentes + state machines, comunicação por EventBus.
6. Depois de cada fase: rode os testes GUT, rode o export web e me diga o que passou e o que quebrou.
7. Mudanças em números de balanceamento passam pelo rules-agent; mudanças visuais passam pelo design-agent.
8. Cutscenes são sempre in-engine (AnimationPlayer). Nada de vídeo pré-renderizado.
9. Ao terminar uma feature, atualize o status dela em FEATURES.md.
```

---

## FASE A — Fundação

### A1 · Onboarding e agentes (T000–T008)
```
Contexto: jogo "Scribe of the Damned", roguelite survivors-like com combate por palavras em latim, Godot 4.7, GDScript tipado, alvo principal export Web (itch.io). O planejamento SDD completo está no repo:
- .specify/memory/constitution.md
- specs/000-game-bible/{spec.md, art-bible.md, design-tokens.json}
- specs/001-core-loop/{spec.md, plan.md, data-model.md, tasks.md}
- FEATURES.md
Os sprites finais estão em assets/sprites/.

Tarefa: executar a Fase 0 de specs/001-core-loop/tasks.md (T000 a T008).
Comece por T000–T002: AGENTS.md na raiz + .claude/agents/rules-agent.md + .claude/agents/design-agent.md, exatamente como as tasks descrevem.
Depois T003–T008: projeto Godot (640x360, canvas_items, keep, Nearest, Compatibility), GUT, estrutura de pastas do plan §3, export preset web single-threaded, CI (testes + export + butler em canal privado) e tools/gen_palette.gd gerando src/core/palette.gd a partir de design-tokens.json.

Antes de gerar, me mostre a lista de arquivos que vai criar.
```
✅ **Checkpoint M0:** build web vazio abre no itch e o CI está verde.

### A2 · Fundações de código (T010–T018)
```
Execute a Fase 1 de specs/001-core-loop/tasks.md (T010 a T018): EventBus com os 15 sinais do plan §4.3, StateMachine/State genéricos, PoolManager, SpatialHash + teste GUT com 1000 pontos, os 7 Resources do data-model.md, os componentes (Health, Hitbox, Hurtbox, Flash com shader de hit flash) e o GameState.

Nada de lógica de gameplay ainda. Ao fim, rode os testes e me mostre a saída.
```

---

## FASE B — Core Loop (feature 001)

### B1 · Jogador e arena (T020–T025)
```
Execute a Fase 2 de specs/001-core-loop/tasks.md (T020 a T025). Use os sprites reais de assets/sprites/chr e env; se faltar algum, crie placeholder no tamanho da art bible e me liste o que falta.
Quero poder rodar o jogo e: andar em 8 direções a 90 px/s, colidir com a margem, ver idle/run com squash & stretch e o ataque automático a cada 0.8s.
```
✅ **Checkpoint:** movimento e ataque funcionando.

### B2 · Inimigos e ondas (T030–T037)
```
Execute a Fase 3 (T030 a T037). Atenção ao plan §4.8: inimigos sem CharacterBody2D, um único _physics_process no EnemyManager, separação e busca via SpatialHash, tudo pooled. Crie data/enemies/imp.tres e data/waves/chapter_1/wave_01.tres.
```
✅ **Checkpoint M1:** matar Diabretes numa onda de 60s.

### B3 · Letras, Atril e Lexicon (T040–T051)
```
Execute a Fase 4 (T040 a T051). Ordem: lexicon.gd (com a validação de 3 a 8 letras que falha no load) → testes → atril.gd → testes → letter_dropper.gd com o drop ponderado do FR-013 → teste estatístico com seed → letter.tscn pooled → magnet → LUX → input de cast.
Escreva os testes antes da implementação de cada um desses três (Lexicon, Atril, LetterDropper).
```
✅ **Checkpoint M2:** coletar L, U, X e conjurar LUX.

### B4 · Palavras base, heresia e purge (T060–T069)
```
Execute a Fase 5 (T060 a T069): as 6 palavras restantes (PAX, CRUX, VITA, AQUA, IGNIS, MORTIS) como cenas de milagre + .tres, heresia (stun 0.5s, poça de aggro 2s, atril limpo) e purge no Shift.
Ao fim, peça ao rules-agent para validar os números das 7 palavras e me mostre o parecer.
```
✅ **Checkpoint M3.**

### B5 · HUD e degradação (T070–T078)
```
Execute a Fase 6 (T070 a T078) usando os assets de HUD já desenhados em assets/sprites/ui. O atril precisa de todos os estados do art bible §8.3 (fill, partial_match, valid, cast_consume, purge, heresy, full_reject).
```
✅ **Checkpoint M4:** uma onda completa jogável.

### B6 · Performance (T080–T086)
```
Execute a Fase 7 (T080 a T086): cena de stress com 300 inimigos + 150 letras + 200 projéteis, medição no build web (Chrome e Firefox), prewarm dos pools e zero instantiate durante a onda.
Se ficar abaixo de 60 FPS, faça a T082 (MultiMesh) e me mostre o antes e depois.
Ao fim, atualize FEATURES.md: 001 → Complete.
```
✅ **Checkpoint M5:** SC-001 e SC-002 aprovados.

---

## FASE C — Sistemas (features 002 a 005, podem ir em paralelo)

### C1 · Vocabulário e combos (002)
```
Implemente specs/002-vocabulary-combos/ seguindo tasks.md, na ordem das 3 fases. Atenção: o combo substitui o efeito da 2ª palavra (FR-202), VERBUM não repete VERBUM e GLORIA/PURGO não entram em combos.
PURGO precisa matar em lotes escalonados para não derrubar o FPS (SC-202).
```

### C2 · Loja (003)
```
Implemente specs/003-shop-scriptorium/ seguindo tasks.md. O RunStats com modifiers (FR-306) é a peça central: Player, Atril e AutoAttack passam a ler dele, nunca do Resource base.
Faça os testes de economia (preços escalados, únicos, travas) antes da UI.
```

### C3 · Arena e degradação (004)
```
Implemente specs/004-arena-degradation/ seguindo tasks.md. Use o SubViewport acumulativo para os decals (custo fixo) e os 2 shaders do plan. Meça o custo no web (SC-401) e me mostre.
```

### C4 · Inimigos e ondas do Cap. 1 (005)
```
Implemente specs/005-enemies-roster/ seguindo tasks.md: refatore behaviors para Resources stateless, adicione os 4 inimigos restantes, campeões e as 9 ondas do Cap. 1.
Ao fim, peça ao rules-agent para revisar a curva de dificuldade das ondas.
```
✅ **Checkpoint:** capítulo 1 jogável até a onda 9.

---

## FASE D — Chefes e apresentação

### D1 · Framework de chefes + Asmodeus (006)
```
Implemente specs/006-boss-asmodeus/. A Fase 1 é o framework que os chefes 012 a 015 vão reutilizar: BossData/PhaseData/AttackData, FSM do chefe, escolha ponderada com anti-repetição, DamageFilter por source_tag e LetterSafety.
Só depois faça os 4 ataques do Asmodeus e as 3 fases.
```
✅ **Checkpoint:** primeira luta de chefe completa.

### D2 · Telas e menus (007)
```
Implemente specs/007-ui-screens-menus/ seguindo tasks.md: ScreenRouter, tema gerado dos tokens, Settings, localização PT-BR/EN, os 8 componentes e as 13 telas.
Requisito não negociável: tudo navegável só por teclado (SC-702). Teste isso ao fim e me mostre o resultado.
```

### D3 · Cutscenes in-engine (008)
```
Implemente specs/008-cutscenes-cap1/ (versão in-engine). Ordem: CutsceneStage + câmera + camadas com parallax + fade por dithering (o shader já está em specs/008-cutscenes-cap1/assets/) → DialogBox → skip → CutsceneDirector → o builder JSON→Animation → as cutscenes.
Converta specs/008-cutscenes-cap1/roteiros/c1-01-o-codice.md em data/cutscenes/c1_01_intro.json e monte a cena com as camadas de assets/cutscenes/c1_01/.
Nada de vídeo: toda a animação é AnimationPlayer (Princípio IX).
```

### D4 · Áudio (009)
```
Implemente specs/009-audio/ seguindo tasks.md: buses, AudioManager com pools e limite de vozes, MusicDirector com camadas sincronizadas, AudioEventMap ligado aos eventos de animação e o gate de áudio do web.
Se ainda não houver os arquivos de áudio, crie os .tres apontando para placeholders silenciosos e me liste o que falta gravar.
```

### D5 · Personagens e desbloqueios (010)
```
Implemente specs/010-characters-unlocks/: CharacterData, PassiveHook, os 5 personagens, UnlockTracker e o DemoGate.
Teste as passivas especiais (Tomé sem stun, Iluminador com letra dupla, Beda com atril 5).
```

---

## FASE E — Demo publicada

### E1 · Export e página do itch (011)
```
Implemente specs/011-web-export-itch/: 4 presets com feature tags, shell HTML com loading em vela, otimização de tamanho (meta: até 25MB), save no web, CI com butler em tags e o checklist de QA em qa/release_checklist.md.
Me mostre o tamanho final do build web e o tempo de carregamento medido.
```
✅ **Checkpoint:** demo do Capítulo 1 publicada (v0.1.0).

---

## FASE F — Capítulos 2 a 5

### F1 a F4 · Um prompt por capítulo (012, 013, 014, 015)
```
Implemente specs/0XX-<feature>/ seguindo tasks.md, reutilizando o framework de chefes da 006 e o sistema de cutscenes da 008.
Antes de começar, me diga o que precisa ser estendido no framework (novas capacidades) e o que é só dado novo.
Ao fim, peça ao rules-agent para validar as mecânicas novas do chefe.
```
Ordem: 012 Mãe das Traças → 013 Abade Caído → 014 Padre Malaquias → 015 Semíhaza.
✅ **Checkpoint final:** campanha completa jogável.

---

## Prompts utilitários (use quando precisar)

### U1 · Adicionar conteúdo novo
```
Quero adicionar <palavra/inimigo/item/onda> ao jogo. Siga o Princípio IV: isso deve ser só um .tres novo, sem mudar código. Se exigir código, me explique por quê antes.
Passe pelo rules-agent antes de gravar os números.
```

### U2 · Bug
```
Bug: <descrição>. Passos: <como reproduzir>.
Antes de corrigir: diga qual requisito da spec está sendo violado e escreva um teste GUT que falha por causa desse bug. Depois corrija e mostre o teste passando.
```

### U3 · Revisão de fase
```
Revise o que foi implementado até aqui contra specs/<feature>/spec.md e a constituição.
Liste: requisitos cumpridos, requisitos faltando, violações da constituição e dívidas técnicas. Não corrija nada ainda, só o relatório.
```

### U4 · Performance
```
O FPS caiu em <situação>. Faça profiling no build web, me mostre os 5 maiores custos e proponha correções ordenadas por custo-benefício. Não implemente antes do meu ok.
```

### U5 · Importar assets novos do Claude Design
```
Adicionei arquivos em assets/sprites/<pasta>. Importe com filtro Nearest e sem mipmaps, crie os SpriteFrames com os frames e tempos da art bible, e ligue nos .tres correspondentes.
Peça ao design-agent para conferir tamanhos e paleta, e me liste o que estiver fora do padrão.
```

### U6 · Cutscene nova
```
Monte a cutscene <id> a partir de specs/008-cutscenes-cap1/roteiros/<arquivo>.md: gere o JSON, monte a cena com as camadas de assets/cutscenes/<id>/ e rode o builder.
Confira cada t= do roteiro contra a Animation gerada (tolerância de 1 frame) e me mostre as divergências.
```

### U7 · Balanceamento depois de playtest
```
Resultado do playtest: <dados>.
Proponha ajustes só em arquivos .tres (drop_tuning, stats das palavras, ondas, preços). Mostre cada mudança como antes → depois, com a justificativa, e peça o parecer do rules-agent antes de aplicar.
```
