class_name Aim
extends RefCounted
## Mira comum (017 T1713; regra da D-067): o cursor, se a opção estiver ligada e houver mouse;
## senão, para onde o escriba olha. Usada pelo Caster (palavras direcionais), pela Bíblia e pelo
## Aspersório.


static func direction(origin: Vector2, facing: Vector2) -> Vector2:
	if GameState.aim_with_mouse and GameState.aim_point != Vector2.INF:
		var d: Vector2 = GameState.aim_point - origin
		if d.length() > 1.0:
			return d.normalized()
	return facing.normalized() if facing != Vector2.ZERO else Vector2.RIGHT


## Distância até o cursor (o raio da Bíblia chega onde o mouse está, D-098); -1 = sem mouse.
static func distance(origin: Vector2) -> float:
	if GameState.aim_with_mouse and GameState.aim_point != Vector2.INF:
		return origin.distance_to(GameState.aim_point)
	return -1.0


## A direção presa a `steps` direções (32 na Bíblia: o raio em pixel inteiro não "treme").
static func snapped(dir: Vector2, steps: int) -> Vector2:
	if steps <= 0:
		return dir
	var step: float = TAU / float(steps)
	return Vector2.RIGHT.rotated(roundf(dir.angle() / step) * step)
