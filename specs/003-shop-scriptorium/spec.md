# 003 — Loja: Scriptorium Noturno

> Status: **Aprovada** (2026-09-28, "1a 2a 3a 4a"; D-058). **Complete** (2026-09-28). Fechamento: D-060.
> Pareceres (2026-09-28): game-design-agent **AJUSTAR** e rules-agent **VÁLIDO COM RESSALVAS**. Os ajustes estão aplicados (marcados **[P]**).
> Depende de: 001, 002, 005 (Complete). Game bible §3.9 (D-017, D-018). Ficha 28 (tela da loja) e ficha 31 (ícones dos itens). Ressalvas da D-057.
> Legenda: **[INICIAL]** = número proposto, a validar pelo rules-agent; tudo fica nos `.tres`.

## Objetivo

Entre uma onda e outra, o escriba se senta no Scriptorium Noturno e gasta a **tinta dourada** da partida em **cartas**: os 9 **itens** (melhorias da partida) e os 5 **apócrifos** (que liberam a palavra, D-017). Comprar, **travar** uma carta para a próxima visita e **rerolar** a oferta. É aqui que o atril cresce para 7 e 8 e as Grandes Orações ficam alcançáveis.

## Fora do escopo

| Item | Feature |
|---|---|
| Arte final da loja e dos ícones (placeholders por script até lá, D-024/D-047 7C) | arte |
| Sons da loja (a arquitetura da 009 já recebe os eventos) | 009 Fase 2 |
| Passivas de personagem que mexem na loja (Hildegarda) | 010 |
| Moeda ou desbloqueio que passa de uma partida para outra | fora (D-018) |

## Histórias de usuário

- **US-1 (P1):** como jogador, depois de cada onda vejo a loja com cartas, o preço de cada uma e minha tinta, e compro o que dá.
- **US-2 (P1):** como jogador, compro o apócrifo que eu quero e ele passa a valer no atril, nas dicas e no drop na hora.
- **US-3 (P1):** como jogador, compro a Estante Nova e o atril cresce, até 8; assim as Grandes Orações cabem.
- **US-4 (P2):** como jogador, travo uma carta que não posso pagar agora e ela está lá na próxima visita.
- **US-5 (P2):** como jogador, pago para rerolar a oferta quando nada me serve.
- **US-6 (P1):** como jogador de teclado, faço tudo na loja sem mouse.

## Requisitos funcionais

### Fluxo
- **FR-301** Ao fim de cada onda (menos a última do capítulo), depois de a tinta que sobrou voar até o escriba (D-042), a **loja abre** e o jogo fica parado. A loja substitui a pausa de 3 s entre ondas. Sair da loja (**Próxima onda**) começa a onda seguinte.
- **FR-302** A loja **não tem tempo limite [P]**: é o respiro no lugar dos 3 s; o "curto" vem de poucas cartas e do Enter sempre à mão.
- **FR-302b** A loja abre também depois da **última onda**, antes do chefe (006) **[D-058]**. Até a 006 existir, fechar essa loja conclui o capítulo.

### Oferta
- **FR-303** Cada visita mostra **3 itens + 1 vaga fixa de apócrifo** (um apócrifo ainda não liberado) **[D-058]**. Com os 5 apócrifos liberados, a vaga vira item.
  O sorteio usa o `GameState.rng` (mesma seed, mesma loja).
- **FR-304** Estante Nova com o atril em 8 sai do baralho. Círio Bento com 8 velas máximas **continua**, mas só acende 1 vela **[P]** (senão o fim do capítulo fica sem recuperação). Rosário de Contas: compra única.
- **FR-305** **Preço** = `roundi(base_price × (1 + 0.10 × (onda que acabou − 1)))` **[P]** (×1,7 na visita 8). Comprar o mesmo item de novo não encarece além disso.

### Ações
- **FR-306** **Comprar:** com tinta suficiente, a carta é paga, aplicada na hora e marcada como vendida. Sem tinta, a carta aparece em dithering (nunca opacidade, ficha 28) e comprar não faz nada.
- **FR-307** **Travar:** a carta travada sobrevive ao reroll e volta na próxima visita **pelo preço da visita em que foi travada [P]** (premia quem planeja). Travar de novo destrava. Só **1 carta travada [P]**.
- **FR-308** **Reroll:** troca as cartas não travadas e não vendidas. Custa **5**, +**3** a cada reroll na mesma visita, sem subir por onda **[P]**.

