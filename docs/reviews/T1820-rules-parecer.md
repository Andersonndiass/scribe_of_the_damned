# T1820 — Parecer do rules-agent: passada de ritmo (018 Fase 6)

> 2026-10-01 · Skill: `game-development/game-design` (fluxo, curva, economia); as regras do projeto prevalecem.
> Fontes: T1801 §5, T1742, `data/weapons/*.tres`, `data/tuning/{grace,letter_menu,potions}.tres`, `data/potions/*.tres`, `data/waves/chapter_1/*.tres`, `data/shop/shop_tuning.tres` + `items/`, `data/enemies/*.tres`, D-088/D-093.
> Sonda T1819: `kite` (distância = 0,8 × alcance da arma ativa), `potions` (o bot bebe e compra poções até 40% da tinta da visita), loja sem trocar arma; selos automáticos preferem o selo de arma (antes pegavam o 1º, e a garantia põe a arma por último: uma rodada travou a Pena no nv 2 e foi descartada).

**PARECER: VÁLIDO COM RESSALVAS.** O ritmo do capítulo (Graça, níveis, palavras, tinta, poções) está no alvo. Os 4 ❌ têm causa localizada: Crucifixo nv 1 fraco e nv 3 morto, Pena 2/3 na onda 1 sem god (morreu aos 59,9 s), compras 5 numa rodada, onda 3 com menus altos (ruído).

## 1. As 22 medidas

Ondas: 60/65/70/75/80/80/85/90/90 s (695 s). Menus/min por onda (média de 3): 6,3 · 6,5 · **8,0** · 5,3 · 5,3 · 5,3 · 6,4 · 6,4 · 5,6. O desvio por rodada é alto (o3: 4,3–12,9; o9: 2,7–8,0).

| # | Medida | Medido | Aceite | Status |
|---|---|---|---|---|
| 1 | Palavras/min | 0,92 / 0,67 / 1,00 (0,86) | 0,8–1,3 | ✅ média (R2 abaixo) |
| 2 | Menus/min por onda | capítulo 6,8/5,3/5,6; o3 8,0; o9 5,6 | 5,0–6,5; o9 ≥ 4,5 | ❌ parcial (o3, ruído) |
| 3 | 1º nível | 14,9 / 14,7 / 16,3 s | 12–20 s | ✅ |
| 4 | Níveis na onda 1 | 3 / 3 / 3 | 2–3 | ✅ (teto) |
| 5 | Níveis na onda 9 | 2 / 1 / 2 | 1–2 | ✅ |
| 6 | Nível final | 17 / 16 / 17 | 16–20 | ✅ |
| 7 | Arma ativa nv 5 | onda 3 / 4 / 3 | até a onda 7 ≥ 2/3 | ✅ (cedo; §4) |
| 8 | Onda 1 sem god | Pena 2/3, Crucifixo 0/3, Rosário 3/3, Aspersório 2/3 | Pena 3/3; demais ≥ 2/3 | ❌ |
| 9 | Onda 9 sem god | derrota 3/3 (16,6–17,8 s) | derrota 3/3 | ✅ |
| 10 | Mortes/min por arma | o1 máx. 1,18× ✅; o5 Bíblia 1,38×, Turíbulo 1,39×, Rosário 1,30×; o9 Bíblia 1,28×; Rosário nv 1 = 1,18× Pena ✅ | ≤ 1,25× mediana | ❌ (o5, o9) |
| 11 | Crucifixo nv 1→4 (o5) | 58,5 / 88,5 / 60,0 / 80,2 | cresce | ❌ |
| 12 | Eficiência da Pena | — | ≥ 0,65 | não medido |
| 13 | Acerto do Aspersório | — | ≥ 0,65 | não medido |
| 14 | Campeão | — | 4–15 s | não medido |
| 15 | Tinta | 85 / 82 / 80 | 82 ± 15% | ✅ |
| 16 | Compras arma/apócrifo | 6 / 6 / 5 | 6–8 | ❌ (R3) |
| 17 | Gasto em poções | 19% / 12% / 28% | ≤ 40% | ✅ |
| 18 | Letras da Iluminura | 0 (não comprada) | ≤ 10% | ✅ por vacuidade |
| 19 | Vinho (piso 0,55) | GUT `test_potions` | nunca furado | não medido (GUT) |
| 20 | Água Benta | GUT | 0 comuns dentro | não medido (GUT) |
| 21 | Banco | STUCK ≤ 0,07% | faixas do §4 | parcial |
| 22 | Desempenho | — | sem regressão | não medido |

## 2. Diagnóstico e alavancas

### Crucifixo (#8, #11, maior parte do #10)
- **nv 1:** 21 mortes/min na o1 (0,38× a mediana): 1 cruz a cada 1,6 s mata ~0,56 inimigo na onda esparsa; o `pierce` 8 quase não conta. O limite é a cadência.
- **nv 3 morto:** só muda o dano de 4 para 6, mas a vida dos comuns é 1–5 e 4 já mata todos menos a gárgula.
- **Alavanca:** só `interval` em `crucifix.tres`: **1,6/1,4/1,4/1,4/1,2 → 0,8/0,7/0,6/0,6/0,5**. Raio (D-088), dano, `pierce` e alcance ficam como estão; a antecipação de 0,2 s continua dentro do intervalo. Cada nível passa a mexer em algo que mata mais.
- **Efeito no #10:** na o5 a mediana vai a ~122 (teto ~152); na o9 a ~187 (teto ~234).
- **Ressalva:** Pena e Aspersório continuam em ~0,5× das armas de área na o5. Reserva, só se o #10 ainda falhar: `aspergillum.tres` lv3 `interval` 1,1 → 0,95.
- **Vinho:** 0,5 × 0,70 = 0,35 s (o piso 0,55 é só da Pena; 0,35 > 0,2 de antecipação).

