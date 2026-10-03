# 012 — Capítulo 2: A Mãe das Traças

> Status: **Aprovada pelo autor** (2026-10-03, "1a2a3a4a5a6a" → D-107; as perguntas abaixo ficam respondidas pela opção a). Decisões do autor: **D-102** ("1a2a3a4a5a6a") — vinculantes.
> Pareceres: game-design-agent **AJUSTAR** (perguntas no fim). Faltam: rules-agent (números), mechanics-agent (Eat_Page, arena que encolhe, filtro), design-agent (fichas 12 e 17, arena), animation-agent (virada de página, mordida), story-agent (C2-01, verbetes).
> Depende de: 004, 005, 006 (framework de chefes), 008 (cutscenes), 010, 016–019 (Complete). Game bible §3.8, §3.10, §3.12; asset catalog §5 (Mãe das Traças), fichas 12 (`ENM_TRACA_MAE`) e 17 (`BSS_MAE_TRACAS`); narrativa §5.3, §6 ("A página roída: o tempo") e §12 (C2-01); D-084, D-085, D-098, D-100.
> Legenda: **[RULES]** = número que o rules-agent define (sempre em `.tres`; nada aqui é valor final). **[P?]** = decisão do autor.

## Objetivo

O segundo capítulo do roguelite: **a página roída**. 9 ondas numa biblioteca comida por traças, com um inimigo novo (a Traça-Mãe pequena), e depois a **Mãe das Traças**: fome sem malícia. **As armas não ferem a Mãe, só as palavras** (D-102). As armas matam as crias, que soltam muitas letras, e a luta vira uma corrida de escrita. Ela morde a página (Eat_Page), e uma palavra no tempo certo cancela a mordida. O capítulo reusa todo o framework da 006 e o pipeline do Cap. 1: **conteúdo novo = arquivos de dados novos**. Código novo só para o que o Cap. 1 não tem: arena que encolhe e imunidade a armas.

## Fora do escopo

| Item | Onde |
|---|---|
| Cap. 3 (O Abade Caído) e seguintes | 013–015 |
| Música do Cap. 2 (o autor manda pronta; a arquitetura da 009 já recebe) | 009 Fase 3 / autor |
| Arte final (67 quadros da ficha 17, ficha 12, camadas da arena); aqui fica placeholder por script | arte / pixel-art-gen |
| Vozes das falas novas (`tools/gen_*_voices.py`) | autor |
| Inimigos de outros capítulos (Noviço Espectral, Coroinha) | 013/014 |
| Mudanças nas armas, poções, relíquias ou na loja | — (só reuso) |
| Demo publicada (011) | depois dos capítulos (D-102) |

## Reusado do Cap. 1 × novo

| Reusado sem mudança | Novo nesta feature |
|---|---|
| WaveDirector, SpawnGroup, campeões, loja entre ondas, Graça/selos, menu da letra, WordGuard, LetterSafety | `data/chapters/chapter_2.tres`, `data/waves/chapter_2/wave_01..09.tres` |
| Os 5 inimigos do Cap. 1 (`data/enemies/*.tres`) | `data/enemies/moth_mother.tres` (Traça-Mãe pequena) + comportamento "estoura ao morrer" |
| Framework de chefe: BossData/PhaseData/AttackData, FSM, sorteio sem repetição, DamageFilter e tetos | `data/bosses/mae_tracas.tres` + `_phase_1..3.tres` + ataques Wing_Gust, Swarm_Release, Dust_Cloud, Eat_Page |
| PageDegradation (4 estágios), ObstacleMap/ObstacleQuery | `data/arena/chapter_2.tres` "biblioteca roída" (obstáculos atuais + mais furos) e `assets/arena/chapter_2/` |
| Pipeline de cutscene JSON → AnimationPlayer, falante `"@player"` | `data/cutscenes/c2_01.json`; abertura com virada de página (`ENV_PAGE_TURN`) |
| Zonas letais (D-084), que nunca tocam o chefe | regra `weapons_immune` do chefe no DamageFilter |

## Histórias de usuário

