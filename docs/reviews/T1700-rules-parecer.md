# T1700 — Parecer do rules-agent: números da 017 "Arsenal sagrado"

> 2026-09-30 · **VÁLIDO COM RESSALVAS.**
>
> **Carga das ondas (HP/s que nasce):**
>
> | Onda | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
> |---|---|---|---|---|---|---|---|---|---|
> | HP/s | 2,5 | 3,0 | 3,4 | 4,1 | 5,0 | 5,4 | 6,5 | 7,5 | 8,3 |
>
> - A Pena de hoje dá 1,25 de DPS.
> - Com ~1 palavra/min, a arma ativa precisa cobrir 75–80%: ~2 de DPS na onda 1, ~4 na onda 5 e ~6,5 na onda 9.
> - Meta no nível 5: 5–7 de DPS efetivo (×1,43 com a Pena de Ganso no teto).
> - Todo dano de arma é inteiro.

## 1. Armas
Colunas: "1 alvo" = DPS contra um inimigo; "grupo" = DPS efetivo contra Diabretes (estimativa; a sonda mede).

**Pena do Copista:** automática; alcance 160, velocidade 220, não atravessa; as gotas vão nos N mais próximos.

| Nv | Dano | Intervalo | Gotas | 1 alvo | Grupo |
|---|---|---|---|---|---|
| 1 | 1 | 0,80 | 1 | 1,25 | 1,25 |
| 2 | 1 | 0,70 | 1 | 1,43 | 1,43 |
| 3 | 1 | 0,70 | 2 | 2,86 | 2,86 |
| 4 | 1 | 0,60 | 2 | 3,33 | 3,33 |
| 5 | 1 | 0,60 | 3 | 5,00 | 5,00 |

**Bíblia:** mirada; raio contínuo; dano por tick em cada inimigo no raio; atravessa até 2.

| Nv | Dano/tick | Tick | Comprimento × largura | 1 alvo | Grupo |
|---|---|---|---|---|---|
| 1 | 1 | 0,60 | 200 × 6 | 1,67 | 3,3 |
| 2 | 1 | 0,50 | 200 × 6 | 2,0 | 4,0 |
| 3 | 1 | 0,50 | 260 × 10 | 2,0 | 4,0 |
| 4 | 1 | 0,40 | 260 × 10 | 2,5 | 5,0 |
| 5 | 1 | 0,33 | 260 × 10 | 3,0 | ~5–6 |

- **[P?]** `precision_mul` 1,5 contra campeão e chefe (4,5 contra 1 alvo no nível 5).

**Crucifixo:** automático; linha instantânea no mais próximo, atravessa todos.

| Nv | Dano | Intervalo | Linha | 1 alvo | Grupo | Pesados |
|---|---|---|---|---|---|---|
| 1 | 4 | 1,60 | 140 × 8 | 2,5 | 2,5 | ~5 |
| 2 | 4 | 1,40 | 140 × 8 | 2,86 | 2,86 | ~5,7 |
| 3 | 6 | 1,40 | 140 × 8 | 4,3 | 2,86 | ~7 |
| 4 | 6 | 1,40 | 180 × 12 | 4,3 | 4,3 | ~8 |
| 5 | 8 | 1,20 | 180 × 12 | 6,7 | 5,0 | ~9 |

**Rosário:** contas em órbita; cada inimigo leva no máximo 1 acerto a cada 0,4 s.

| Nv | Contas | Dano | Raio | Volta | 1 alvo | Grupo |
|---|---|---|---|---|---|---|
| 1 | 2 | 1 | 32 | 1,6 s | 1,25 | ~3 |
| 2 | 3 | 1 | 32 | 1,6 s | 1,9 | ~4,5 |
| 3 | 3 | 1 | 40 | 1,6 s | 1,9 | ~5 |
| 4 | 3 | 2 | 40 | 1,6 s | 3,75 | ~6 |
| 5 | 4 | 2 | 40 | 1,3 s | 5,0 | ~7 |

**Turíbulo:** golpe em arco de 150° alternando os lados; rastro com largura 12 e tick de 1 a cada 0,5 s.

