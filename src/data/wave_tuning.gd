class_name WaveTuning
extends Resource
## Números do ritmo da onda que não são de uma onda só (004 FR-404).

## Segundos antes do fim da onda em que a página "ameaça" o próximo estágio (D-078, autor "2a").
@export var closing_warning: float = 10.0
## Tempo da revelação do estágio novo no fim da onda (provisório até o animation-agent, T420).
@export var reveal_time: float = 0.4
