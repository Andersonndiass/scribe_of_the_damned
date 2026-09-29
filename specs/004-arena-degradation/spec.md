# 004 — Arena e degradação da página (Cap. 1)

> Status: **Aprovada** (2026-09-29, "1a 2a 3b"; D-078) — obstáculos entram já no Cap. 1 (números com o rules-agent, colisão com o mechanics-agent).
> Parecer (2026-09-29): game-design-agent **AJUSTAR** — tema da rasura no lugar das traças, sem BLOOD na degradação, legibilidade em toda a área jogável, dado da onda definido (aplicados abaixo).
> Depende de: 001 (arena protótipo, decals em SubViewport, FR-026), 005 (as 9 ondas do Cap. 1), 006 (o chefe), 008 (cutscenes). Game bible §2 (loop: "onda termina → página degrada → loja") e §3.10. Art bible §7.1 (arena em camadas), §7.2 (4 estágios **acumulados** por capítulo), §7.4 (margem 24 px, obstáculos com sombra e borda clara), §6.3 (ambientais DUST, EMBER, PAGE_TEAR, MOTH_EDGE). Narrativa §6 ("a degradação é a contagem regressiva do texto: quando o papel queima nas bordas, é a realidade acabando"). Regras de pixel art D-075/D-076 e camadas (feedback do autor).
> **[P]** = proposta do Claude. **[P?]** = decisão do autor.

## Objetivo

Fazer a página do Cap. 1 **contar a história do capítulo**: começa limpa e, onda a onda, vai se gastando até estar em chamas nas bordas quando o Asmodeus chega. A arena passa a ser montada em **camadas separadas** (fundo, texto-fantasma, ornamentos, obstáculos, degradação, decals), cada uma um sprite/nó próprio, e todo o desenho segue as regras de pixel art (sem pixel solto, sem xadrez em área pequena, círculos fechados).

## O que existe hoje (protótipo da 001) e muda

| Hoje | Na 004 |
|---|---|
| Estágio avança por onda e **volta ao 0** (0-1-2-3-0-1-2-3-0); o `arena.gd` ignora o `WaveData.degradation_stage` | Estágios **acumulados** no capítulo (art bible §7.2), lidos do dado da onda; as 9 `wave_0N.tres` reescritas; o teste do loop em `test_hud.gd` é substituído |
| Desgaste = 90–270 pixels soltos, círculos com `draw_circle`, cantos BLOOD (fora da regra do art bible §2) | Formas em blocos por estágio (manchas, rasuras, queimado) — regras D-075/D-076; sem BLOOD |
| Tudo desenhado num `_draw` | Camadas separadas (fundo, texto-fantasma, ornamentos, obstáculos, degradação, decals) |
| Sem texto-fantasma nem ornamentos | Texto-fantasma e ornamentos de iluminura na página |

## Fora do escopo

| Item | Feature |
|---|---|
| Arenas dos caps. 2–5, cratera do Cap. 5, virada de página entre capítulos | 012–015 |
| A Mãe das Traças encolhendo a arena; traças e página roída (tema do Cap. 2) | 012 |
| Arte definitiva (o autor pode importar cada camada com `tools/import_art.gd`) | autor |

## Histórias de usuário

- **US-1 (P1):** como jogador, vejo a página se gastar ao fim de cada onda e sinto o capítulo avançando para o fim (não um ciclo).
- **US-2 (P1):** como jogador, leio a arena com clareza em qualquer estágio: o desgaste fica nas bordas e nunca esconde inimigo, letra ou telegrafia.
- **US-3 (P2):** como jogador, vejo pequenas vidas na página (poeira, riscos de pena, brasas na borda queimada) que reforçam o estágio.
- **US-4 (P1) [D-078]:** como jogador, contorno os obstáculos da página (furos, banco, vitral, altar) e uso-os para escapar; os inimigos também precisam contorná-los.

## Requisitos funcionais

### Estágios
- **FR-401** 4 estágios **acumulados** no capítulo; `WaveData.degradation_stage` é o estágio **visível durante** aquela onda (dado, não código). Proposta **[P]** para as 9 ondas: 0, 0, 1, 1, 2, 2, 3, 3, 3; o chefe luta no estágio 3.
- **FR-402** O estágio da onda N é aplicado **na transição do fim da onda N-1, antes da loja** (game bible §2), com uma transição curta (tempos do animation-agent); nunca no meio do combate. Na entrada direta (`?boss`, sonda com `wave=N`, testes) ele é aplicado na hora, sem transição.
- **FR-403** O que cada estágio acrescenta **[P]** — tema do Cap. 1: **a rasura** (narrativa §6). As formas grandes (rasgos, queimado) ficam na **moldura de 24 px**; dentro da área jogável, só tons baixos (PARCHMENT_OLD / INK_SOFT) em pouca área:
  - 0 — página limpa (texto-fantasma e ornamentos inteiros);
  - 1 — manchas de tinta e riscos de pena nas margens; o texto-fantasma começa a falhar;
  - 2 — rasuras e rasgos na moldura; ornamentos riscados; poeira (ambiente);
  - 3 — bordas queimadas com brasas (ambiente EMBER, cor do design-agent, **sem BLOOD**); cantos chamuscados; o texto-fantasma quase some.
