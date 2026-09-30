class_name ArsenalTuning
extends Resource
## Inventário de armas (017 FR-1701; animation-agent T1700).

## Espaços no inventário.
@export var slots: int = 2
## "Saque" ao trocar de arma: a arma nova só ataca depois disto (a recarga dela seguiu correndo).
@export var swap_draw_time: float = 0.1
## Lista explícita (o build web não lista pastas).
@export var weapons: Array[WeaponData] = []
