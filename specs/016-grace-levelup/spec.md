# 016 — Graça: XP e subir de nível no meio da onda

> Status: **Aprovada** (2026-09-30, "1a 2a 3a"; D-083) — pedido do autor (D-082: "a gameplay tá meio chata"; "ganhar XP e upar no meio da onda… escolhe se melhora o dano, vida").
> Respostas do autor já dadas (D-082, C-007): XP de **matar inimigos e de fechar palavras** (2b + palavras); o jogo **pausa** e **3 selos** aparecem desenhados na página, escolha por tecla 1/2/3 ou clique (3a/C-007 "a"); as melhorias pequenas **saem da loja** e viram escolhas do level-up (4a); vida cai **rara** como pingo de cera (6b). Instrumentos (5a) ficam na **017**.
> Parecer do game-design-agent (D-082): XP e level-up só ajudam se alimentarem as palavras; escolhas no tema ("bênçãos"); loja com as coisas grandes.
> Depende de: 001 (vitals/velas, ataque automático), 002 (palavras, `Miracle.damage_mul`), 003 (loja, `RunStats`, `ShopItemData`), 005 (inimigos, campeões), 007 (telas, `tr()`, `Settings.key_label`), D-082 (ritmo das palavras).
> Pareceres (2026-09-30): **rules-agent** VÁLIDO COM RESSALVAS (números abaixo; R1–R5 aplicadas) · **mechanics-agent** (FSM, dados, eventos, pausa; aplicado abaixo e em `tasks.md`).
> **[P]** = proposta do Claude. **[P?]** = decisão do autor.

## Objetivo

Dar ao jogador **crescimento dentro da onda**: a Graça (XP) enche matando inimigos e, mais ainda, fechando palavras; a cada nível o jogo pausa e o escriba escolhe **1 de 3 bênçãos** (dano das palavras, vela, ímã, velocidade…). A loja entre as ondas passa a vender só o que é grande: palavras (apócrifos), atril e, na 017, instrumentos.

## O que existe hoje e muda

| Hoje | Na 016 |
|---|---|
| Nada cresce durante a onda; a tinta só vira compra na loja | Barra de Graça no HUD; subir de nível várias vezes por onda |
| A loja vende 7 itens pequenos (Pedra-Ímã, Sandálias, Círio Bento, Lentes do Copista, Rosário, Bolsa de Esmolas, Pena de Ganso Fina) | Esses 7 **saem da loja** e viram bênçãos do level-up; a loja fica com Estante Nova, Tinteiro Duplo e os apócrifos (emenda à 003) |
| Dano das palavras só cresce com GLORIA (temporário) | Bênção **Tinta Consagrada**: +X% de dano das palavras, permanente na partida |
| Vida: parado (D-011), VITA, campeão, Círio Bento, SALVATOR | + **pingo de cera** raro de inimigo comum (6b) |

## Fora do escopo

| Item | Feature |
|---|---|
| Instrumentos do escriba na loja (penas, tintas) | 017 |
| Letras de abertura e garantia da letra-alvo (D-082, "precisa de código") | só se o playtest pedir |
| Progressão entre partidas (meta) | 010 |
| Arte definitiva dos selos | autor |

## Histórias de usuário

- **US-1 (P1):** como jogador, vejo a barra de Graça encher enquanto mato e escrevo, e sinto que fechar uma palavra vale muito mais que matar.
- **US-2 (P1):** como jogador, ao subir de nível o jogo pausa e escolho 1 de 3 selos na página; a escolha muda como eu jogo o resto da partida.
- **US-3 (P1):** como jogador, entendo cada selo pelo desenho e por uma frase curta, sem ler números pequenos.
- **US-4 (P2):** como jogador, às vezes um inimigo deixa um pingo de cera que acende uma vela.
- **US-5 (P1):** como jogador, a loja entre as ondas vende coisas que mudam a partida (palavras novas, atril), não números pequenos.

## Requisitos funcionais

### Graça (XP)
- **FR-1601** A Graça vem de: **matar inimigo** (`EnemyData.grace`: Traça 1, Diabrete 1, Borrão 1, Monge Oco 2, Gárgula 2; **campeão ×5**) e **fechar palavra** (**6 por letra** da palavra digitada: LUX 18 … 8 letras 48; **combo**: a 2ª palavra vale ×1,5; o eco do VERBUM conta as 6 letras de VERBUM, não a palavra repetida). Heresia, apagar o atril (Shift) e o fim da onda (`dissolve_all`) não dão Graça; a palavra PURGO dá normalmente. Números em `data/tuning/grace.tres`.
- **FR-1602** Proporção: ~2/3 da Graça do capítulo vem de palavras (conta do rules-agent: 67%; 75% nas ondas 1–4, 60% nas 5–9).
- **FR-1603** Curva: subir do nível n para o n+1 custa **30 + 6·(n−1)** (`level_base` 30, `level_step` 6; tabela opcional que substitui a fórmula). Previsto: **17 níveis no capítulo**, 3·3·2·2·2·1·2·1·1 por onda; primeiro nível em ~15–25 s. `boss_grace_mul` 1,0 (alavanca se houver pausa demais no chefe).
- **FR-1604** A Graça e o nível **zeram a cada partida** e **continuam entre as ondas** do capítulo (não zeram na loja).
- **FR-1605** Se a Graça passar de mais de um nível de uma vez, os níveis ficam **na fila**: um selo depois do outro, sem despausar entre eles.