- **FR-404** **[P?]** Durante a onda, o estágio seguinte "ameaça" nos últimos 10 s do cronômetro (brasas ou fumaça sutil), ligando a degradação ao tempo (narrativa §6). Limites: só na moldura de 24 px; poucos elementos e movimento lento; sem pulso nem piscar no ritmo da telegrafia; tempos do animation-agent.

### Camadas (art bible §7.1)
- **FR-405** A arena é uma pilha de camadas, cada uma um nó próprio: **fundo** (pergaminho), **texto-fantasma** (linhas de texto quase invisíveis — art bible §3: no máximo "alpha 0.12" feito com xadrez em área grande, nunca ruído embaixo das letras do chão), **ornamentos** (iluminuras nos cantos e capitular), **degradação** (uma camada por estágio, empilhadas), **decals** (o SubViewport acumulativo da 001, mantido).
- **FR-406** Cada camada estática é desenhada **uma vez** (textura em cache): custo por quadro fixo e baixo (SC-001). Os ambientes animados são poucos nós pequenos.
- **FR-407** Arte do autor por camada: se existir `assets/arena/chapter_1/<camada>.png` (640×360, fundo transparente), ela substitui o placeholder daquela camada.

### Obstáculos (D-078, autor "3b")
- **FR-408** Obstáculos do Cap. 1, com tipos e tamanhos do catálogo (furo 16×16, banco 32×8, vitral 20×40, altar 60×16), **em dados** (`data/arena/chapter_1.tres`: tipo, posição); quantos e onde vêm do **rules-agent** (mexem na dificuldade já calibrada).
- **FR-410** Colisão de movimento para o escriba e para os inimigos que andam; o que cada tipo bloqueia (voadores, projéteis, telegrafias, ataques do chefe) é definido pelo rules-agent e implementado como o mechanics-agent propuser (inimigos comuns não usam física: constituição).
- **FR-411** Nenhum inimigo nasce, nenhuma letra cai e nenhuma tinta dourada fica dentro de um obstáculo; toda a área livre continua alcançável (sem bolsões fechados).
- **FR-412** Todo obstáculo tem sombra e borda clara (art bible §7.4), em camada própria; legível em todos os estágios de degradação.
- **FR-413** A luta com o chefe acontece na mesma página, com os obstáculos que o rules-agent aprovar para ela (o Asmodeus e seus ataques foram calibrados sem obstáculos).

### Legibilidade
- **FR-409** Nenhum elemento da degradação usa BLOOD (art bible §2: BLOOD é só dano, telegrafia, inimigos e UI crítica) — nem nas brasas; os cantos BLOOD do protótipo saem. O contraste entre letras/telegrafias e o fundo fica preservado em todos os estágios, **em toda a área jogável X24–615 Y24–335** (onde os inimigos surgem e as letras caem), não só no centro.

## Critérios de sucesso

- **SC-401** O estágio segue o dado da onda e **nunca volta** dentro do capítulo (teste com as 9 ondas).
- **SC-402** A troca de estágio só acontece no fim da onda (teste).
- **SC-403** Dentro da área jogável X24–615 Y24–335, as camadas de degradação só usam tons baixos (PARCHMENT_OLD/INK_SOFT) e em pouca área; nada dentro da área central X160–480 Y60–300 (teste por pixels). Nenhum pixel BLOOD na degradação.
- **SC-404** Todas as texturas geradas usam só as 9 cores exatas (o teste byte a byte da D-076).
- **SC-405** O SC-001 se mantém no estágio 3 (stress com a arena no estágio máximo e os obstáculos).
- **SC-406** Nada nasce nem cai dentro de obstáculo; a área livre é conexa (teste).
- **SC-407** A sonda de balanceamento das 9 ondas e do chefe continua dentro das faixas aprovadas (005/006) com os obstáculos (relatório do rules-agent).

## Decisões do autor (D-078)

1. **1a:** estágios acumulados 0, 0, 1, 1, 2, 2, 3, 3, 3; o chefe no 3.
2. **2a:** ameaça sutil nos últimos 10 s, só na moldura.
3. **3b:** obstáculos já no Cap. 1 (FR-408–FR-413).