| Nv | Dano | Intervalo | Raio | Rastro | 1 alvo | Grupo |
|---|---|---|---|---|---|---|
| 1 | 1 | 1,2 | 40 | 1,5 s | ~1,8 | ~4 |
| 2 | 1 | 1,2 | 40 | 2,5 s | ~1,8 | ~4,5 |
| 3 | 2 | 1,2 | 40 | 2,5 s | ~2,7 | ~5,5 |
| 4 | 2 | 1,2 | 52 | 2,5 s | ~2,7 | ~6 |
| 5 | 2 | 1,0 | 52 | 2,5 s | ~4,0 | ~7 |

**Aspersório:** mirado; leque de gotas; dano 1; não atravessa.

| Nv | Gotas | Ângulo | Alcance | Intervalo | Dano | 1 alvo | Grupo |
|---|---|---|---|---|---|---|---|
| 1 | 4 | 50° | 64 | 1,10 | 1 | 1,8 | 2,7 |
| 2 | 5 | 50° | 64 | 1,10 | 1 | 2,3 | 3,6 |
| 3 | 5 | 50° | 80 | 1,10 | 1 | 2,3 | 3,6 |
| 4 | 5 | 50° | 80 | 0,85 | 1 | 2,9 | 4,7 |
| 5 | 5 | 50° | 80 | 0,85 | 2 | 5,9 | ~7 |

**Regras gerais das armas:**
- No nível 5, o grupo fica entre 5 e 7 e o 1 alvo entre 3 e 7; as armas de perto podem ter até 30% a mais.
- A arma comprada começa no nível 1.
- O dano no chefe usa a tag "auto".
- A Pena de Ganso multiplica o intervalo, o tick e a volta de todas as armas.

## 2. Menu da letra
- **Alvo:** 5,0–6,5 menus por minuto, o que dá ~1,0–1,3 palavra por minuto (acerto de 90%, palavra média de 4,5 letras).
- **Chance de letra = 0,04 × HP:**

| Inimigo | Chance |
|---|---|
| Traça | 0,04 |
| Diabrete | 0,08 |
| Borrão | 0,12 |
| Monge | 0,16 |
| Gárgula | 0,20 |
| Campeão | 1 letra garantida, rara (campo novo) |

- **`WaveData.letter_drop_mul`:**

| Onda | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|---|---|---|---|---|---|---|---|---|---|
| Multiplicador | 1,00 | 0,90 | 0,80 | 0,70 | 0,57 | 0,55 | 0,47 | 0,42 | 0,38 |

  Resultado: 5,1 a 6,5 letras por minuto em todas as ondas.
- **Câmera lenta:** ×0,2 (teto ×0,3).
- **Fila:** 1; o 3º drop se perde; 0,25 s reais entre dois menus.
- **Letras vindas de palavra:** no máximo 1 por conjuração (campo novo).
- **REQUIEM** `guaranteed_drop_cap`: 40 → 2.
- **As 2 opções que não continuam a palavra:** sorteio sem `target_bonus`, diferentes da certa, cada uma com 5% de ser rara.
- **Saem de uso:** `target_bonus`, `letter_lifetime`, `selective_magnet`, `blink_time`, `magnet_radius` das letras.
- **LetterSafety do chefe:** `wait`/`cooldown` 4 → 8 s.
- **Tinteiro Duplo:** +0,08 por selo, teto 0,24.

## 3. Palavras como ultimate
**Regra:** medidas lineares ×1,5; duração das zonas que ficam na tela ×~1,3; `damage` ×2,5. A zona letal já mata o comum, então o `damage` vale para campeão e chefe.

| Palavra | Depois |
|---|---|
| LUX | 480 × 15, dano 20 |
| IGNIS | raio 72, 4 s, dano 4 |
| CRUX | 72 × 9, 5 s, dano 6 |
| SANCTUS | raio 135, 8 s, dano 5 |
| ANGELUS | raio 60, largura 12, 13 s, dano 8 |
| MORTIS / REQUIEM / MISERERE | dano 50 / 50 / 100 |
| PURGO | 25 |
| FLAMMA | 480 × 30, 4 s, dano 4 |
| MARTYRIUM | 240 × 8, 5 s, dano 6 |
| VAPOR | raio 180, 5 s, dano 4 |
| CAECITAS | raio 210, dano 15 |