### Subir de nível (C-007 "a")
- **FR-1606** Ao subir de nível, o jogo **pausa** e **3 selos** aparecem desenhados sobre a página, com o nome e uma frase curta de cada bênção; escolha por **1/2/3**, clique, ou setas + Confirmar (ações novas `grace_pick_1..3`, trocáveis na tela de Opções).
- **FR-1607** Proteção contra escolha sem querer: a escolha só vale **0,4 s** (tempo real) depois que os selos abrem **e** com uma tecla apertada depois disso (tecla segurada do combate não conta). Recomeça a cada selo da fila e ao fechar a Pausa.
- **FR-1608** Os 3 selos são sorteados (sorteio próprio, não mexe no das letras) sem repetir entre as bênçãos **abaixo do teto**; se sobrarem menos de 3, mostra as que houver; se não sobrar nenhuma, a reserva **Graça plena** (+1 vela; com todas acesas, +3 de tinta).
- **FR-1609** Ao escolher, o selo "carimba" (tempo do animation-agent), o jogo volta e o escriba ganha **0,5 s de invulnerabilidade** (só depois do último selo da fila; não acumula).
- **FR-1610** Nível subido durante a **Pausa**, a **loja**, uma **cutscene** ou o **Game Over** espera o jogo voltar; morte no mesmo quadro descarta os selos; depois da morte do chefe não há selo. A Pausa (Esc) pode abrir por cima dos selos e, ao fechar, os selos continuam (o jogo não despausa por baixo).
- **FR-1610b** Testes, sonda e stress escolhem sozinhos, sem pausar (como a loja que fecha sozinha).

### Bênçãos (o que se escolhe)
- **FR-1611** Bênçãos (valor por escolha como na loja; tetos revistos para ~17 escolhas; somando os tetos, 28 escolhas: ninguém fecha tudo no capítulo):

| Bênção | Efeito por escolha | Teto (escolhas) | Origem |
|---|---|---|---|
| **Tinta Consagrada** | +15% de dano das palavras (`word_damage_mul`) — **só dano**, a cura da VITA/SALVATOR não aumenta | +60% (4) | nova (pedido "dano") |
| **Círio Bento** | +1 vela máxima e acende 1 vela | 8 velas (5) | loja → level-up (pedido "vida") |
| **Pedra-Ímã** | +30% raio do ímã | 100 px (5) | loja → level-up |
| **Sandálias do Peregrino** | +10% velocidade | 135 (5) | loja → level-up |
| **Lentes do Copista** | +6 no bônus da letra-alvo | +18 (3) | loja → level-up |
| **Rosário** | heresia atordoa metade | ×0,5 (1) | loja → level-up |
| **Bolsa do Esmoler** | +20% tinta dourada | +40% (2) | loja → level-up |
| **Pena de Ganso Fina** | ataque automático 15% mais rápido | 0,56 s (3) | loja → level-up |

- **FR-1612** Bênçãos e itens da loja têm a mesma base de dados (stat, modo, valor, teto, cura em dados), aplicada por um só código (`RunUpgrade`) — sem sistema de números novo.
- **FR-1613** Nenhuma bênção deixa o ataque automático mais forte que as palavras: o dano dele não sobe; a cadência para em +43% (abaixo dos +60% da Tinta).

### Loja (emenda à 003 e à game bible §3.9)
- **FR-1614** Os 7 itens saem da loja. Fica: **Estante Nova**, **Tinteiro Duplo** e os **5 apócrifos** (13 cartas). **2 vagas de item** (antes 3, senão uma fica vazia), preços iguais, **dízimo 4 → 5** (com 4 não se compra nada na 1ª visita), **reroll 5+3 → 3+2**. Previsto: ~5–6 cartas compradas no capítulo (SC-306 revisto). A 017 (instrumentos) reenche a loja.

### Pingo de cera (6b)
- **FR-1615** Inimigo comum solta um **pingo de cera** com chance **1%** (~4 no capítulo; campeão continua com a vela garantida). Pisar acende 1 vela (o ímã não puxa); com as velas cheias ele **fica no chão**. Some depois de **12 s**, piscando nos últimos 2 s (como a letra). No máximo 3 no chão (pool; sem `instantiate` na onda). Sorteio próprio. Sprite `ITM_` pelo design-agent.

### HUD
- **FR-1616** Barra de Graça fina (estilo da barra do chefe), com o número do nível, num lugar que não cubra a área central (SC do HUD); ao subir de nível, um brilho curto na barra antes da pausa.
- **FR-1617** Texto em `tr()` (PT-BR e EN, `i18n/ui.csv`); nomes e frases das bênçãos em dados.

## Critérios de sucesso

- **SC-1601** Sonda (cast god, 9 ondas): 2–4 níveis por onda nas ondas 1–3 e ≥ 1 nas ondas 7–9; ~2/3 da Graça vindo de palavras.
- **SC-1602** Teste: a pausa do level-up congela inimigos, projéteis, letras e o cronômetro; a escolha aplica o valor no `RunStats`; nenhuma bênção passa do teto; fila de níveis funciona.
- **SC-1603** Teste: a loja nunca oferece os 7 itens que migraram.
- **SC-1604** Teste: zero `instantiate` durante a onda (selos e pingos em pool).
- **SC-1605** A comparação A/B dos obstáculos (D-079) e o SC-001 continuam dentro das faixas.
- **SC-1606** Playtest do autor: "tá menos chato" — subir de nível várias vezes por onda é bom, a pausa não irrita.

## Perguntas para o autor [P?]

1. Quantas vezes subir de nível por onda? (a) 2–4 no começo, menos no fim **[P]**; (b) mais vezes (5+); (c) menos (1–2).
2. Nome da XP no jogo: (a) "Graça" **[P]**; (b) "XP"; (c) outro.
