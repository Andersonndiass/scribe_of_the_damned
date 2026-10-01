# 017 — Arsenal sagrado: armas, menu de escolha da letra e ímã reverso

> Status: **Complete** (2026-10-01, D-093; playtest do autor e Chrome pendentes) · antes: **Aprovada** (2026-09-30, D-087: "1a 2a 3a 4b 5a 6a 7a 8a 9a 10a 11a") — direção aprovada pelo autor na D-085 (respostas "1a 2a… 12a") e C-008 ("1a 2b 3b e mouse clicando 4a"). Game bible: Emenda 1.
> Parecer de direção: `docs/reviews/D085-game-design-arsenal.md` (game-design-agent, AJUSTAR).
> Pareceres: `docs/reviews/T1700-rules-parecer.md` (números: armas por nível, letras 0,04×HP × `letter_drop_mul` por onda, palavras ×1,5 área/×2,5 dano, Graça, selos, ímã, loja) · `T1700-mechanics-parecer.md` (TimeScale, contextos de tecla, WeaponData/Loadout/Arsenal, WeaponZones, LetterMenu, SealPool; 6 fases) · `T1700-design-parecer.md` + `T1700-design-maps.json` (ícones, ataques CHALK/INK, HUD do inventário, menu acima do escriba) · `T1700-animation-parecer.md` (troca 100 ms, ataques, câmera lenta ×0,2, ultimate com 100 ms de hit-stop).
> Depende de: 016 (Graça, selos, `RunUpgrade`, `BlessingOffer`), 003 (loja), 002 (palavras, atril), D-084 (zonas letais das palavras), 007 (Opções, teclas).
> **[P]** = proposta (números do rules-agent; sistema do mechanics-agent; arte do design-agent; tempo do animation-agent). **[P?]** = decisão do autor.

## Objetivo

As **armas sagradas** passam a ser o ataque de todo segundo; as **palavras** viram o milagre final, raro e dourado. O escriba carrega **2 armas** e troca entre elas na onda (teclas 1 e 2); só a ativa ataca. As letras deixam de cair no chão: cada letra solta abre um **menu de escolha** rápido. O ímã de letras vira o **ímã reverso**, um passivo comprado na loja que empurra os inimigos.

## O que existe hoje e muda

| Hoje | Na 017 |
|---|---|
| Ataque automático fixo (gota de tinta, 1 de dano a cada 0,8 s) | Arma **Pena do Copista** (a mesma gota) em dados; inventário de 2 armas; teclas 1/2 |
| Letras caem no chão, ímã puxa, Traça come, 12 s de vida | **Menu de escolha**: 3 letras, 1 continua a palavra, 2,5 s em câmera lenta, perdida se o tempo acabar |
| ~3,5 palavras/min (D-082) | ~**1 palavra/min** (menos letras soltas) — números na passada de ritmo |
| Selos da Graça = bênçãos de status | Selos = **+1 nível de arma**, **status** (bênçãos + Estante Nova + Tinteiro Duplo) ou poção (018) |
| Loja: Estante, Tinteiro, apócrifos | Loja: **armas**, **ímã reverso**, apócrifos (poções na 018) |
| Graça: 6 por letra da palavra; inimigo 1–2 | Graça sobretudo das **mortes**, proporcional à força do inimigo |

## Fora do escopo

| Item | Onde |
|---|---|
| As 4 poções (teclas 3–6) | 018 |
| Passada de ritmo (raridade das letras, força das palavras, curva da Graça, preços) | fase final da 018 ou feature própria |
| Arma inicial por personagem | 010 |

## Histórias de usuário

- **US-1 (P1):** como jogador, troco entre 2 armas no meio da onda (1/2) e cada uma resolve um problema diferente.
- **US-2 (P1):** como jogador, miro a Bíblia com o mouse e seguro um raio contínuo; o Crucifixo ataca sozinho, mais forte.
- **US-3 (P1):** como jogador, quando um inimigo solta letra, escolho 1 de 3 em 2,5 s em câmera lenta; acertar a letra certa me aproxima do milagre.
- **US-4 (P1):** como jogador, subir de nível me deixa escolher melhorar uma das minhas armas ou um status.
- **US-5 (P2):** como jogador, compro armas novas e o ímã reverso na loja.
- **US-6 (P1):** como jogador, a palavra, quando sai, é um golpe que limpa a tela (dourado só dela).

## Requisitos funcionais

