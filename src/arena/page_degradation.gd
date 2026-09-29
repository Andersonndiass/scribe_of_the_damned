class_name PageDegradation
extends RefCounted
## Estado da degradação da página (004 FR-401, FR-402, FR-404; mechanics-agent). Lógica pura, sem cena:
## o `Arena` só desenha `shown_stage` e `reveal`. FSM: STEADY → (fim da onda com estágio maior)
## THREATENED → (troca) TRANSITIONING → STEADY. O estágio nunca volta dentro do capítulo (SC-401).

## O estágio terminou de aparecer (sai também na entrada direta).
signal degraded(stage: int)

enum Phase { STEADY, THREATENED, TRANSITIONING }

var state: Phase = Phase.STEADY
## Estágio lógico (o da onda atual) e o da próxima onda (para a ameaça).
var stage: int = 0
var next_stage: int = 0
## Estágio já visível; durante a transição, o novo é revelado por cima com `reveal` 0 → 1.
var shown_stage: int = 0
var reveal: float = 1.0


## Aplica o estágio `to` (com o próximo `next`). `animated` = fim de onda (revela); senão, na hora.
func apply(to: int, next: int, animated: bool) -> void:
	next_stage = next
	if not animated:
		stage = to
		shown_stage = to
		reveal = 1.0
		state = Phase.STEADY
		degraded.emit(to)
		return
	if to == stage:
		if state == Phase.THREATENED:
			state = Phase.STEADY
		return
	if to < stage:
		push_error("PageDegradation: o estágio não volta dentro do capítulo (%d → %d)" % [stage, to])
		return
	stage = to
	reveal = 0.0
	state = Phase.TRANSITIONING


## Os últimos segundos da onda: ameaça se a página vai piorar.
func on_closing() -> void:
	if state == Phase.STEADY and next_stage > stage:
		state = Phase.THREATENED


## Avança a revelação; `reveal_time` vem do animation-agent.
func tick(dt: float, reveal_time: float) -> void:
	if state != Phase.TRANSITIONING:
		return
	reveal = minf(1.0, reveal + dt / maxf(reveal_time, 0.001))
	if reveal >= 1.0:
		_settle()


## Termina a transição na hora (a loja abriu e pausou a árvore).
func snap() -> void:
	if state == Phase.TRANSITIONING:
		reveal = 1.0
		_settle()


func threatened() -> bool:
	return state == Phase.THREATENED


func _settle() -> void:
	shown_stage = stage
	state = Phase.STEADY
	degraded.emit(stage)