### Efeitos (RunStats)
- **FR-309** Os números do escriba passam a ser lidos de um **RunStats** (a base é o `PlayerData`; os itens somam *modifiers*). Nada muda para quem lê hoje o `PlayerData`: o RunStats expõe os mesmos campos. Zera a cada partida.
- **FR-310** Os 9 itens, com preços e números do rules-agent **[P]**. Empilhamento aditivo sobre a base do personagem, com teto:

  | Item | Preço base | Efeito por compra | Teto |
  |---|---|---|---|
  | Pedra-Ímã | 4 | +30% no raio do ímã | +150% (100 px); o ×2 do LUMEN vem depois |
  | Rosário de Contas | 4 | stun da heresia ×0,5 | 1 compra |
  | Sandálias do Peregrino | 5 | +10% de velocidade | +50% |
  | Bolsa do Esmoler | 5 | +20% de tinta dourada | +60% |
  | Lentes do Copista | 6 | +3 no bônus da letra-alvo | +9 (3 compras) |
  | Tinteiro Duplo | 7 | +10% de chance de letra dupla (ver FR-310b) | 50% |
  | Pena de Ganso Fina | 8 | ataque automático ×0,85 (multiplicativo) | intervalo mínimo 0,40 s |
  | Círio Bento | 8 | +1 vela máxima e acende 1 | 8 velas (depois: só acende 1) |
  | Estante Nova | 9 | +1 espaço no atril | atril 8 |

- **FR-310b** Tinteiro Duplo: a letra extra é um **segundo sorteio independente** do drop ponderado (mesmos alvos, FR-013) **[D-058]**, caindo ao lado como outra coleta. Nunca entra sozinha no atril.
- **FR-311** **Carta de apócrifo** (preços **[P]**: PURGO 5 · FIDES 6 · LUMEN 7 · GLORIA 9 · VERBUM 10; PURGO o mais barato, D-057): comprar chama `GameState.unlock_word` (a palavra passa a valer na hora; VERBUM libera o B no mesmo instante, D-057). Vale só na partida (D-017).

### Economia
- **FR-312** A tinta dourada só vale dentro da partida (D-018) e não expira (D-042). Hoje só os campeões soltam tinta (~28 no Cap. 1, e as lojas das ondas 1 e 2 abririam vazias). **Nova fonte [D-058]:** um **dízimo fixo de 4 de tinta ao fim de cada onda concluída** (determinístico, sem pickups nem pool). Inimigo comum não solta tinta (manteria o chão limpo para as letras e o campeão como a fonte grande). Tinta acumulada ao abrir cada loja: ~4, 8, 16, 24, 32, 40, 48, 56.

### Tela (ficha 28)
- **FR-313** Tela 640×360: o escriba sentado à mesa (6 quadros @200 ms), as cartas com ícone 24×24 em 2× (ficha 31), nome, efeito curto e preço (a informação mais legível depois do ícone), o contador de tinta com roll-up, o botão de reroll (dado de osso; custo visível) e a **fita da próxima onda**. Estados da carta: entrada, idle, hover, sem dinheiro, comprar, travada, reroll, vendida. BLOOD só em alerta (preço sem dinheiro, fogo do reroll).
- **FR-314** Teclado: ←/→ escolhe a carta, **Espaço** compra, **L** trava, **R** rerola, **Enter** vai para a próxima onda. Esc abre a pausa normal.

### Técnica
- **FR-315** Cartas e itens em `.tres` (`data/shop/items/*.tres`, `data/shop/shop_tuning.tres`); a lógica da oferta é pura e testável (`ShopOffer`). Nenhum `instantiate()` durante a onda (a loja não é onda, mas usa pools/nós pré-criados).
- **FR-316** Placeholders: ícones 24×24 dos 9 itens e das 5 cartas de apócrifo gerados por script (`tools/gen_placeholders.gd`), pela ficha 31.

### Fora (pareceres)
- Vender cartas e cura avulsa: fora (alongam a loja / não estão no roadmap).

## Critérios de sucesso

- **SC-301** Mesma seed, mesma sequência de ofertas (teste).
- **SC-302** Comprar a Estante Nova 3 vezes leva o atril de 5 a 8, e a 4ª não aparece mais (teste).
- **SC-303** Comprar um apócrifo faz a palavra valer na hora (atril VALID, dicas, drop) (teste).
- **SC-304** Travar mantém a carta através do reroll e da onda seguinte (teste).
- **SC-305** Toda a loja funciona só com teclado (teste de input).
- **SC-306** Com a tinta do Capítulo 1, um jogador que mata os campeões compra **cerca de 5 cartas** no capítulo (sonda de balanceamento, preço efetivo médio ~10).
- **SC-307** Os SC-001/SC-503 se mantêm (a loja não roda durante a onda).
