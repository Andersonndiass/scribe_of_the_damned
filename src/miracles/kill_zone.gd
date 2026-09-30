class_name KillZone
extends ZoneShape
## Zona letal de uma palavra de ataque (D-084; mechanics-agent): enquanto dura, todo inimigo comum
## dentro morre; o campeão leva um golpe forte uma vez por conjuração; o chefe nunca é tocado aqui.
## O milagre descreve a forma (e a move); o EnemyManager aplica 1× por tick de física.
## FSM: IDLE → ACTIVE → (DRAINING, só as de tela) → CLOSED; o milagre só termina em CLOSED.

## A geometria (forma, origem, direção, raio, pontos) vem de ZoneShape (017 T1710).
enum Phase { IDLE, ACTIVE, DRAINING, CLOSED }

var phase: Phase = Phase.IDLE
var life_left: float = 0.0
## Zonas de tela: ao acabar o tempo, continuam até não achar mais ninguém dentro.
var drain: bool = false
var cast_id: int = 0
var tag: StringName = &""
## Golpe no campeão: fixo (PURGO) ou fração da vida × multiplicador (power × GLORIA × Tinta).
var champion_flat: int = 0
var champion_frac: float = 0.0
var champion_mul: float = 1.0
## Campeões (uid) que já levaram o golpe desta zona.
var champions_hit := PackedInt32Array()
## REQUIEM: quantas mortes ainda soltam letra garantida.
var drops_left: int = 0
var kills: int = 0


func open(p_shape: Shape, p_life: float, p_drain: bool = false) -> void:
	shape = p_shape
	life_left = p_life
	drain = p_drain
	champions_hit.clear()
	kills = 0
	drops_left = 0
	phase = Phase.ACTIVE


func close() -> void:
	phase = Phase.CLOSED


func is_live() -> bool:
	return phase == Phase.ACTIVE or phase == Phase.DRAINING


## Avança o tempo; `found_common` = a última passada achou algum comum dentro (drenagem).
func tick(dt: float, found_common: bool) -> void:
	if phase == Phase.ACTIVE:
		life_left -= dt
		if life_left <= 0.0:
			phase = Phase.DRAINING if drain else Phase.CLOSED
	elif phase == Phase.DRAINING and not found_common:
		phase = Phase.CLOSED


## Dano do golpe no campeão de vida máxima `max_hp` (nunca menos que 1).
func champion_damage(max_hp: int) -> int:
	if champion_flat > 0:
		return champion_flat
	return maxi(1, ceili(champion_frac * max_hp * champion_mul))
