class_name ArenaData
extends Resource
## A página de um capítulo (004): obstáculos e regras de espaço (rules-agent, 2026-09-29).

const PLAYABLE := Rect2(24, 24, 592, 312)

@export var chapter: int = 1
@export var obstacles: Array[ObstacleData] = []
## Folga entre dois obstáculos (ou obstáculo e parede): 0 (encostado) ou pelo menos isto.
@export var min_corridor: float = 40.0
## Letra ou tinta que cair dentro do obstáculo inflado nesta margem é empurrada para fora…
@export var drop_margin: float = 6.0
## …até ficar esta distância além da margem.
@export var drop_clearance: float = 2.0
## Nascimento de inimigo: fora do obstáculo inflado pelo raio do inimigo + isto.
@export var spawn_clearance: float = 2.0
## Pasta da arte do autor por camada (FR-407).
@export var layer_dir: String = "res://assets/arena/chapter_1/"


## Os obstáculos ativos no layout das ondas ou do chefe.
func active(boss_layout: bool, bounds: Rect2 = PLAYABLE) -> Array[ObstacleData]:
	var out: Array[ObstacleData] = []
	for o: ObstacleData in obstacles:
		if (o.in_boss if boss_layout else o.in_waves) and fits(o, bounds):
			out.append(o)
	return out


## 012 (Eat_Page): a peça fica se cabe inteira em `bounds` e a folga até cada borda é 0 ou
## ≥ `min_corridor` (sem fresta onde prender). Com a página inteira, toda peça válida fica.
func fits(o: ObstacleData, bounds: Rect2) -> bool:
	if bounds == PLAYABLE:
		return true
	var r := Rect2(o.rect())
	if not bounds.encloses(r):
		return false
	for g: float in [r.position.x - bounds.position.x, bounds.end.x - r.end.x, r.position.y - bounds.position.y, bounds.end.y - r.end.y]:
		if g > 0.01 and g < min_corridor:
			return false
	return true


## "" se o layout é válido: dentro da área jogável, sem sobreposição, folgas 0 ou ≥ min_corridor.
func validate() -> String:
	for i: int in obstacles.size():
		var a: Rect2 = obstacles[i].rect()
		if not PLAYABLE.encloses(a):
			return "obstáculo %d fora da área jogável" % i
		for side: float in _wall_gaps(a):
			if side > 0.0 and side < min_corridor:
				return "obstáculo %d com fresta de %d px na parede" % [i, side]
		for j: int in range(i + 1, obstacles.size()):
			var b: Rect2 = obstacles[j].rect()
			if a.intersects(b):
				return "obstáculos %d e %d se sobrepõem" % [i, j]
			var gap: float = _gap(a, b)
			if gap > 0.0 and gap < min_corridor:
				return "fresta de %d px entre %d e %d" % [gap, i, j]
	return ""


static func _wall_gaps(r: Rect2) -> Array[float]:
	return [r.position.x - PLAYABLE.position.x, PLAYABLE.end.x - r.end.x,
		r.position.y - PLAYABLE.position.y, PLAYABLE.end.y - r.end.y]


## Distância entre dois retângulos (0 se encostados).
static func _gap(a: Rect2, b: Rect2) -> float:
	var dx: float = maxf(0.0, maxf(b.position.x - a.end.x, a.position.x - b.end.x))
	var dy: float = maxf(0.0, maxf(b.position.y - a.end.y, a.position.y - b.end.y))
	return Vector2(dx, dy).length()
