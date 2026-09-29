# 003 — Tarefas

## Fase 1 — Lógica
- ✅ **T300** [TEST-FIRST] `test_run_stats.gd` → `RunStats`: base = PlayerData, soma e multiplica com teto, Círio no teto só cura, Rosário 1 compra.
- ✅ **T301** `ShopItemData`, `ShopTuning` e os 14 `.tres` (9 itens + 5 apócrifos).
- ✅ **T302** [TEST-FIRST] `test_shop_offer.gd` → `ShopOffer`: 3 itens + 1 apócrifo, mesma seed = mesma oferta (SC-301), teto tira do baralho (SC-302), preço por onda, trava pelo preço antigo através do reroll e da onda (SC-304), reroll 5 +3, compra sem tinta não faz nada.
- ✅ **T303** Leitores no RunStats: movimento, ataque, ímã (letras e tinta), atril, velas, bônus da letra-alvo, stun da heresia, ×tinta; letra dupla como 2º sorteio independente.
- ✅ **T304** Fluxo: dízimo no fim da onda, loja entre as ondas e depois da última, `Shop` aplicando compras (apócrifo libera a palavra na hora, SC-303).

**Checkpoint 003-A:** ✅ a loja funciona por código e por teste, sem tela (2026-09-28, GUT 245/245). Fora do jogo de verdade (testes, sonda, stress) a loja abre e fecha sozinha (`shop_auto_close`).

## Fase 2 — Tela
- ✅ **T310** Placeholders por script (ficha 31/28): 14 ícones 24×24 e o escriba sentado (6 quadros). Parecer do design-agent antes.
- ✅ **T311** `ShopScreen`: cartas (8 estados), contador de tinta, reroll, trava, fita da próxima onda; teclado (FR-314). Tempos pelo animation-agent.
- ✅ **T312** Integração `test_shop_flow.gd`: onda → loja → compra/trava/reroll só no teclado → próxima onda (SC-305).

**Checkpoint 003-B:** ✅ a loja jogável entre as ondas (2026-09-28, GUT 250/250; conferida no Chrome com `index.html?shop`).

## Fase 3 — Fechamento
- ✅ **T320** Sonda de balanceamento: o bot compra na loja; ~5 cartas no Cap. 1 (SC-306).
- ✅ **T321** GUT, export web, SC-001/SC-503 (SC-307), `FEATURES.md`, `CLAUDE.md`, `docs/DECISIONS.md`.
