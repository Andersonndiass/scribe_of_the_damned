# T1801 — Parecer do rules-agent: 018 Poções, curva da Graça, banco e passada de ritmo

> 2026-10-01 · **VÁLIDO COM RESSALVAS.** [P?] = decisão do autor.

## 1. Poções (3 níveis cada)
Comum: intervalo mínimo entre poções **1,5 s** (tempo de jogo); a mesma poção renova a duração; o nível vale para a run inteira.

| Poção | nv 1 | nv 2 | nv 3 | Teto de cargas | Preço base |
|---|---|---|---|---|---|
| Óleo da Unção | 1 vela | 1 vela + 1,0 s invulnerável | 1 vela + 1,5 s invulnerável | 2 | 3 |
| Água Benta | raio 32, 3 s | raio 40, 4 s | raio 48, 5 s | 2 | 4 |
| Vinho do Fervor | intervalo ×0,80, 8 s | ×0,75, 10 s | ×0,70, 12 s | 2 | 4 |
| Tinta Iluminada | 1 menu (1 útil em 3) | [P?] 2 úteis em 3 | [P?] 3 úteis em 3 | 1 | 6 |

- **Óleo < VITA:** o VITA também acende 1 vela. **[P?] Recomendado:** VITA `heal_candles` 1 → 2 (ultimate; SALVATOR continua 3). Alternativa: o Óleo acende a vela depois de 0,75 s e os níveis só dão invulnerabilidade.
- **Água Benta:** fixa onde foi usada; comuns e campeões não entram; quem estava dentro vai para a borda, sem dano; projéteis passam; o chefe ignora; heresia dentro apaga; parado dentro não conta para recuperar vela.
- **Vinho:** só a arma ativa; com a Pena de Ganso, o produto não desce de **0,55**; vale para o tick da Bíblia e a volta do Rosário (o 0,4 s do Rosário continua).
- **Iluminura:** 1 letra por carga, teto 1 (≤ ~1 letra extra por onda); bloqueada com menu aberto ou fila cheia (não gasta); conta para a LetterSafety. Alternativa para nv 2–3: chance de rara 0,25/0,50.
- Preços crescem com `price_growth` 0,1 (onda 8: 5/7/7/10). Começa com 1 Óleo (conta como comprada).

## 2. Selo de poção
Pesos: arma ativa 0,30 · reserva 0,15 · status **0,37** · ímã 0,10 · **poção 0,08**. Só poções compradas abaixo do nv 3; nunca dá carga (~4 selos de poção no capítulo).

## 3. Curva da Graça (pedido do autor D-094)
`level_costs = [16, 40]`, `level_base` **8**, `level_step` **28** → 16, 40, 64, 92, 120, … 456. Até o nível 18: 3956 (hoje 3944).
1º nível aos **~15–16 s** da onda 1 (hoje ~33 s); 2º aos ~40 s; 2–3 níveis na onda 1. Alavanca: `level_costs[0]` 16 → 12 (~14 s). Code: `GraceTuning.validate()` não checa `level_costs[0]`.

## 4. Banco (o6)
(104, 328) → **(184, 272)**: parede de baixo 56, esquerda 160 (≥ 40); furo o2 a 96 px na mesma linha; fora dos retângulos do HUD (26 px acima do atril), fora do painel das poções (x ≤ 168), antes do atril (x ≥ 252); corredor de 56 px sob o banco (sem fresta de dash). Aceite: STUCK ≤ 5%; letras/min com banco ≥ 50% sem ele; média ±20%.

## 5. Passada de ritmo (lista fechada)
Sonda nova: distância = alcance da arma; ≥ 3 rodadas; capítulo inteiro com selos e loja.

| # | Medida | Aceite |
|---|---|---|
| 1 | Palavras/min no capítulo | 0,8–1,3 |
| 2 | Menus/min por onda | 5,0–6,5; onda 9 ≥ 4,5 (alavanca 0,38 → 0,45) |
| 3 | 1º nível da onda 1 | 12–20 s |
| 4 | Níveis na onda 1 | 2–3 |
| 5 | Níveis na onda 9 | 1–2 |
| 6 | Nível final | 16–20 |
| 7 | Arma ativa nv 5 | até a onda 7 em ≥ 2/3 |
| 8 | Onda 1 sem god | Pena 3/3; Crucifixo, Rosário, Aspersório nv 1 ≥ 2/3 |
| 9 | Onda 9 sem god do zero | derrota 3/3 |
| 10 | Mortes/min por arma (1, 5, 9) | ≤ 1,25× a mediana; Rosário nv 1 ≥ 0,8× a Pena |
| 11 | Crucifixo nv 1→4 | cresce a cada nível |
| 12 | Eficiência da Pena | ≥ 0,65 |
| 13 | Aspersório (240 px/s) | acerto ≥ 0,65 |
| 14 | Campeão | 4–15 s |
| 15 | Tinta no capítulo | 82 ± 15% |
| 16 | Compras de arma e apócrifo | 6–8 |
| 17 | Gasto em poções | ≤ 40% da tinta |
| 18 | Letras da Iluminura | ≤ 10% |
| 19 | Vinho | piso 0,55 nunca furado |
| 20 | Água Benta | 0 comuns dentro |
| 21 | Banco | faixas do §4 |
| 22 | Desempenho | SC-001 e `?stress=arsenal` sem regressão |

Fora: vida do Asmodeus (C-006), sonda do chefe (D-081), Firefox, armas/inimigos/ondas novos.
