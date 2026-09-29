# 008 — Cutscenes do Capítulo 1

> Status: **Aprovada** (2026-09-29, "1A 2A 3A — pressionar por 3 segundos"; D-071).
> Parecer (2026-09-29): game-design-agent **AJUSTAR** — tetos de tempo por cena, C1-02 mais curta e quatro correções de canon (aplicados abaixo). mechanics-agent: sistema proposto (seção "Arquitetura").
> Depende de: 006 (entrada e morte do Asmodeus), 007 (telas, roteador, tradução, Vitória). Constituição IX (cutscenes in-engine, AnimationPlayer + builder JSON→Animation, nada de vídeo). Narrativa §5, §10 (falas âncora), §12 (beats C1-01…C1-04). Plano de etapas DV-10 (os roteiros nascem nesta spec) e R-04 (builder com tolerância de 1 quadro). Asset catalog §2 (closes 128×128).
> **[P]** = proposta do Claude (fala ou regra inventada, o autor aprova ou reescreve). **[P?]** = decisão do autor.

## Objetivo

Contar o Capítulo 1 dentro do motor: quatro cenas curtas (C1-01 a C1-04) que abrem a história, ensinam a regra do livro, apresentam Asmodeus e fecham a página — **curtas, puláveis e sem vídeo**. Cada cena é um **roteiro em JSON** que um builder transforma em `Animation` para um `AnimationPlayer`; o texto vem da tradução (PT-BR e EN).

## Fora do escopo

| Item | Feature |
|---|---|
| Cutscenes dos capítulos 2–5 (C2-01 … C5-02) | 012–015 (usam o mesmo builder) |
| Gravar as vozes (o autor gera no ElevenLabs a partir de `docs/voice/`) e o áudio definitivo de música e efeitos | autor / 009 Fase 3 (aqui: o jogo já toca a voz se o arquivo existir; efeitos provisórios) |
| Arte definitiva (closes, cenário do scriptorium) | quando os PNGs chegarem (aqui, placeholders por script, D-024) |
| Tutorial interativo (dicas na tela durante a onda 1) | fora do roadmap atual (a C1-02 só **conta** a regra) |
| "Rever cutscenes" num menu | **[P?]** fora (ver pergunta 1) |

## Histórias de usuário

- **US-1 (P1):** como jogador, ao começar o Cap. 1 vejo por que Anselmo entra no livro (C1-01) e o que o fantasma do Abade espera dele (C1-02).
- **US-2 (P1):** como jogador, quando Asmodeus chega entendo que ele apaga até as letras do atril (C1-03), antes da luta.
- **US-3 (P1):** como jogador, ao vencer vejo a página purificada e a ameaça da próxima (C1-04), antes da tela de Vitória.
- **US-4 (P1):** como jogador, posso adiantar as falas e **pular** qualquer cena.
- **US-5 (P2):** como jogador que troca o idioma, vejo as falas em PT-BR ou EN.

## Roteiros (beats da narrativa §12)

Tetos assistindo sem adiantar **[P]** (pilar "curto e intenso"; números finais com o animation-agent): **C1-01 + C1-02 somadas ≤ 40 s** (rodam seguidas antes da onda 1), **C1-03 ≤ 12 s** (roda a cada tentativa contra o chefe), **C1-04 ≤ 15 s**. Falas sem marca são canônicas (narrativa §5.1 e §10). Anselmo segue assustado em todas: o herói é pequeno (§5.1).

**C1-01 · O mosteiro arde** (entre o Capítulo e a partida)
1. Subsolo do mosteiro, à noite; pela grade lá em cima, o fogo — que não é fogo comum: as paredes perdem o desenho, como texto sendo apagado (§4.3); a arca de ferro com o medalhão da pena sobre a cruz (§3.2).
2. Legenda: "MOSTEIRO DE SÃO WENDELINO. 1348, O ANO DA PESTE." **[P]** (ano canônico, §3.1)
3. Anselmo (assustado): "O códice… o Abade disse para nunca abri-lo."
4. A arca range; letras escapam pela fresta; Anselmo (ainda assustado): "…Mas o Abade não está aqui." **[P]**
5. Ele abre a arca e o livro; luz branca; a página vira e o engole.
6. Narrador: "Dentro do livro, só a Palavra pode salvá-lo."

**C1-02 · A regra do livro** (em seguida, já na página do Cap. 1, antes da onda 1) — 3 falas
1. A página em branco; Anselmo cai nela; o fantasma do Abade se forma com tinta clara.
2. Abade: "Irmão Anselmo… Você abriu. Claro que abriu." **[P]** (ele queria isso e não conta, §4.4)
3. Abade: "A Palavra sustenta a página. Onde ela some, há o vazio." (lei canônica, §3.3)
4. Anselmo: "…E se eu errar?" — Abade: "Então o vazio fala pela sua boca. E fere você." **[P]** (a heresia fere quem a diz, §3.3 e §9)
5. O fantasma se desfaz; a onda 1 começa.

