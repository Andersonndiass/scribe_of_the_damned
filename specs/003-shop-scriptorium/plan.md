# 003 — Plano

## Arquitetura

- **RunStats** (`src/core/run_stats.gd`, RefCounted, em `GameState.run_stats`): criado no `start_run` a partir do `PlayerData`. Guarda a base e os *modifiers* comprados e expõe os valores finais: `move_speed`, `attack_interval`, `magnet_radius`, `atril_capacity`, `max_candles`, `target_bonus_add`, `double_letter_chance`, `heresy_stun_mul`, `gold_mul`. Cada item soma no seu campo, com o teto do `.tres`. Lógica pura, testável.
- **Leitores passam a usar o RunStats** (hoje leem o `PlayerData`): `Player.move`, `AutoAttack`, `LetterField` (ímã, capacidade do atril, bônus da letra-alvo, letra dupla), `GoldInkField` (ímã e ×tinta), `Caster` (stun da heresia) e `PlayerVitals` (vela máxima). Sem item comprado, os valores são os de hoje: os testes existentes continuam valendo.
- **ShopOffer** (`src/shop/shop_offer.gd`, RefCounted): sorteia a oferta (3 itens + 1 vaga de apócrifo), calcula preço por onda, reroll, trava e compra. Recebe `rng`, baralho, RunStats e palavras liberadas; não conhece nós.
- **Shop** (`src/shop/shop.gd`): liga o ShopOffer ao jogo — cobra a tinta, aplica o item no RunStats (e nos sistemas vivos: atril, velas) ou libera o apócrifo, emite os sinais.
- **ShopScreen** (`src/ui/shop/shop_screen.gd` + `.tscn`, CanvasLayer, `process_mode = ALWAYS`): a tela da ficha 28 desenhada em código com PixelFont e os ícones 24×24; estados da carta; teclado (FR-314).
- **Fluxo** (`main.gd`): `wave_ended` → dízimo (+4, com ×Bolsa) → espera a tinta voar (`open_delay`) → pausa a árvore e abre a loja → Enter fecha → próxima onda. Depois da última onda: loja → `chapter_completed` (o chefe entra aqui na 006).
- **Letra dupla:** no `LetterField._on_enemy_killed`, com a chance do RunStats, um segundo `dropper.roll` independente cai ao lado.

## Arquivos

```
src/core/run_stats.gd · src/data/shop_item_data.gd · src/data/shop_tuning.gd
src/shop/shop_offer.gd · src/shop/shop.gd
src/ui/shop/shop_screen.gd · src/ui/shop/shop_screen.tscn
data/shop/shop_tuning.tres · data/shop/items/*.tres (9 itens + 5 apócrifos)
tools/gen_placeholders.gd (ícones ITM_ 24×24 e o escriba sentado)
tests/unit/test_run_stats.gd · test_shop_offer.gd · tests/integration/test_shop_flow.gd
```

## Riscos

| Risco | Mitigação |
|---|---|
| Trocar PlayerData por RunStats quebra algo | sem item comprado os valores são idênticos; a suíte atual cobre |
| Pausa da árvore congela a tinta voando | a loja só abre depois do `open_delay`; a tela roda em `ALWAYS` |
| Economia errada | sonda de balanceamento compra cartas (SC-306) antes de fechar |