- **US-1 (P1):** como jogador, abro o Cap. 2, vejo a página virar e luto 9 ondas numa biblioteca roída que se degrada como no Cap. 1.
- **US-2 (P1):** como jogador, reconheço a Traça-Mãe pequena pela bolsa de ovos e sei que matá-la solta traças; escolho onde e quando matá-la.
- **US-3 (P1):** como jogador, entendo logo que **as armas não ferem a Mãe**: uso as armas nas crias para colher letras e escrevo para ferir a Mãe.
- **US-4 (P1):** como jogador, vejo o aviso da mordida e posso **cancelá-la com uma palavra**; se falho, a página encolhe de vez e a arena aperta.
- **US-5 (P1):** como jogador, a luta dura 3–4 min e escrevo uma palavra a cada 20–30 s; é o pico de escrita do capítulo.
- **US-6 (P2):** com qualquer um dos 5 escribas, vejo a C2-01 com as minhas falas na entrada do chefe.
- **US-7 (P1):** vencer a Mãe conclui o capítulo.

## Requisitos funcionais

### Capítulo e ondas
- **FR-1201** `chapter_2.tres` (ChapterData): 9 ondas, chefe `mae_tracas`, `boss_cutscene = &"c2_01"`, a arena do Cap. 2 e o estágio do chefe **[RULES]**. **D-102: 9 ondas**; a game bible §3.8 ("caps. 2–5 têm 10") recebe emenda.
- **FR-1202** Ondas 1–9 em `data/waves/chapter_2/`. A curva parte **acima** da onda 1 do Cap. 1 e chega acima da onda 9 dele **[RULES]**: duração, ritmo de spawn, `max_alive`, `letter_drop_mul`, campeões, `degradation_stage`. A Traça-Mãe pequena entra sozinha numa onda de apresentação **[RULES: qual]** e depois se mistura ao elenco.
- **FR-1203** Ritmo de palavras nas ondas igual ao do jogo (D-098: ~1 a cada 2 min); nada de ritmo de chefe nas ondas.
- **FR-1204** Como o Cap. 2 abre e o que o escriba leva: **[P?]** pergunta 1.

### Abertura e cutscene
- **FR-1205** O capítulo abre com a **virada de página** (`ENV_PAGE_TURN`, art bible §7.3) da página limpa para a roída; tempo do animation-agent.
- **FR-1206** **C2-01 na entrada do chefe** (D-102). Beat: "a página está sendo comida, e não por malícia" (narrativa §12). Usa `"@player"` e variantes por escriba, como a C1-03; nenhuma fala passa de 2 linhas. Debug `?cutscene=c2_01`.

### Traça-Mãe pequena
- **FR-1207** Inimigo comum no EnemyManager (sem CharacterBody2D); a bolsa de ovos é o ponto de leitura (ficha 12). Ao morrer, **estoura em traças comuns** (D-102), tiradas do pool, sem `instantiate()`. Quantas e o teto de vivas: **[RULES]**. Que traça: **[P?]** pergunta 2.
- **FR-1208** Uma zona letal (D-084) que mata a Mãe pequena mata as filhas no mesmo instante; não há segunda onda de crias se a zona continua ativa **[mechanics]**.

### A Mãe das Traças
- **FR-1209** `mae_tracas.tres`: 80×64, 3 fases (66% / 33%, asset catalog §5), HP **[RULES]**, contato fere forte, telegrafia ≥ 600 ms (SC-605 da 006).
  - **F1:** Wing_Gust + Swarm_Release.
  - **F2:** + Dust_Cloud; o idle acelera; o Swarm solta mais crias.
  - **F3:** + Eat_Page; asas esqueléticas.
  - Pesos, intervalos, forma e efeito de cada ataque: **[RULES]** (rajada que empurra, liberação de crias, nuvem de pó). Nenhum ataque fere sem telegrafia.
- **FR-1210** **Imune às armas** (D-102): o DamageFilter (FR-604) zera todo `source_tag` de arma; só as palavras ferem, com os tetos da 006. A arma que bate no chefe mostra um retorno de "imune" (sem número, para não parecer bug; design + animation). Poções e relíquias: **[P?]** pergunta 3.
- **FR-1211** **As crias são a fonte de letras** (D-102): as crias do Swarm morrem pelas armas e soltam letras pelo menu da letra. Meta **~1 palavra a cada 20–30 s**, luta de 3–4 min **[RULES: drop das crias, teto de vivas]**. O LetterSafety segue como rede. Menu da letra no chefe: **[P?]** pergunta 5.
- **FR-1212** **Eat_Page** (D-102 + asset catalog §5):
  - aviso telegrafado na borda que vai ser comida;
  - **uma palavra que acerta a Mãe durante o aviso cancela a mordida**;
  - sem cancelamento, a borda é comida e a área jogável encolhe um passo, até a arena mínima **[RULES; o catálogo propõe 400×220]**;
  - **a página não volta a crescer** no resto da luta;
  - **a borda comida só empurra** escriba e inimigos para dentro (sem dano, sem vela);
  - intervalo **[RULES; o catálogo propõe 15 s]**; em que fases: **[P?]** pergunta 4;
  - obstáculos e decals na faixa comida somem ou são cobertos **[mechanics]**; o escriba nunca fica preso nem fora da área.
