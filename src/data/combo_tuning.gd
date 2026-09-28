class_name ComboTuning
extends Resource
## Janela de combo (002 data-model §4, D-044).

## Segundos para fechar o combo, contados a partir da 1ª letra coletada depois da conjuração.
@export var window: float = 2.5
## A janela fecha se nenhuma letra for coletada em max_open segundos.
@export var max_open: float = 8.0
## As dicas do atril destacam as palavras que fecham combo com a última conjurada.
@export var hint_highlight: bool = true
