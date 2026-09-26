class_name LexiconData
extends Resource
## Dicionário de palavras conjuráveis (data-model §3). Validado pelo Lexicon no load (FR-014).

@export var alphabet: PackedStringArray = PackedStringArray()
## Letra -> id da palavra que a libera (ex.: {"B": &"verbum"}).
@export var gated_letters: Dictionary[String, StringName] = {}
@export var words: Array[WordData] = []
@export var min_length: int = 3
@export var max_length: int = 8
