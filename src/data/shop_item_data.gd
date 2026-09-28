class_name ShopItemData
extends Resource
## Uma carta da loja (003 data-model §1): item que mexe no RunStats ou apócrifo que libera a
## palavra (D-017). Todo número mora aqui (Princípio IV).

@export var id: StringName = &""
## &"item" ou &"apocrypha".
@export var kind: StringName = &"item"
@export var display_name: String = ""
@export var short_desc: String = ""
@export var base_price: int = 5
## ITM_ 24×24 (placeholder por script até a arte final).
@export var icon: Texture2D
@export_group("Item")
## Campo do RunStats que o item mexe.
@export var stat: StringName = &""
## &"percent" (+amount × base), &"add" (+amount) ou &"mul" (× amount).
@export var mode: StringName = &"add"
@export var amount: float = 0.0
## Valor final máximo (ou mínimo, para `mul` que reduz).
@export var cap: float = 0.0
## 0 = sem limite (Rosário: 1).
@export var max_buys: int = 0
## Círio: &"heal_only" = no teto continua à venda e só acende 1 vela.
@export var after_cap: StringName = &""
@export_group("Apócrifo")
@export var word: WordData
