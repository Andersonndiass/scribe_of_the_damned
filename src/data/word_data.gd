class_name WordData
extends Resource
## Uma palavra conjurável e os parâmetros do seu milagre (data-model §2).
## Campos não usados por uma palavra ficam em 0/false.

@export var id: StringName = &""
@export var latin: String = ""
@export var translation_key: StringName = &""
## Cresce estritamente com o tamanho da palavra (FR-018, test_word_power).
@export var power_budget: float = 1.0
## &"base", &"apocrypha" ou &"oration" (002 FR-201).
@export var group: StringName = &"base"
## Apócrifos: só valem depois de GameState.unlock_word (loja, 003).
@export var requires_unlock: bool = false
## false para GLORIA e PURGO (FR-204).
@export var combo_eligible: bool = true
@export var miracle_scene: PackedScene
@export_group("Parâmetros do milagre")
@export var damage: float = 0.0
@export var tick_interval: float = 0.0
@export var radius: float = 0.0
@export var length: float = 0.0
@export var duration: float = 0.0
@export var stun: float = 0.0
@export var knockback: float = 0.0
@export_range(0.0, 1.0) var slow_factor: float = 0.0
@export var heal_candles: int = 0
@export var kill_hp_threshold: int = 0
@export var blocks_projectiles: bool = false
## Largura (px) de braços/feixes (CRUX).
@export var width: float = 0.0
## Raio (px) ao redor do centro em que projéteis são bloqueados (CRUX, parecer rules-agent 005).
@export var block_radius: float = 0.0
@export_group("Apócrifos e orações (002)")
## GLORIA: multiplicador de dano/cura dos milagres durante o efeito.
@export var buff_mul: float = 1.0
## LUMEN: multiplicadores do ímã e do bônus da letra-alvo.
@export var magnet_mul: float = 1.0
@export var target_weight_mul: float = 1.0
## FIDES: golpes absorvidos pelo escudo.
@export var charges: int = 0
## Efeitos de tela inteira em lotes (SC-202).
@export var kill_batch_per_frame: int = 30
## Réquiem/MISERERE: teto de letras garantidas por conjuração.
@export var guaranteed_drop_cap: int = 0
## ANGELUS, Martírio: intervalo mínimo entre acertos no mesmo inimigo.
@export var hit_cooldown: float = 0.0
## ANGELUS: quantos objetos orbitam o escriba.
@export var orbit_count: int = 0
## Martírio, ANGELUS: voltas por segundo do que gira em volta do escriba.
@export var rotation_speed: float = 0.0
## SPIRITUS: multiplicador de velocidade do escriba.
@export var speed_mul: float = 1.0
## SALVATOR: apaga os projéteis inimigos da tela.
@export var clear_projectiles: bool = false
## MISERERE: perdoa a próxima heresia.
@export var forgive_heresy: bool = false
@export_group("Arte")
@export var vfx_prefix: StringName = &""
## Desenhar abaixo das letras do chão, no FxLayer (Vapor, Flamma, Grandes Orações; design-agent).
@export var draw_below_world: bool = false
