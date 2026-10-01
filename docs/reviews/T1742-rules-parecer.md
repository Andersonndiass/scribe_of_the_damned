# T1742 — Parecer do rules-agent: sonda por arma e por onda (SC-1704)

> 2026-10-01 · **VÁLIDO COM RESSALVAS. SC-1704: AJUSTAR** (aplicado em seguida; ver "Depois do ajuste").
> Sonda: `tools/balance_probe.gd -- cast [god] wave=N weapons=<arma> wlevel=N`; bot que foge, responde ao menu em 0,8 s e acerta a letra útil com p = 0,9. Arma sozinha, sem selos nem loja. 1 rodada por célula (ruído alto).

## Medição (antes do ajuste)
| Arma | Onda 1 nv 1 (god) | Onda 1 sem god | Onda 5 nv 3 | Onda 9 nv 5 |
|---|---|---|---|---|
| Pena | 21 mortes/min, 1 menu/min | morreu 52 s | 71 | 170 |
| Bíblia | 70, 5 menus/min | venceu | 133 | 203 |
| Crucifixo | 46 | morreu 43 s | 70 (após a correção do float32) | 152 |
| Rosário | 25 | morreu 46 s | 110 | 150 |
| Turíbulo | 60 | venceu | 129 | 192 |
| Aspersório | 34 | morreu 54 s | 82 | 153 |

## 1. Veredito
- **Palavras/min:** 0,67–1,5 onde há menus (alvo 0,8–1,3), mas a medida é grossa (1–2 palavras por rodada): precisa de ≥3 rodadas ou do capítulo inteiro.
- **"As armas fecham as ondas":** passa nas ondas 5 e 9; **falha na onda 1 com a Pena** (arma inicial): morre aos 52 s e dá ~1 menu/min. A onda 1 solta ~2,5 HP/s; a Pena nv 1 dá 1,25 de DPS nominal (~0,7 efetivo). Isso quebra a premissa de 2 níveis de Graça na onda 1.
- **"Nenhuma arma domina":** falha nas ondas 1 e 5 (Bíblia 1,75× e 1,39× a mediana; Turíbulo 1,5× e 1,34×; teto 1,25×).
- **Viés:** a sonda foge — favorece raio e rastro (Bíblia, Turíbulo) e pune as armas de perto (Rosário, Aspersório).

## 2. Alavancas aplicadas
| Item | Antes | Depois |
|---|---|---|
| Pena contas/intervalo nv 1…5 | 1/0,80 · 1/0,70 · 2/0,70 · 2/0,60 · 3/0,60 | **2/0,80 · 2/0,70 · 2/0,60 · 3/0,60 · 3/0,55** |
| Onda 1 `Group_late.spawn_rate_end` | 2,0 | **1,6** |
| Onda 1 `letter_drop_mul` | 1,00 | **1,20** |
| Rosário nv 1 contas/raio | 2/32 | **3/36** |
| Rosário raio nv 2…5 | 32/40/40/40 | **40/44/44/44** |
| Bíblia tick nv 1/2/3 | 0,60/0,50/0,50 | **0,70/0,60/0,55** |
| Turíbulo rastro nv 1/2/3 | 1,5/2,5/2,5 | **1,0/1,5/2,0** |

- Graça esperada na onda 1 com a Pena nova: ~42 mortes × 2 + ~3,5 letras × 10 ≈ 120 ≥ 104 (2 níveis).
- Reserva (não aplicada): `level_base` da Graça 40 → 30 se a Pena ainda morrer na onda 1.
- `precision_mul` 1,5 da Bíblia mantida (D-087).

## 3. Aceite do ajuste
A Pena vence a onda 1 sem god em pelo menos 2 de 3 rodadas; nenhuma arma acima de 1,25× a mediana (3 rodadas por célula).

## 4. Para a passada de ritmo (018)
- Sonda: modo "manter distância = alcance da arma"; ≥3 rodadas ou capítulo inteiro; onda 9 sem god começando do zero (derrota esperada); tempo do campeão (4–15 s).
- Onda 9: 4–4,7 menus/min (alvo 5) → talvez `letter_drop_mul` 0,38 → 0,45 depois de medir.
- Crucifixo nv 1 morreu aos 43 s: o projétil a 360 px/s erra demais? Revisar o salto dos níveis 2–4 depois da correção.
- Aspersório: velocidade 240 px/s sem parecer (D-092); alcance 64 contra a fuga.
- Pena: eficiência ~0,56 (alcance 160 contra a fuga).
- Chefe 3–4 min; banco da arena (D-089); "nv 5 na arma ativa nas ondas 7–9" com selos e loja de verdade.

## Depois do ajuste
Sonda de 3 rodadas por célula (2026-10-01):

| Caso | Mortes/min | Sobreviveu (sem god) | Menus/min |
|---|---|---|---|
| Pena onda 1 nv 1 | 52 / 55 / 56 | 3 de 3 ✅ | 1–10 (média ~4) |
| Rosário onda 1 nv 1 | 27 / 18 / 23 | 2 de 3 | 0–3,5 |
| Bíblia onda 1 nv 1 (god) | 59 / 59 / 63 | — | 6 |
| Turíbulo onda 1 nv 1 (god) | 52 / 50 / 50 | — | 2–5 |
| Bíblia onda 5 nv 3 (god) | 133 ×3 (mata tudo o que a onda solta) | — | 3–4,5 |
| Turíbulo onda 5 nv 3 (god) | 122 / 127 / 127 | — | 3–8 |

- **Aceite:** a Pena vence a onda 1 (3/3) ✅; na onda 1 ninguém passa de 1,25× a mediana (Bíblia 1,18×) ✅; na onda 5 a Bíblia e o Turíbulo batem no teto da onda (a medida satura).
- **Fica para a passada de ritmo:** o Rosário nv 1 continua abaixo da Pena nova (~23 contra ~54); os menus/min variam muito por rodada.
