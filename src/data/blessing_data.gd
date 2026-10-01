class_name BlessingData
extends StatUpgradeData
## Bênção do level-up (016 FR-1611): um dos 3 selos que o escriba escolhe ao subir de nível.

## Arte grande do selo (design-agent); sem ela, o selo usa o `icon`.
@export var seal_art: Texture2D
## Peso no sorteio dos selos.
@export var weight: float = 1.0
## 017 (T1729): o que o selo faz. &"stat" = bênção de status (RunStats); &"weapon_level" = +1 nível
## da arma do espaço `slot`; &"passive_level" = +1 nível do ímã reverso. Os de arma e ímã são
## montados na hora pelo SealPool (não há .tres).
@export var kind: StringName = &"stat"
var slot: int = -1
