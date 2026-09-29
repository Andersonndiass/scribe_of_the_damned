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
@export_group("Arena (004)")
## Página do capítulo: camadas e obstáculos.
@export var arena: ArenaData
## Estágio de degradação durante a luta do chefe (≥ o da última onda).
@export_range(0, 3) var boss_stage: int = 3


## Estágio visível durante a onda `slot` (dado da onda; FR-401).
func stage_for_wave(slot: int) -> int:
	if waves.is_empty():
		return 0
	return waves[clampi(slot, 0, waves.size() - 1)].degradation_stage


## Estágio depois da onda `slot`: o da próxima onda, ou o do chefe depois da última.
func stage_after(slot: int) -> int:
	return stage_for_wave(slot + 1) if slot + 1 < waves.size() else boss_stage


## "" se os estágios nunca voltam (SC-401); senão, o motivo.
func validate_stages() -> String:
	var last: int = 0
	for i: int in waves.size():
		if waves[i].degradation_stage < last:
			return "onda %d volta o estágio (%d < %d)" % [i + 1, waves[i].degradation_stage, last]
		last = waves[i].degradation_stage
	if boss_stage < last:
		return "o chefe volta o estágio"
	return ""