### Inventário e armas
- **FR-1701** Inventário de **2 espaços**; **só a arma ativa ataca**; **teclas 1 e 2** escolhem a ativa (ações novas `weapon_1`, `weapon_2`, trocáveis nas Opções). Trocar é imediato **[P]** (sem animação longa; o animation-agent define um "saque" curto).
- **FR-1702** Anselmo começa com a **Pena do Copista** no espaço 1; o espaço 2 começa vazio e é preenchido na loja. Comprar arma com os 2 espaços cheios **substitui a ativa** (confirmação na loja) **[P?]**.
- **FR-1703** Toda arma é dado (`WeaponData`): modo (automática × mirada), padrão (rajada, contínuo, órbita, arco com rastro, leque), dano, cadência, alcance, largura, atravessa, níveis (curva por nível). Nenhum número no código.
- **FR-1704** **Nível da arma** (1 → máx. [P] 5), guardado no espaço; subir de nível pelos selos da Graça.
- **FR-1705** As 6 armas (papel do game-design-agent; números do rules-agent):

| Arma | Como ataca | Papel |
|---|---|---|
| **Pena do Copista** | automática, rajada rápida, 1 alvo (gota de tinta) | inicial, confiável, fraca |
| **Bíblia** | **mirada** (mouse; sem mouse, a direção do movimento), raio de luz **contínuo** em linha, dano baixo por segundo | precisão: campeão, Monge à distância |
| **Crucifixo** | automática, rajada lenta e forte, atravessa em linha no mais próximo | dano bruto |
| **Rosário** | automática, contas **orbitando** o escriba | segurar enxame |
| **Turíbulo** | automática, balança em arco e deixa **rastro de incenso** que fere | controle de área |
| **Aspersório** | **mirada**, rajada em **leque curto** de água benta | abrir caminho de perto |

- **FR-1706** Armas desenhadas só em tinta (INK, INK_SOFT, CHALK); **o dourado é das palavras** (game bible Emenda 1). Sprites em camadas pelas regras de pixel art (D-075/D-076).
- **FR-1707** Armas usam pools e a SpatialHash (sem `instantiate` na onda; SC-001). O dano da arma não é zona letal (só as palavras matam o comum na hora).

### Menu de escolha da letra (C-008)
- **FR-1708** Quando um inimigo solta letra, abre o menu: **3 letras**, **1 continua a palavra** do atril (ou começa uma que cabe, com o atril vazio); as outras 2 pelo sorteio ponderado atual.
- **FR-1709** Durante o menu o jogo fica em **câmera lenta** [P ×0,2 — animation-agent] por **2,5 s** (tempo real); escolha por **setas + Espaço** ou **clique**; **se o tempo acabar, a letra é perdida**.
- **FR-1710** Letra rara (vogal dourada) e letra-alvo continuam marcadas no menu; a heresia e o purge (Shift) seguem valendo. Um segundo drop durante o menu entra numa **fila** [P?] (ou é perdido).
- **FR-1711** As letras não caem mais no chão: saem o ímã de letras, a vida útil no chão, a Traça comendo letras e o ímã seletivo (D-082). A Traça ganha outro comportamento [P — rules-agent/game-design].

### Ímã reverso
- **FR-1712** **Passivo comprado na loja**: a cada X s empurra os inimigos em volta do escriba (raio R); subindo de nível (selos), **o intervalo diminui** e **o empurrão passa a dar dano** (números do rules-agent). Visual: onda de tinta INK_SOFT (design-agent).

### Graça e selos (016 revisto)
- **FR-1713** A Graça vem sobretudo das **mortes**, proporcional à força do inimigo (`EnemyData.grace`); a palavra dá um bônus grande.
- **FR-1714** Os 3 selos sorteiam entre **+1 nível de uma arma equipada**, **status** (Círio, Sandálias, Lentes, Escapulário, Bolsa, Pena de Ganso — agora "cadência de todas as armas" —, Tinta Consagrada, Estante Nova, Tinteiro Duplo) e **nível do ímã reverso** se comprado; poções na 018.

### Loja (003 revisto)
- **FR-1715** A loja vende **armas** (as que o jogador não tem), **ímã reverso** e **apócrifos**; preços do rules-agent.

## Critérios de sucesso

- **SC-1701** Teste: só a arma ativa ataca; 1/2 trocam; comprar arma preenche/substitui; nível da arma aplica a curva.
- **SC-1702** Teste: o menu abre a cada drop, 1 das 3 continua a palavra, câmera lenta, perdida no fim do tempo, clique e setas funcionam.
- **SC-1703** SC-001 no Chrome igual ao build anterior com a Bíblia contínua e 300 inimigos.
- **SC-1704** Sonda: ~1 palavra/min; armas matam o bastante para as ondas fecharem; nenhuma arma domina (rules-agent).
- **SC-1705** Playtest do autor depois da fatia Bíblia + Crucifixo: "ficou mais dinâmico e divertido".

## Fases (resumo; tasks detalhadas depois dos pareceres)
1. Inventário e Pena em dados (sem mudar o que se sente).
2. Bíblia + Crucifixo → **playtest do autor**.
3. Menu de escolha da letra (fim das letras no chão).
4. Selos com nível de arma; loja com armas e ímã reverso.
5. Rosário, Turíbulo, Aspersório.
6. Medição e fechamento.
