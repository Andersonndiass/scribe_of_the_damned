class_name EnemyData
extends Resource
## Dados de um tipo de inimigo comum (data-model §4).

@export var id: StringName = &""
@export var max_hp: int = 1
@export var move_speed: float = 40.0
@export var radius: float = 5.0
## Nível de dano de contato: 1 = fraco, 2 = forte (D-012).
@export_range(1, 2) var contact_damage: int = 1
@export var separation_weight: float = 1.0
## Comportamento stateless (005 FR-501). Nulo = perseguir (ChaseBehavior).
@export var behavior: EnemyBehavior
## Voa: ignora obstáculos (Traça).
@export var flying: bool = false
## Dano de contato durante o dash (Gárgula: 2 = forte). 0 = usa contact_damage.
@export_range(0, 2) var dash_contact_damage: int = 0
@export var telegraph_time: float = 0.5
@export_range(0.0, 1.0) var letter_drop_chance: float = 0.5
@export var sprite_frames: SpriteFrames
## Pivot do sprite em pixels (base-centro), da ficha. Ex.: Diabrete (6,11).
@export var sprite_pivot: Vector2 = Vector2(6, 11)
## Tamanho da dissolução (art bible §6.1): 12, 16 ou 24.
@export var dissolve_size: int = 12
