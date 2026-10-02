class_name PlayerData
extends Resource
## Números base de um personagem jogável (data-model §1).
## Na feature 003 o RunStats passa a ser a fonte lida em runtime; este Resource vira a base.

@export var id: StringName = &""
@export_group("Escriba (010)")
## Nome próprio (não traduz) e a passiva (chave).
@export var display_name: String = ""
@export var passive_key: StringName = &""
## Quem fala nas falas da partida e nos closes (barks.json, speakers.json).
@export var speaker_id: StringName = &""
## Abertura própria (D-101 7b); vazio = as do capítulo (Anselmo).
@export var intro_cutscene: StringName = &""
@export var sprite_frames: SpriteFrames
## Guarda de palavra (Hildegarda: 2; D-101).
@export_range(1, 2) var word_guard_slots: int = 1
## Poções iniciais (id → cargas); vazio = PotionTuning.start.
@export var start_potions: Dictionary[StringName, int] = {}
## Passivas que o RunStats semeia (T1000): letra dupla (Iluminador) e atordoamento da heresia (Tomé).
@export var double_letter_chance: float = 0.0
@export var heresy_stun_mul: float = 1.0
## null = livre (Anselmo).
@export var unlock: UnlockData
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
