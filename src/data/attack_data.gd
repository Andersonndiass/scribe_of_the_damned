class_name AttackData
extends Resource
## Um ataque de chefe (006 FR-601, spec FR-608). Todo número mora aqui.

@export var id: StringName = &""
## Executor: &"beam", &"swipe", &"summon", &"double_beam", &"rotating_cross", &"erasure".
@export var kind: StringName = &""
## Aviso antes do dano (SC-605: nunca abaixo do mínimo do BossData).
@export var telegraph: float = 0.9
## Tempo em que o golpe fere.
@export var active: float = 0.2
## Pausa depois do golpe, antes do próximo (sem contar o intervalo da fase).
@export var recover: float = 0.4
## 1 = fraco, 2 = forte (game bible §3.12); 0 = não fere vela (Summon, Rasura).
@export var damage: int = 2
@export var source_tag: StringName = &"boss"
@export_group("Forma")
@export var width: float = 12.0
@export var reach: float = 0.0
@export var arc_degrees: float = 0.0
@export var angle_offset_degrees: float = 0.0
@export var lines: int = 1
@export var arms: int = 0
@export var turn_degrees_per_s: float = 0.0
@export var duration: float = 0.0
@export var radius: float = 0.0
@export_group("Condições")
## Segundos até poder repetir este ataque.
@export var cooldown: float = 0.0
## Só sai com o escriba a esta distância ou menos (0 = sem condição).
@export var max_distance: float = 0.0
@export_group("Empurrão e poça (012)")
## Gust: distância (px) que o escriba é empurrado para longe do chefe, em `push_time` s.
@export var push: float = 0.0
@export var push_time: float = 0.2
## Dust: a poça deixada no ponto do golpe.
@export var hazard: PuddleData
@export_group("Eat_Page (012)")
## Bordas que podem ser comidas; a de mais folga sai primeiro (empate alterna esquerda/direita).
@export var bite_sides: Array[StringName] = [&"left", &"right", &"bottom"]
@export var bite_depth_side: float = 48.0
@export var bite_depth_bottom: float = 46.0
## A área nunca fica menor que isto (centrada, presa no topo).
@export var bite_min_size: Vector2 = Vector2(400, 220)
@export_group("Summon")
@export var summon_enemy: EnemyData
@export var summon_count: int = 0
@export var summon_max_alive: int = 0
