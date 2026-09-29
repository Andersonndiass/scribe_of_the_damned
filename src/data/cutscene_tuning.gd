class_name CutsceneTuning
extends Resource
## Números das cutscenes (008 FR-805, FR-810b). Tempos do animation-agent (T810); segurar Esc 3 s é
## decisão do autor (D-071).

## Letras por segundo do texto que aparece letra a letra (1 letra a cada 2 quadros).
@export var chars_per_second: float = 30.0
## Segundos segurando Esc para pular a cena (D-071).
@export var skip_hold: float = 3.0
## O indicador de pular só aparece depois deste tempo segurando (toque rápido não mostra nada).
@export var skip_show_after: float = 0.1
## Ao soltar antes, o indicador escorre até 0 neste tempo (a lógica zera na hora).
@export var skip_drain: float = 0.2
## Espera entre a morte do chefe e a C1-04 (a explosão de letras termina antes de congelar).
@export var post_boss_delay: float = 0.4
