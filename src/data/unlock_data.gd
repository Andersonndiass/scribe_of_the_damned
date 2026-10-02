class_name UnlockData
extends Resource
## Condição de desbloqueio de um escriba (010; D-101 6b; rules-agent T1000; mechanics-agent):
## &"chapter_won" (vencer o capítulo `chapter`), &"heresies_survived" (heresias sobrevividas,
## acumuladas), &"combos_discovered" (combos no Grimório), &"words_discovered" (palavras do grupo
## `word_group` no Grimório). `target` é o limite.

@export var kind: StringName = &"chapter_won"
@export var target: int = 1
@export var chapter: int = 1
@export var word_group: StringName = &"base"
## Heresia sobrevivida: janela (s) sem perder vela depois da heresia (T1000).
@export var window: float = 3.0
## Texto da dica no medalhão ("SOBREVIVA A {target} HERESIAS"), com o progresso n/alvo.
@export var hint_key: StringName = &""


func validate() -> String:
	if not [&"chapter_won", &"heresies_survived", &"combos_discovered", &"words_discovered"].has(kind):
		return "desbloqueio: tipo inválido"
	if target < 1:
		return "desbloqueio: alvo < 1"
	return ""