**C1-03 · O Rasurador** (entrada do chefe, no lugar da animação de entrada da 006 FR-607)
1. A página escurece; riscos de rasura cruzam o papel.
2. Asmodeus sobe do centro-topo: "Tuas palavras… eu as APAGO."
3. Um risco atravessa o atril e apaga uma letra (a Rasura, 006 FR-609, **só na cena**: o atril real não perde nada).
4. Anselmo: "…Catorze anos copiando. E ele apaga assim." **[P]** (humor seco; alternativa mais didática: "Ele apaga até o que eu já juntei.")
5. A barra do chefe aparece; a luta começa.

**C1-04 · A página limpa** (depois da morte do chefe, antes da Vitória da 007)
1. Asmodeus se desfaz em traços de tinta; a página clareia (raios GOLD_LIGHT).
2. Abade (fantasma): "Uma página limpa. Há muitas outras." **[P]**
3. O canto da página se levanta; algo rói a borda (silhueta de traça, teaser do Cap. 2).
4. Anselmo: "…Traças. Eu detesto traças."
5. Corte para a tela de Vitória.

## Requisitos funcionais

### Roteiro e builder
- **FR-801** Cada cena é um arquivo `data/cutscenes/<id>.json`: `id`, `version`, `duration`, `play` (`once`/`always`, a regra da FR-810 vive no dado), `actors` (camada, tipo, recurso, valores iniciais) e `events` com `t` (segundos): **chaves de propriedade** (alvo, propriedade de uma lista fechada, valor, easing `linear/in/out/in_out/step`; cor só por nome da paleta), **falas** (falante, expressão, chave de tradução, `end`), **legendas**, **sons** (id do AudioManager) e **marcas** (lista fechada, para sincronizar o meio da cena). Falantes (nome e closes) em `data/cutscenes/speakers.json`. O load valida tudo (alvo existe, chave de tradução nos dois idiomas, falas sem sobreposição, nada fora da duração, duas chaves no mesmo quadro = erro).
- **FR-802** `CutsceneBuilder` transforma o JSON numa `Animation` (`step` 1/60): trilhas de valor por alvo+propriedade e **uma trilha de método** com os "cues" (falas, legendas, sons, marcas). Todo `t` cai no quadro certo, com tolerância de 1 quadro a 60 FPS (R-04). **[P]** O som sai por cue chamando o `AudioManager` (não por trilha de áudio), para valerem os volumes das Opções e os sons provisórios da 009.
- **FR-802b** **Timeline fixa** **[P]**: sem ninguém apertar nada, a cena dura exatamente `duration`. Adiantar nunca pausa a cena: completa o texto ou pula para o fim da fala. Cues pulados: as marcas disparam em ordem; sons e falas do trecho pulado são descartados.
- **FR-803** Nada de conteúdo no código: falas, tempos, posições e atores vêm do JSON e da tradução.

### Palco
- **FR-804** `CutscenePlayer` (cena própria) com camadas: fundo, atores, efeitos e a faixa de diálogo (close do falante + nome + texto que aparece letra a letra). Tudo em 640×360, com a paleta travada; placeholders por script onde não houver arte (closes 128×128 de Anselmo e do Abade, cenário do scriptorium, fantasma, Asmodeus já existe).
- **FR-805** Controles: **Espaço/Enter ou clique** completa o texto da fala e, completo, adianta para a próxima (o clique segue a D-067); **segurar Esc por 3 s** pula a cena inteira **[D-071]**: enquanto segura, aparece uma animação de carregamento **subindo** (enche de baixo para cima; o visual é do design-agent e o tempo do animation-agent); ao completar, a cena pula. Soltar antes zera. Toque rápido no Esc não faz nada (não há pausa dentro da cena).
- **FR-806** Pular leva ao **mesmo estado** que assistir até o fim: as trilhas vão ao valor final, as marcas pendentes disparam em ordem e `cutscene_finished` sai **sempre por último** (também se o JSON estiver quebrado: o jogo nunca trava numa cena).
- **FR-806b** Durante a cena, a entrada é da cena (o Esc não abre a Pausa por baixo). O som das cenas toca com a árvore do jogo parada (o AudioManager ganha vozes que não pausam) e o hit-stop não desacelera a cena.

