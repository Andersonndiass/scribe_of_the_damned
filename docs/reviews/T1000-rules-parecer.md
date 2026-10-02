# T1000 — Parecer do rules-agent: 010 Personagens (D-101)

> 2026-10-02 · Skill: `game-development/game-design`. **VÁLIDO COM RESSALVAS** (P1–P5 ao autor; R1 e R2 bloqueiam).

## Regra geral: "começo adiantado, mesmo teto"
As passivas de atributo adiantam o começo, mas o teto é o mesmo das bênçãos (Tinteiro 0,24; Sandálias 135 px/s; Estante 8; Escapulário ×0,5). Quem já nasce no teto não recebe aquele selo (`RunStats.is_capped`).

## Números
| Escriba | Passiva (PlayerData) | Arma | Poção inicial | Golpes até morrer |
|---|---|---|---|---|
| Anselmo | — | Pena (exclusiva) | Óleo ×1 | 4 |
| Hildegarda | `word_guard_slots` 2 | Aspersório | Água Benta ×1 | 3 |
| Tomé | `heresy_stun_mul` 0,0 · `start_candles` 2 | Turíbulo | Óleo ×2 | 4 |
| Iluminador | `double_letter_chance` 0,24 | Bíblia | Iluminura ×1 | 3 |
| Beda | `atril_capacity` 4 · `move_speed` 108 | Crucifixo | Vinho ×1 | 3 (+20% vel.) |

- A arma inicial de qualquer escriba vende por `starter_ref_price` 4.
- Riscos: Hildegarda fraca de arma (reserva: Aspersório `interval` 0,95); Tomé morre com vida cheia num golpe forte (alavancas: `iframes` 1,25 ou P1b); Iluminador o mais forte em palavras (alavanca: 0,16); Beda o mais forte em sobrevivência (alavanca: velocidade 104).

## Heresia sobrevivida (Tomé)
Uma `heresy_committed` conta se, nos **3,0 s** seguintes, o escriba não perde vela nem morre (FIDES/Selo de Cera contam como sobrevivida; MISERERE perdoada não conta; fim de onda cancela). Acumulado entre partidas. **10** é o número certo (heresia ficou rara desde a D-100).

Ritmo esperado: Iluminador 3–5 partidas; Beda 2–4; Tomé 2–4; Hildegarda pela habilidade.

## Aceites (sonda `char=<id>`, linha CHAR, bateria `heresy=N`)
C1 onda 1 sem god: Anselmo 5/5, demais ≥ 4/5 · C2 onda 9 sem god: derrota 3/3, tempo vivo ≤ 1,5× o Anselmo · C3 Tomé na onda 5 sem god ≥ 0,75× o Anselmo · C4 palavras/min de cada um entre 0,75× e 1,35× o Anselmo · C5 Iluminador menus/min 1,15–1,35× · C6 Beda letras conjuradas/min ≤ 1,15× · C7 Hildegarda combos 1,3–2,5× · C8 nível final 15–17 · C9 tinta 80–100, compras 6–8 · C10 mortes/min ≤ 1,25× a mediana · C11 Tomé 0 s atordoado · C12 `heresy=20`: 50–90% sobrevividas.

## Dados novos
- `PlayerData`: `start_potions: Dictionary[StringName,int]` (sai do `potions.tres` `start`), `word_guard_slots` (1–2), `double_letter_chance`, `heresy_stun_mul` (hoje fixos no `run_stats.gd`), `unlock: UnlockData`.
- `UnlockData`: `kind` (none/chapter_won/heresy_survived/codex_count), `target`, `ids`, `threshold`, `window`.
  - Hildegarda: chapter_won chapter_1 1 · Tomé: heresy_survived 10 (3,0 s) · Iluminador: codex_count combos 3 · Beda: codex_count words (lux pax crux vita aqua ignis mortis) 7.
- Desbloqueio retroativo; o anúncio no fim da partida.
- **Guarda dupla:** a pronta vai ao 1º espaço livre; com os 2 cheios fica no atril; Espaço com atril vazio/pela metade conjura a mais antiga (FIFO); parceira no atril forma combo com a mais antiga parceira; LUX+LUX não é combo.

## Ressalvas
- **R1 (bloqueia):** a sonda, o stress e o debug gravam no Grimório real (`Codex.persist` só desliga no GUT); com o desbloqueio pelo Grimório, a sonda liberaria escribas. Desligar o save fora do jogo de verdade.
- **R2 (bloqueia):** a game bible §3.11/§3.6 contradiz a D-101; emendar antes da spec.
- R3 Tomé e golpe forte · R4/R5 Bíblia e Turíbulo sem medição da onda 1 sem god · R6 relíquias × palavras (T1900).

## Perguntas
P1 Tomé com 2 velas (custo) + Óleo ×2 · P2 Hildegarda: duas guardadas parceiras com atril vazio fazem o combo · P3 emendar a bible antes · P4 Iluminador 0,24 · P5 confirmar o desbloqueio misto (6b).