- **FR-1213** O DOMINUS no chefe atordoa como na 006. A janela de exposição da 006 (FR-609b) **não** vale aqui: a recompensa por ler o ataque é cancelar a mordida **[rules confirma]**. A palavra guardada (D-100) é imune a tudo da Mãe.
- **FR-1214** Morte pelo fluxo da 006: dissolução, explosão de letras douradas, `boss_defeated`, `chapter_completed(2)`. Derrota = Game Over normal.

### Técnica e ferramentas
- **FR-1215** Tudo em dados (constituição IV); nenhum número no código. Pools pré-aquecidos para o pico do Swarm e dos estouros.
- **FR-1216** Debug: `?chapter=2` (com `?boss`, `?char=`, `?unlock=all`); `?stress=boss2` (Swarm no teto + estouros + arena mínima); sonda `chapter=2` (sem argumento com "boss" no nome, D-086), com linha nova `EATPAGE` (mordidas tentadas, canceladas, área final).
- **FR-1217** Grimório: verbetes "Traça-Mãe pequena" (falta na narrativa §11; story-agent) e "Mãe das Traças" (existe). A vitória mostra o Cap. 3 selado ("em breve"). Áudio dos ataques novos pelo manifesto (audio-agent).

## Critérios de sucesso

- **SC-1201** `chapter_2.tres` carrega 9 ondas + chefe; vencer emite `chapter_completed(2)` (integração).
- **SC-1202** Dano de qualquer arma na Mãe = 0; palavras e combos de ataque passam com os tetos da 006 (unitário por `source_tag`).
- **SC-1203** Palavra que acerta durante o aviso cancela o Eat_Page; sem palavra, a área encolhe um passo; nunca abaixo do mínimo, nunca cresce (unitário).
- **SC-1204** A borda comida empurra sem dano; a sonda registra `STUCK = 0` e nenhum escriba ou inimigo fora da área em 10 lutas.
- **SC-1205** A Traça-Mãe pequena estoura dentro do teto, sem `instantiate()` na onda (teste com pool).
- **SC-1206** Todo ataque da Mãe tem ≥ 600 ms de telegrafia (reusa o teste da 006).
- **SC-1207** Na sonda, bot com ~6 compras vence a Mãe em **3–4 min**, mediana de **20–30 s entre palavras** (D-102).
- **SC-1208** Curva das ondas: a sonda `cast chapter=2 chapter buy grace only_waves` fica nas metas do rules-agent (ritmo, Graça, taxa de derrota acima do Cap. 1).
- **SC-1209** `?stress=boss2` a 60 FPS no Chrome (média ≥ 60 / p95 ≥ 55).
- **SC-1210** A C2-01 toca com cada um dos 5 escribas (`@player`); a virada de página abre o capítulo.
- **SC-1211** Cap. 1 sem regressão: GUT inteiro verde e sonda do Cap. 1 igual à de antes.

## Perguntas ao autor

1. **Como se entra no Cap. 2?** a) Partida nova pela tela de Capítulo, liberada ao vencer o Cap. 1, do zero (arma e poção iniciais do escriba). b) Continuação da mesma partida: vencer a Asmodeus vira a página e o escriba segue com armas, relíquias, nível e tinta. *Recomendado: a.*
2. **Que traças saem da Traça-Mãe pequena e do Swarm?** a) A Traça do Cap. 1 como é (rouba do atril). b) Variante só em dados (`moth_hatchling.tres`), menor, que persegue e não rouba. *Recomendado: a, com teto baixo de vivas.*
3. **Poções e relíquias ferem a Mãe?** a) Não: tudo que não é palavra é imune. b) Só as armas são imunes. *Recomendado: a.*
4. **Em que fase o Eat_Page aparece?** a) Só na F3. b) F2 e F3, mais espaçado na F2. *Recomendado: a.*
5. **O menu da letra pausa durante a luta?** a) Pausa como no resto do jogo (D-098). b) Só no chefe, câmera lenta em vez de pausa. *Recomendado: a, medida no playtest.*
6. **A C2-02 (vitória) entra na 012?** a) Sim, curta, como a C1-04. b) Não, fica para a 013. *Recomendado: a.*
