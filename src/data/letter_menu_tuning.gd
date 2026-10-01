class_name LetterMenuTuning
extends Resource
## Menu de escolha da letra (017 FR-1708..FR-1710; rules-agent e animation-agent T1700; D-087).
## Tempos em segundos "de jogo a ×1": o relógio do menu desconta a câmera lenta e o hit-stop
## (na sonda, com a base ×4, tudo anda 4× mais rápido, como o resto do jogo).

## Quanto o menu fica aberto antes de a letra se perder.
@export var menu_time: float = 2.5
## Lentes do Copista somam aqui (`menu_time_add`); teto do acréscimo.
@export var time_add_cap: float = 1.0
## Feedback do autor (2026-10-01, D-098): o menu PAUSA o jogo (o tempo do menu corre em tempo
## real, com a barra embaixo das cartas). Falso = a câmera lenta antiga (D-090).
@export var pause_game: bool = true
## Câmera lenta com o menu aberto (teto ×0,3; só com `pause_game` falso).
@export var slow_factor: float = 0.2
## Entrada e saída da câmera lenta em degraus (animation-agent): fatores e duração de cada degrau.
@export var slow_in_steps: PackedFloat32Array = PackedFloat32Array([0.5, 0.2])
@export var slow_in_step_time: float = 0.05
@export var slow_out_steps: PackedFloat32Array = PackedFloat32Array([0.5, 1.0])
@export var slow_out_step_time: float = 0.1
## Menus esperando: 1 (D-087 item 10); o excedente se perde.
@export var queue_cap: int = 1
## Intervalo entre dois menus seguidos.
@export var reopen_gap: float = 0.25
## Escolha travada logo depois de abrir (a tecla já apertada não escolhe sem querer).
@export var pick_guard: float = 0.1
## Chance de rara nas 2 opções que não continuam a palavra (só vogais).
@export_range(0.0, 1.0) var other_rare_chance: float = 0.05
## Barra do tempo: pisca nos últimos `blink_window` s; mais rápido nos últimos `blink_fast_window`.
@export var blink_window: float = 0.7
@export var blink_fast_window: float = 0.2
