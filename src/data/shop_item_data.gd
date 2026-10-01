class_name ShopItemData
extends StatUpgradeData
## Uma carta da loja (003 data-model §1): item que mexe no RunStats ou apócrifo que libera a
## palavra (D-017). Todo número mora aqui (Princípio IV). Os campos de número (stat, modo, valor,
## teto, cura) vêm de StatUpgradeData (016).

## &"item", &"apocrypha", &"weapon" (017: entra no inventário) ou &"passive" (017: ímã reverso).
@export var kind: StringName = &"item"
@export var base_price: int = 5
@export_group("Item")
## 0 = sem limite (Rosário: 1).
@export var max_buys: int = 0
## Círio: &"heal_only" = no teto continua à venda e só acende 1 vela.
@export var after_cap: StringName = &""
@export_group("Apócrifo")
@export var word: WordData
@export_group("Arma e passivo (017)")
@export var weapon: WeaponData
## Passivo: id do que a compra liga (hoje só &"reverse_magnet").
@export var passive: StringName = &""