- **`boss_damage_filter`:** 120/240 → 250/500.
- **Campeão:** `champion_strike_frac` 0,4 → 0,5; `hp_mul` continua 6. Com as armas, morre em 4–10 s.
- **Tinta Consagrada:** +12% de alcance e dano por selo, teto de 3 selos (stat novo `word_area_mul`).

## 4. Graça
| Inimigo | Graça |
|---|---|
| Traça | 1 |
| Diabrete | 2 |
| Borrão | 3 |
| Monge | 5 |
| Gárgula | 6 |
| Campeão | ×5 |

- `per_letter` 6 → 10.
- Curva: `level_base` 40, `level_step` 24 (o nível custa 40, 64, 88, 112…).
- Total previsto no capítulo: ~3.900 de Graça (~3.360 das mortes), o que leva ao **nível ~18**. São 2 níveis na onda 1 e 1–2 na onda 9.

## 5. Selos
- **Chances:**
  - nível da arma ativa: 30%;
  - nível da reserva: 15%;
  - status: 45%;
  - ímã reverso (se comprado): 10%.
- **Garantia:** pelo menos 1 selo de arma, se houver arma para subir. Teto no nível 5.
- **Pena de Ganso:** todas as armas ×0,88, teto 0,70 (3 selos).
- **Estante Nova:** vira selo (+1, teto 8).
- **Tinteiro Duplo:** vira selo (+0,08, teto 0,24).
- **Pedra-Ímã:** sai.
- **Lentes [P?]:** tempo do menu +0,5 s, teto +1,0 s; ou sair.
- **Iguais:** Círio, Sandálias, Escapulário e Bolsa.

## 6. Ímã reverso (compra única 8; os níveis vêm pelos selos)
| Nv | Intervalo | Raio | Empurrão | Dano |
|---|---|---|---|---|
| 1 | 6,0 s | 56 | 40 | 0 |
| 2 | 5,0 s | 56 | 40 | 0 |
| 3 | 4,5 s | 64 | 48 | 1 |
| 4 | 4,0 s | 72 | 48 | 1 |
| 5 | 3,5 s | 72 | 56 | 2 |

- **Campeão:** empurrão ×0,5, dano normal.
- **Chefe:** não é empurrado, mas leva o dano.

## 7. Loja
- **Armas:** base 6 cada (~10,8 na onda 9).
- **1ª loja:** as 2 vagas são armas, garantido.
- **Dízimo:** 5 → 6.
- **Tinta no capítulo:** ~82 (~100 com a Bolsa).
- **Compras esperadas:** ~6–8 no capítulo.

## 8. Riscos e aceite
- **Riscos:**
  - **Onda 1:** a Pena fraca não dá conta (alavanca: `spawn_rate_end` 2,0 → 1,6).
  - **Ondas 7–9:** exigem a arma ativa no nível 5.
  - **Campeões:** a Bíblia sem `precision_mul` passa de 10 s.
  - **Chefe:** 1500 de HP deve dar ~3–3,5 min.
  - **Chuva de letras:** sem os tetos, cada palavra abre vários menus.
  - **Efeitos órfãos:** LUMEN, Lentes e Tinta Iluminada precisam de efeito novo (proposta para a LUMEN: chance de letra ×2 por 10 s).
  - **Heresia:** custa ~45 s de progresso.
- **Sonda nova (bot):**
  - escolhe a letra certa com p = 0,9;
  - sobe a arma ativa até o nível 5;
  - compra na 1ª loja a arma de `weapon2=`;
  - modo `solo=`.
- **Aceite:**
  - 0,8–1,3 palavra por minuto;
  - sem god, a onda 1 é vencida e a onda 9 começando do zero é derrota;
  - nenhuma arma passa de 1,25× a mediana das 6;
  - campeão morre em 4–15 s;
  - chefe entre 3 e 4 min no playtest.
