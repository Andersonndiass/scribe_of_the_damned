class_name ShopTuning
extends Resource
## Números da loja (003 data-model §2, rules-agent; D-058).

## As 14 cartas (9 itens + 5 apócrifos). Lista explícita: o build web não lista pastas.
@export var deck: Array[ShopItemData] = []
## Itens por oferta, mais a vaga fixa de apócrifo (se ainda houver apócrifo a liberar).
@export var item_slots: int = 3
@export var apocrypha_slot: bool = true
## Preço = roundi(base × (1 + price_growth × (onda − 1))).
@export var price_growth: float = 0.10
## Reroll: reroll_base, + reroll_step a cada reroll na mesma visita.
@export var reroll_base: int = 5
@export var reroll_step: int = 3
@export var max_locks: int = 1
## Dízimo: tinta dada ao fim de cada onda concluída (× Bolsa do Esmoler).
@export var wave_clear_ink: int = 4
## Espera depois do fim da onda para a tinta que sobrou voar até o escriba.
@export var open_delay: float = 1.0
## Círio Bento no teto: velas acesas por compra.
@export var heal_only_candles: int = 1
