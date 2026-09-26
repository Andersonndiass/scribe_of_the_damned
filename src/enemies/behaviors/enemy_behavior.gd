class_name EnemyBehavior
extends Resource
## Comportamento de inimigo STATELESS (005 FR-501). O estado de cada inimigo vive nos arrays do
## EnemyManager (state, state_timer, aim); um mesmo .tres serve a todos os inimigos do tipo.
##   desired_velocity(): chamado só no tick de steering do inimigo (escalonado, D-039), com dt já
##                       multiplicado. Devolve a velocidade desejada; separação e integração ficam
##                       no manager.
##   tick(): chamado TODO tick, só se `needs_tick` (timers de telegrafia, disparos, poças).

## Estados compartilhados pelos comportamentos (valores de EnemyManager.state[i]).
const STATE_IDLE := 0
const STATE_WINDUP := 1
const STATE_DASH := 2
const STATE_COOLDOWN := 3
const STATE_FLEE := 4
const STATE_EATING := 5

## true = o manager chama tick() todo frame para este comportamento.
@export var needs_tick: bool = false


func desired_velocity(m: EnemyManager, i: int, target: Vector2, _dt: float) -> Vector2:
	return ChaseBehavior.seek(m, i, target)


func tick(_m: EnemyManager, _i: int, _dt: float) -> void:
	pass


## Chamado na morte com recompensa (antes de o slot ser removido): devolver letras, deixar poça...
func on_death(_m: EnemyManager, _i: int) -> void:
	pass


## Desenha a telegrafia do inimigo (só é chamado enquanto state == STATE_WINDUP).
func draw_telegraph(_m: EnemyManager, _i: int, _canvas: CanvasItem) -> void:
	pass
