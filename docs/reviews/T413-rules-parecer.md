# T413 — Parecer do rules-agent: obstáculos do Cap. 1 na sonda (SC-407)

> 2026-09-29 · Escopo: `data/arena/chapter_1.tres` (7 peças), FR-408..FR-413, SC-407. Sonda: `tools/balance_probe.gd -- cast god wave=N [obstacles=off]`.

**PARECER: VÁLIDO COM RESSALVAS** — SC-407 passa com ressalva; nenhuma alavanca acionada.

## 1. Faixas do A/B (propostas pelo rules-agent; a 005/006 não tinham faixa numérica)

- a) Média das 9 ondas: letras/min e mortes/min em ±20% do OFF.
- b) Nenhuma onda com letras/min ON abaixo de 50% do OFF (8+ rodadas).
- c) STUCK ≤ 5% na pior rodada.
- d) SC-506 julgado pela forma da curva ON × OFF, não pelo valor absoluto.

**Pendente do autor:** confirmar essas faixas.

## 2. Resultado (bot invencível; médias ON / OFF)

| Onda | Rodadas | Letras/min | Alvo/min | Palavras/min | Mortes/min | STUCK ON (pior, pico) |
|---|---|---|---|---|---|---|
| 1 | 8/8 | 36,6 / 45,5 (80%) | 8,6 / 13,6 | 0,62 / 1,62 | 28,1 / 37,5 | 0,10%, 1 |
| 2 | 4/4 | 33,9 / 37,9 | 8,8 / 12,2 | 0,69 / 1,61 | 27,5 / 34,6 | 0,23%, 1 |
| 3 | 4/4 | 44,0 / 37,3 | 12,8 / 7,5 | 0,86 / 0,65 | 35,6 / 29,8 | 0,44%, 3 |
| 4 | 4/4 | 30,2 / 29,6 | 9,0 / 10,2 | 0,40 / 0,80 | 25,8 / 34,4 | 0,67%, 2 |
| 5 | 8/8 | 16,1 / 28,5 (56%) | 5,2 / 6,5 | 0,19 / 0,28 | 18,9 / 24,9 | 1,00%, 4 |
| 6 | 4/4 | 23,2 / 23,1 | 8,1 / 6,8 | 0,56 / 0,56 | 23,1 / 23,4 | 3,39%, 3 |
| 7 | 8/8 | 29,6 / 39,0 (76%) | 9,4 / 11,7 | 0,44 / 0,88 | 30,0 / 32,3 | 4,65%, 4 |
| 8 | 4/4 | 63,0 / 33,7 | 17,4 / 10,5 | 0,83 / 0,67 | 43,4 / 34,0 | 2,92%, 4 |
| 9 | 4/4 | 40,4 / 25,2 | 12,8 / 7,2 | 0,50 / 0,33 | 35,0 / 24,5 | 2,80%, 4 |
| **Média** | | **35,2 / 33,3** | 10,2 / 9,6 | 0,57 / 0,82 | **29,7 / 30,6** | |

- Os critérios a, b e c passam. O ponto mais apertado é a onda 5: 56% das letras sem obstáculos, perto do limite de 50%.
- Palavras/min não serve de conclusão: dá cerca de 1 palavra por rodada, e o ruído entre rodadas chega a 3×. É o problema do bot (C-004).
- A queda da onda 5 no SC-506 aparece nos dois lados, com e sem obstáculos.
- Chefe (1 rodada de cada lado): fase 2 aos 4,45 min com obstáculos e 4,44 sem; fase 3 aos 7,46 e 8,71. A luta já estava fora dos 3–4 min antes da 004 (C-006).
- Sem god, o bot morre na onda 1 com e sem obstáculos, então essa comparação não informa nada (C-004).

## 3. Bugs que a sonda achou (corrigidos, com teste)

- **`constrain` empurrava para a margem:** um inimigo no alto do altar ia para y=19, entre a peça e a parede. Agora o empurrão só usa lados que ficam dentro da página.
- **`slide` virava para o canto entre peça e parede** quando a multidão empurrava o inimigo. Agora a direção que termina na margem é trocada pela outra.

## 4. Alavanca (só se o playtest confirmar queda)

- Mexer só nos 4 furos, os únicos no campo aberto: (72,72) (552,72) (72,272) (552,272) passam para (64,64) (560,64) (64,280) (560,280).
- A folga até a parede fica em 40 px, dentro da regra.
- Os furos de cima sobem na direção do HUD, o que depende do T420. Se o design-agent vetar, mexer só nos dois de baixo.

## 5. Layout do chefe

- Confirmado com todas as peças (`in_boss` true). O corredor do chefe, y 90–130, não encosta em nenhuma peça.

## 6. Para o playtest do autor

- a) Ondas 1, 5 e 7 com obstáculos: o ritmo de letras e o desvio dos inimigos.
- b) Chefe: esquivar Cruz, Duplo e Swipe perto do vitral e do banco sem ficar encurralado.
  - Se encurralar, tirar do layout do chefe só a peça culpada. Não mexer nos números dos ataques.
- c) Letras empurradas 6 px perto das peças: continuam legíveis e fáceis de pegar?
- d) C-006: medir a duração da luta já com os obstáculos.

## 7. Nova medição com o layout da D-080 (altar 556,172 · banco 104,328)

- **Condições:** 2026-09-29, só 2 Godot rodando por vez. Nas medições anteriores havia 3 sondas do chefe travadas ocupando a CPU, então aqueles números vieram com carga extra.
- **Rodadas:** 8 por lado nas ondas 1, 5 e 7; 4 por lado nas outras.
- **Números (com obstáculos / sem):**
  - Letras/min, média: **36,7 / 32,9** (+12%).
  - Mortes/min, média: **31,8 / 31,7**.
  - Pior onda: a 2, com 74% das letras sem obstáculos (limite 50%).
  - STUCK, pior rodada: **2,07%** (teto 5%).
  - Palavras/min: 0,68 / 0,95. Não serve de conclusão, porque dá cerca de 1 palavra por rodada (C-004).
- **Veredito:** passa nas faixas da D-079 (a, b, c). Sem alavanca.
