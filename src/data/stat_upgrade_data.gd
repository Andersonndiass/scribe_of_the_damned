class_name StatUpgradeData
extends Resource
## Melhoria de número da partida (016 FR-1612): base comum das cartas da loja (ShopItemData) e das
## bênçãos do level-up (BlessingData). Aplicada no RunStats e nos sistemas vivos por RunUpgrade.

@export var id: StringName = &""
## Chaves de `tr()` (i18n/ui.csv).
@export var display_name: String = ""
@export var short_desc: String = ""
## ITM_ 24×24 (placeholder por script até a arte final).
@export var icon: Texture2D
## Campo do RunStats que a melhoria mexe (vazio = só cura, como a Graça plena).
@export var stat: StringName = &""
## &"percent" (+amount × base), &"add" (+amount) ou &"mul" (× amount).
@export var mode: StringName = &"add"
@export var amount: float = 0.0
## Valor final máximo (ou mínimo, para `mul` que reduz).
@export var cap: float = 0.0
## Velas que acende ao aplicar (Círio Bento, Graça plena). Estava fixo no código da loja.
@export var heal_candles: int = 0
