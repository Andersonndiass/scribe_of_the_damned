class_name PlayerData
extends Resource
## Números base de um personagem jogável (data-model §1).
## Na feature 003 o RunStats passa a ser a fonte lida em runtime; este Resource vira a base.

@export var id: StringName = &""
@export_group("Movimento")
@export var move_speed: float = 90.0
@export_group("Ataque automático")
## Arma inicial (017; o ataque automático antigo virou a Pena do Copista em dados).
@export var start_weapon: WeaponData
@export var attack_interval: float = 0.8
@export var attack_range: float = 160.0
@export var projectile_speed: float = 220.0
@export var projectile_damage: int = 1
@export_group("Velas")
@export_range(1, 8) var start_candles: int = 3
@export_range(1, 8) var max_candles: int = 8
@export var iframes: float = 1.0
@export var idle_regen_delay: float = 5.0
@export var idle_regen_interval: float = 3.0
@export_group("Coleta")
@export var magnet_radius: float = 40.0
@export_range(3, 8) var atril_capacity: int = 5
@export var hurtbox_radius: float = 5.0
