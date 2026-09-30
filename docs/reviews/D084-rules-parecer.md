# D-084 — Parecer do rules-agent: palavras de ataque matam quem estiver no alcance

> 2026-09-30 · **VÁLIDO COM RESSALVAS**

## Achado principal
Para os inimigos comuns, a regra muda pouco. Todo comum tem HP de 1 a 5, e todo ataque já tira 5 ou mais por contato. O que muda de fato:
- quem **entra** numa área que continua na tela morre na hora, sem esperar o próximo tick (até 0,25 s);
- quem **entra** na linha do LUX durante os 0,3 s dela morre;
- quem **nasce** durante as varreduras de tela morre;
- o **campeão** passa a levar um golpe forte.

## Quem entra na regra
- **Ataque:** LUX, IGNIS, CRUX, MORTIS, PURGO, SANCTUS, ANGELUS, MISERERE, FLAMMA, MARTYRIUM, REQUIEM, VAPOR, CAECITAS.
- **Ferramenta (fica fora):** PAX, AQUA, VITA, SALVATOR, LUMEN, FIDES, GLORIA, DOMINUS, SPIRITUS.
- **VERBUM:** o eco é uma conjuração nova, então herda a classe da palavra que repete.

## Campeão
- **`champion_strike_frac` = 0.4** (em `champion.tres`).
  - No primeiro contato de cada conjuração com cada campeão, o dano é max(dano normal, ceil(0,4 × max_hp × damage_mul)).
  - Os ticks seguintes da mesma conjuração continuam com o dano normal.
- **`hp_mul` 4 → 6.** Sem isso, o campeão Diabrete morreria com 1 LUX.
  - Com 6, os campeões ficam com Diabrete 12, Borrão 18, Monge 24 e Gárgula 30.
  - LUX com o golpe forte mata em 2, 3, 3 e 3 acertos.

## Janela letal = `duration` visual (em dados)
| Palavra | Janela |
|---|---|
| LUX | 0,3 s (0,5 s opcional, a decidir com o animation-agent) |
| IGNIS | 3 s |
| CRUX | 4 s |
| SANCTUS | 6 s |
| ANGELUS | 10 s |
| FLAMMA | 3 s |
| MARTYRIUM | 4 s |
| VAPOR | 4 s |
| MORTIS, PURGO, MISERERE, REQUIEM | 0,6 s (hoje é o `SWEEP_TIME` no código; vira `duration` no `.tres`) |
| CAECITAS | 0,42 s (hoje é `FLASH_TIME` + `RING_TIME` no código; vira `duration` no `.tres`) |

## Chefe
Nada muda: mesmos danos, mesmos ticks e o mesmo filtro. Três cuidados:
- a zona letal não bate no chefe;
- o golpe forte não vale para o chefe;
- a PURGO continua com 10 literais no chefe.

## Reequilíbrio
- **Asmodeus:** HP 1500 por enquanto; 1000 se o playtest passar de 4 min (C-006).
- **Ondas 6–9** (só se o critério A falhar): `spawn_rate_end` ×1,2 e `max_alive` do Diabrete +20.
- **Curva da Graça** (só se o critério C falhar): 30 + 8·(n−1).

## Critérios de aceite
- **A.** Sem god, a onda 1 é vencida e a onda 9 começando do zero continua sendo derrota.
- **B.** A média de mortes/min das 9 ondas sobe no máximo +25%, e letras/min não cai abaixo da linha de base em nenhuma onda.
- **C.** A Graça dá de 15 a 20 níveis no capítulo.
- **D.** O campeão morre com 2 ou 3 conjurações de LUX, CRUX ou IGNIS; com MORTIS, em 1.
- **E.** A/B dos obstáculos (D-079) refeito.
- **F.** Chefe entre 3 e 4 min no playtest.
