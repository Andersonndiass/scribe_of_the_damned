# 008 — Tarefas

> Spec: `spec.md` (aprovada, D-071; emenda D-072). Sistema do mechanics-agent (seção "Arquitetura" da spec).

## Fase 1 — Roteiro e builder
- ✅ **T800** [TEST-FIRST] `tests/unit/test_cutscene_builder.gd`: cada `t` do roteiro no quadro certo (±1 a 60 FPS), estático e avançando quadro a quadro (R-04, SC-801); o load recusa roteiro inválido (alvo inexistente, chave de tradução faltando, falas sobrepostas, `t` fora da duração, duas chaves no mesmo quadro); `step` vira NEAREST.
- ✅ **T801** `src/cutscenes/cutscene_builder.gd` (JSON → `Animation` + cues) e o contrato do JSON; `data/cutscenes/speakers.json`; `CutsceneTuning` (`data/tuning/cutscene.tres`: velocidade do texto, segurar Esc 3 s); `ChapterData` ganha intro, chefe e fim.
- ✅ **T802** Testes transversais: toda fala/legenda em PT-BR e EN (SC-803); nenhum arquivo de vídeo no projeto (SC-804).

**Checkpoint 008-A:** ✅ um roteiro de teste vira `Animation` no quadro certo (estático e quadro a quadro); 11 tipos de roteiro inválido recusados (2026-09-29, GUT 358/358).

## Fase 2 — Palco
- ✅ **T810** Visual e tempos: parecer do design-agent (faixa de diálogo, closes 128×128 placeholders de Anselmo e do Abade, subsolo com a arca, fantasma, riscos de rasura, raios, silhueta de traça, **carregamento subindo** do pular) e do animation-agent (tempos das 4 cenas dentro dos tetos, texto letra a letra, corte C1-01 → C1-02).
- ✅ **T811** `src/cutscenes/cutscene_player.tscn/.gd`: camadas, faixa de diálogo (FSM Hidden/Typing/Complete), legenda, FSM do player, Espaço/Enter/clique adianta, **segurar Esc 3 s** pula com a animação subindo, entrada presa na cena, `cutscene_*` no EventBus, fim sempre emitido (fail-open).
- ✅ **T812** `AudioManager`: vozes que tocam com o jogo parado; voz da fala por idioma (`assets/audio/voice/<idioma>/<id>.mp3`, FR-814) e do latim ao conjurar (`assets/audio/voice/latin/`, FR-816); silêncio se não existir.
- ✅ **T813** [TEST] `tests/unit/test_cutscene_player.gd`: adiantar (1º completa, 2º pula a fala), pular em vários pontos = mesmo estado final e `cutscene_finished` por último, toque curto no Esc não faz nada, hit-stop não desacelera.

**Checkpoint 008-B:** ✅ uma cena toca, adianta e pula com o estado certo; faixa, closes, legenda e placa de pular desenhados (2026-09-29, GUT 366/366). D-073.

## Fase 3 — As quatro cenas no jogo
- ✅ **T820** Roteiros `data/cutscenes/c1_01.json` … `c1_04.json` (tempos do animation-agent) e placeholders por script.
- ✅ **T821** Rota `cutscene` no roteador (C1-01 → C1-02 → jogo), "já vista" no Codex (1A), `?cutscene=c1_0N`.
- ✅ **T822** C1-03 no lugar da entrada do chefe (árvore parada; o fim da cena solta o Asmodeus já lutando).
- ✅ **T823** C1-04 entre a morte do chefe e a Vitória.
- ✅ **T825** Frases na partida (FR-815): `data/barks/barks.json` (gatilho, falante, chave, intervalo), balão de fala (visual do design-agent no T810), voz opcional; teste: cada gatilho mostra a frase uma vez e respeita o intervalo.
- ✅ **T824** [TEST] `tests/integration/test_cutscene_flow.gd` (SC-802, SC-805): Capítulo → C1-01 → C1-02 → onda 1 (na 2ª vez, direto); C1-03 pulada → chefe lutando, `boss_spawned` uma vez; C1-04 pulada → Vitória; Esc na cena não abre a Pausa. Estender o `test_screens_flow` da 007.

**Checkpoint 008-C:** ✅ do Capítulo à Vitória com as quatro cenas (teste do fluxo); frases na partida com intervalos e prioridade (2026-09-29, GUT 382/382).

## Fase 4 — Fechamento
- ✅ **T830** GUT, export web, SC-001 e 60 FPS numa cena no Chrome (SC-806), `FEATURES.md`, `CLAUDE.md`, `docs/DECISIONS.md`, push.

**008 Complete** (2026-09-29): GUT 382/382; export web ok; `?cutscene=c1_0N` no Chrome sem erros; SC-001 no Chrome 75–79 FPS (p95 57–62) — os custos subiram ~50% por igual também em sistemas intocados (máquina mais lenta nesta medição), média acima de 60. D-077.
