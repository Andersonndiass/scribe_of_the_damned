class_name DropTuning
extends Resource
## Ajustes de letras, heresia e purge (data-model §7).

@export var base_weights: Dictionary[String, float] = {}
@export var target_bonus: float = 6.0
@export_range(0.0, 1.0) var rare_chance: float = 0.05
@export var rare_power_bonus: float = 1.5
@export_group("Letras no chão")
@export var letter_lifetime: float = 8.0
@export var blink_time: float = 2.0
## Experimento (C-004): o ímã só puxa letras que continuam uma palavra; as outras, só por toque.
@export var selective_magnet: bool = false
@export_group("Purge")
@export var purge_scatter_radius: float = 20.0
@export var purge_pickup_lock: float = 0.3
@export_group("Heresia")
@export var heresy_stun: float = 0.5
@export var heresy_pool_time: float = 2.0
@export var heresy_pool_radius: float = 64.0
@export_group("HUD")
@export var hint_count: int = 3