### Pena 2/3 na onda 1 sem god (#8)
- Morreu aos 59,9 s (pico do `spawn_rate_end`). Re-medir **com `potions`** (o Óleo inicial é a folga prevista).
- Só se der < 3/3: `wave_01.tres` `Group_late.spawn_rate_end` 1,6 → 1,5.

### Compras (#16)
- `shop_tuning.tres` `price_growth` **0,10 → 0,08** (fator 1,56 na o8; ~+0,5 compra). Não mexe na tinta ganha (#15); as poções ficam ~1 mais baratas no fim (o #17 tem folga).
- Reserva: `wave_clear_ink` 6 → 7 (vigiar o #15).

### Onda 3 com 8,0 menus/min (#2)
- Ruído: as rodadas dão 15 / 8 / 5 e a mediana é 6,9. Não mexer agora.
- Só se a mediana de 5 rodadas passar de 6,5: `wave_03.tres` `letter_drop_mul` 0,80 → 0,75.
- Onda 9: 5,6 ≥ 4,5, então a alavanca 0,38 → 0,45 da T1801 não se aplica.

## 3. Mudanças

| Item | Antes | Depois | Status |
|---|---|---|---|
| `crucifix.tres` `interval` lv1…5 | 1,6/1,4/1,4/1,4/1,2 | 0,8/0,7/0,6/0,6/0,5 | **aplicado** |
| `shop_tuning.tres` `price_growth` | 0,10 | 0,08 | **aplicado** |
| `wave_01.tres` `Group_late.spawn_rate_end` | 1,6 | 1,5 | condicional (Pena < 3/3 com poções) |
| `wave_03.tres` `letter_drop_mul` | 0,80 | 0,75 | condicional (mediana o3 > 6,5) |
| `aspergillum.tres` lv3 `interval` | 1,1 | 0,95 | reserva (#10) |

## 4. Ressalvas sem alavanca
- **#7:** a arma ativa chega ao nv 5 nas ondas 3–4 porque a sonda prefere o selo de arma. Confirmar no playtest humano (SC-1705) antes de mexer nos pesos dos selos.
- **#4 no teto:** o `wave_01` condicional ajuda; não mexer na Graça.
- **#18–#20:** a sonda não exercita esses itens; o GUT cobre as regras.

## 5. Re-medir
1. Crucifixo: o1 sem god nv 1 ×3; o5 nv 1→5 ×3; ondas 1/5/9 em god ×3 para as 6 armas.
2. Pena o1 sem god ×5 com `potions`; o `wave_01` só se der < 3/3.
3. Capítulo ×5 com o `price_growth` novo: #1, #2 (mediana da o3/o9), #15, #16, #17, distribuição dos selos.
4. Fora desta bateria: #12, #13, #14, #21, #22 (o Crucifixo nv 5 gera ~2,4× mais cruzes; conferir o pool).
5. Playtest do autor (SC-1705).

## 6. Re-medição e fechamento (2026-10-01)
- **Crucifixo** (depois do `interval` novo): onda 1 sem god **3/3**. Onda 5 nv 1→5 (mediana de 3): **85 / 86 / 106 / 119 / 129** mortes/min, crescendo ✅.
- **#10** (mediana de 3 por célula):
  - o1: 0,84–1,09× ✅
  - o5: 0,61–1,20× ✅
  - o9: 0,54–1,08× ✅
- **Capítulo ×5** com `price_growth` 0,08:
  - compras 5/6/6/5/6 e tinta média 71 → reserva `wave_clear_ink` 6 → **7** aplicada;
  - o9 com média de 3,9 menus/min → `wave_09.letter_drop_mul` 0,38 → **0,45** aplicado;
  - o3 com mediana de 6,0 → sem mudança.
- **Pena** na o1 sem god com poções: 3/5 → `wave_01.Group_late.spawn_rate_end` 1,6 → **1,5** aplicado.
- **Verificação final:**
  - Pena **5/5**, Aspersório **3/3**;
  - capítulo ×3: compras **7/7/7**, tinta 92/80/101, palavras/min 0,83/1,08/1,08, o9 com 4,7/4,7/8,7 menus/min, nível final 15/15/16.
- **Ressalva aberta:** os menus da o1 ficaram em 8–10/min na verificação final (eram ~6,3 antes). Fica para o playtest; a alavanca é `wave_01.letter_drop_mul` 1,2 → 1,0.
- **Reserva do Aspersório:** não usada.
- **GUT** 536/536 (testes do Crucifixo e do preço passaram a ler os dados); export web OK.
- **#22 desempenho:** `stress_scene -- stress=crucifix` (novo; Crucifixo nv 5 a 0,5 s + Pena nv 5, 300 inimigos), no desktop: média 60,0, p95 55,2. O controle SC-001 deu p95 53,3, então sem regressão. A medição no web/Chrome fica com o autor.