### Onde as cenas entram
- **FR-807** C1-01 e C1-02: entre a tela de Capítulo e a partida (o roteador ganha a rota `cutscene`). Na partida, a onda 1 só começa quando a C1-02 termina.
- **FR-808** C1-03: substitui a animação de entrada do chefe (006 FR-607): a árvore do jogo fica parada, a cena roda por cima e **o fim da cena** solta o Asmodeus já pronto para lutar (a barra aparece nessa hora). Testes, sonda de balanceamento e `?boss` seguem pela entrada normal.
- **FR-809** C1-04: depois da morte do chefe (006 FR-611), antes da Vitória (007 FR-706).
- **FR-810** **[P?]** C1-01 e C1-02 só na **primeira vez**; depois, a partida começa direto. C1-03 e C1-04 **sempre** (curtas; marcam a luta). "Já vista" fica no save do Grimório (`user://codex.save`, seção própria, sem virar entrada nem "novidade" na Vitória), gravada quando a cena **termina ou é pulada**.
- **FR-810b** Quais cenas cada capítulo usa fica no `ChapterData` (intro, chefe, fim), não no código; velocidade do texto e tempo de segurar o Esc (3 s, D-071) em `data/tuning/cutscene.tres` (números com o animation-agent).
- **FR-811** Atalhos de debug: `?cutscene=c1_01` (… `c1_04`) abre a cena sozinha; `?boss`, `?shop`, `?unlock=all` continuam pulando tudo.

### Texto e som
- **FR-812** Toda fala e legenda em `i18n/ui.csv` (PT-BR e EN); troca de idioma vale na cena seguinte. O latim não aparece nas falas.
- **FR-813** Sons por evento do `AudioManager` (fogo, corrente, virada de página, rasura, sino); com o áudio provisório da 009 enquanto os arquivos não chegam.
- **FR-814** **Vozes [D-071]:** cada fala pode ter voz, uma por idioma, em `assets/audio/voice/<pt_BR|en>/<id>.mp3` (id = chave da fala em minúsculas). O jogo toca a do idioma atual; sem arquivo, a fala só aparece escrita. Todas as falas do jogo, em PT-BR e EN, com direção de voz por personagem: `docs/voice/VOICE-LINES.md` e `docs/voice/voice_lines.csv`. Quando as vozes chegarem, o `end` de cada fala se ajusta à duração do áudio (animation-agent), respeitando os tetos das cenas.

## Arquitetura (mechanics-agent, resumo)

- `CutsceneBuilder` (JSON → `Animation` + lista de cues) · `CutscenePlayer` (CanvasLayer 30, acima dos overlays e abaixo do fade; `Stage` com fundo/atores/efeitos criados no load; faixa de diálogo; legenda; anel do Esc; `AnimationPlayer`; FSM `Idle → Ready → Playing → Skipping → Finishing`; a faixa de diálogo `Hidden → Typing → Complete`).
- EventBus: `cutscene_started(id)`, `cutscene_mark_reached(id, mark)`, `cutscene_skipped(id)`, `cutscene_finished(id, skipped)` — o fluxo do jogo escuta só o último.
- Rota `cutscene` no roteador (fila de cenas → depois `game`); `?cutscene=c1_0N` toca e volta ao Menu. O Main carrega C1-03 e C1-04 ao abrir (nada é criado durante a onda) e troca a entrada do chefe e a Vitória pelo fim das cenas.

## Critérios de sucesso

- **SC-801** Builder: para cada roteiro, cada `t` vira uma chave no quadro certo (±1 quadro a 60 FPS) — teste estático (JSON × `Animation`) e de execução (avançando quadro a quadro, cada cue dispara no quadro certo). O load recusa roteiros inválidos.
- **SC-802** Pular (segurar Esc) chega ao mesmo estado que assistir: a partida começa na onda 1; a luta começa com o chefe ativo; a Vitória aparece (teste).
- **SC-803** Toda fala e legenda existe em PT-BR e EN; nenhuma fala escrita no código (teste da 007 estendido).
- **SC-804** Nenhum arquivo de vídeo no projeto (teste varre `.ogv`, `.webm`, `.mp4`).
- **SC-805** Do Capítulo à onda 1 só com teclado, passando pelas cenas (teste do fluxo da 007 estendido).
- **SC-806** O SC-001 se mantém (as cenas não rodam durante a onda); a cena roda a 60 FPS no Chrome.

## Decisões do autor (D-071)

1. **1A:** C1-01 e C1-02 só na primeira vez; C1-03 e C1-04 sempre.
2. **2A:** falas propostas aprovadas (trocáveis no `i18n/ui.csv` e em `docs/voice/`).
3. **3A, com ajuste:** segurar Esc por **3 s**, com animação de carregamento subindo; ao completar, pula.
4. **Vozes:** o autor gera as falas no ElevenLabs a partir de `docs/voice/` (PT-BR e EN); o jogo toca quando os arquivos existirem (FR-814).
