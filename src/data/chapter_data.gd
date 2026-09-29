class_name ChapterData
extends Resource
## Um capítulo: a sequência de ondas (005 FR-513). O chefe entra na feature 006.

@export var chapter: int = 1
@export var waves: Array[WaveData] = []
## Chefe depois da loja da última onda (006). Vazio = o capítulo acaba na loja.
@export var boss: BossData
@export_group("Cutscenes (008)")
## Antes da partida, em ordem (ex.: c1_01, c1_02).
@export var intro_cutscenes: Array[StringName] = []
## No lugar da entrada do chefe.
@export var boss_cutscene: StringName = &""
## Depois da morte do chefe, antes da Vitória.
@export var outro_cutscene: StringName = &""
