class_name ChampionTuning
extends Resource
## Multiplicadores e recompensas do campeão (005 data-model §5, ficha 15, D-011).

@export var hp_mul: float = 4.0
@export var speed_mul: float = 1.1
@export var radius_mul: float = 1.5
@export var spawn_telegraph: float = 0.8
@export var gold_drops_min: int = 3
@export var gold_drops_max: int = 5
@export var heal_candles: int = 1
@export var death_hitstop_ms: int = 40
## Shake fraco na morte do campeão (animation-agent, 006): px e s.
@export var death_shake: float = 1.0
@export var death_shake_time: float = 0.2
