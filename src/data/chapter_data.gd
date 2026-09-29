class_name ChapterData
extends Resource
## Um capítulo: a sequência de ondas (005 FR-513). O chefe entra na feature 006.

@export var chapter: int = 1
@export var waves: Array[WaveData] = []
## Chefe depois da loja da última onda (006). Vazio = o capítulo acaba na loja.
@export var boss: BossData
