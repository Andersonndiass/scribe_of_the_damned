class_name ArsenalTuning
extends Resource
## Inventário de armas (017 FR-1701; animation-agent T1700).

## Espaços no inventário.
@export var slots: int = 2
## "Saque" ao trocar de arma: a arma nova só ataca depois disto (a recarga dela seguiu correndo).
@export var swap_draw_time: float = 0.1
## Lista explícita (o build web não lista pastas).
@export var weapons: Array[WeaponData] = []
## D-098 (T1830 §2.4): limites de qualquer arma com todos os atributos no teto.
@export var max_count: int = 6
@export var min_interval: float = 0.40
@export var min_beam_interval: float = 0.29
@export var min_slow_factor: float = 0.75
## Lentidão de arma no campeão vale a metade (o chefe é imune).
@export var champion_slow_mul: float = 0.5
