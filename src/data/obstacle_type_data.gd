class_name ObstacleTypeData
extends Resource
## Um tipo de obstáculo da página (004 FR-408, FR-410; catálogo §10). O que ele bloqueia é dado
## (rules-agent, 2026-09-29), não código.

## O que o obstáculo bloqueia (flags).
enum Block { WALK = 1, FLYER = 2, PLAYER_SHOT = 4, ENEMY_SHOT = 8, BOSS_ATTACK = 16 }

@export var id: StringName = &""
## Tamanho em pixels (furo 16×16, banco 32×8, vitral 20×40, altar 60×16).
@export var footprint: Vector2i = Vector2i(16, 16)
@export_flags("Andar", "Voador", "Tiro do escriba", "Tiro inimigo", "Ataque do chefe") var blocks: int = Block.WALK
## O dash da Gárgula para na borda.
@export var stops_dash: bool = true
## Arte do tipo (opcional; sem ela, o placeholder por script).
@export var texture: Texture2D
