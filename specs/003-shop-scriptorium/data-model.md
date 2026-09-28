# 003 — Modelo de dados

Valores do parecer do rules-agent (2026-09-28), aprovados na D-058.

## 1. `ShopItemData` — `data/shop/items/<id>.tres`

| Campo | Tipo | Nota |
|---|---|---|
| `id` | StringName | |
| `kind` | StringName | `&"item"` ou `&"apocrypha"` |
| `display_name` | String | nome na carta (PT) |
| `short_desc` | String | efeito em uma linha |
| `base_price` | int | |
| `icon` | Texture2D | ITM_ 24×24 (placeholder por script) |
| `stat` | StringName | campo do RunStats (itens) |
| `amount` | float | o que soma (ou multiplica, se `multiplicative`) |
| `multiplicative` | bool | Pena de Ganso |
| `cap` | float | teto do campo |
| `max_buys` | int | 0 = sem limite (Rosário: 1) |
| `after_cap` | StringName | Círio: `&"heal_only"` |
| `word` | WordData | apócrifos |

| Item | Preço | stat | amount | Teto |
|---|---|---|---|---|
| Pedra-Ímã | 4 | `magnet_radius` | +30% da base | +150% |
| Rosário de Contas | 4 | `heresy_stun_mul` | ×0,5 | 1 compra |
| Sandálias do Peregrino | 5 | `move_speed` | +10% da base | +50% |
| Bolsa do Esmoler | 5 | `gold_mul` | +0,20 | +0,60 |
| Lentes do Copista | 6 | `target_bonus_add` | +3 | +9 |
| Tinteiro Duplo | 7 | `double_letter_chance` | +0,10 | 0,50 |
| Pena de Ganso Fina | 8 | `attack_interval` | ×0,85 | mínimo 0,40 s |
| Círio Bento | 8 | `max_candles` | +1 e acende 1 | 8 (depois só acende 1) |
| Estante Nova | 9 | `atril_capacity` | +1 | 8 |

| Apócrifo | Preço |
|---|---|
| PURGO | 5 |
| FIDES | 6 |
| LUMEN | 7 |
| GLORIA | 9 |
| VERBUM | 10 |

## 2. `ShopTuning` — `data/shop/shop_tuning.tres`

| Campo | Valor |
|---|---|
| `item_slots` | 3 |
| `apocrypha_slot` | true |
| `price_growth` | 0.10 por onda |
| `reroll_base` / `reroll_step` | 5 / 3 |
| `max_locks` | 1 |
| `wave_clear_ink` | 4 |
| `open_delay` | 1.0 s (a tinta que sobrou voa antes) |

## 3. Estado em runtime

- `GameState.run_stats: RunStats` (zera no `start_run`); `GameState.gold_ink` (já existe).
- `ShopOffer`: `cards` (4), `sold` (máscara), `locked_id` + `locked_price`, `rerolls_this_visit`.

## 4. EventBus (sinais novos)

| Sinal | Parâmetros |
|---|---|
| `shop_opened` | `wave: int` |
| `shop_closed` | — |
| `item_bought` | `item: ShopItemData, price: int` |
| `shop_rerolled` | `cost: int` |
