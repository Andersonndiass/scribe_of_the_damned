class_name CutsceneTuning
extends Resource
## Números das cutscenes (008 FR-805, FR-810b). O texto e os tempos finos vêm do animation-agent
## (T810); segurar Esc 3 s é decisão do autor (D-071).

## Letras por segundo do texto que aparece letra a letra (provisório até o T810).
@export var chars_per_second: float = 40.0
## Segundos segurando Esc para pular a cena (D-071).
@export var skip_hold: float = 3.0
