class_name DropTuning
extends Resource
## Ajustes de letras e heresia (data-model §7). As letras do chão saíram na 017 (menu da letra):
## `target_bonus` só vale para o LetterDropper (sorteio ponderado antigo, ainda usado em testes).

@export var base_weights: Dictionary[String, float] = {}
@export var target_bonus: float = 6.0
@export_range(0.0, 1.0) var rare_chance: float = 0.05
@export var rare_power_bonus: float = 1.5
@export_group("Heresia")
@export var heresy_stun: float = 0.5
@export var heresy_pool_time: float = 2.0
@export var heresy_pool_radius: float = 64.0
@export_group("HUD")
@export var hint_count: int = 3
