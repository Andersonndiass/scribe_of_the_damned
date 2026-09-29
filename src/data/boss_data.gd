class_name BossData
extends Resource
## Um chefe (006 FR-601). Fases em ordem decrescente de limiar.

@export var id: StringName = &""
@export var display_name: String = ""
@export var max_hp: int = 1500
@export var phases: Array[PhaseData] = []
## Raio do corpo (hurtbox e contato).
@export var body_radius: float = 20.0
## Dano de contato (2 = forte).
@export var contact_damage: int = 2
## Velocidade de deslocamento na metade de cima da página.
@export var move_speed: float = 20.0
## Telegrafia mínima de qualquer ataque (SC-605).
@export var min_telegraph: float = 0.6
## Invulnerável ao trocar de fase.
@export var phase_shift_invulnerable: float = 1.5
## Janela de exposição depois de Raio/Swipe errado (D-062 2A).
@export var exposed_time: float = 1.0
@export var exposed_word_bonus: float = 0.25
## Stun recebido: multiplicador (DOMINUS 3 s → 1 s; D-062 3A).
@export var stun_mul: float = 0.33
## Rasura: não apaga letra pega há menos disso.
@export var erasure_grace: float = 0.5
@export_group("Tempos (animation-agent, 006)")
## Entrada: invulnerável até o fim (a página escurece e os inimigos se dissolvem antes).
@export var enter_time: float = 2.5
@export var enter_rise_start: float = 0.4
@export var enter_rise_end: float = 2.1
## Troca de fase: animação até aqui, depois idle na nova cadência.
@export var phase_anim_end: float = 0.9
## Morte: dissolução; as letras douradas saem em `death_burst_at`; o capítulo acaba depois de
## `chapter_end_delay`.
@export var death_time: float = 1.5
@export var death_burst_at: float = 0.9
@export var chapter_end_delay: float = 2.5
## Letras douradas da morte (visual).
@export var death_letters: int = 12
@export var sprite_frames: SpriteFrames
