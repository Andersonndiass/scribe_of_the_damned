class_name WaxDrop
extends Node2D
## Pingo de cera (016 FR-1615; ficha ITM_WAX_DROP 8×13, pivot base-centro): toco de vela apagada
## com fumaça. Só visual; a lógica fica no WaxDropField (laço único). Queda em 4 degraus, fumaça em
## ping-pong, pisca antes de sumir (como a letra), balança se as velas estão cheias, sobe ao ser pego.

const POOL_KEY := &"wax_drop"
const BASE := preload("res://assets/placeholders/itm_wax_drop_base.tres")
const SMOKE: Array[Texture2D] = [
	preload("res://assets/placeholders/itm_wax_drop_smoke_0.tres"),
	preload("res://assets/placeholders/itm_wax_drop_smoke_1.tres"),
]
const PIVOT := Vector2(4, 12)
## Queda: y −6, −2, squash, repouso (animation-agent).
const FALL_Y: Array[float] = [-6.0, -2.0, 0.0, 0.0]

var tuning: WaxDropTuning
var age: float = 0.0
var life: float = 0.0
## Tempo desde que começou a ser pego (−1 = no chão).
var collecting: float = -1.0
var shake_left: float = 0.0
## Já balançou nesta entrada (velas cheias): só de novo depois de sair de cima.
var rejected: bool = false


func start(pos: Vector2, p_tuning: WaxDropTuning) -> void:
	tuning = p_tuning
	global_position = pos
	age = 0.0
	life = tuning.lifetime
	collecting = -1.0
	shake_left = 0.0
	rejected = false
	modulate.a = 1.0
	queue_redraw()


func can_pick() -> bool:
	return collecting < 0.0 and age >= tuning.pickup_lock


func tick(dt: float) -> void:
	age += dt
	life -= dt
	shake_left = maxf(0.0, shake_left - dt)
	if collecting >= 0.0:
		collecting += dt
	modulate.a = _alpha()
	queue_redraw()


func _alpha() -> float:
	if collecting >= 0.0 or life > tuning.blink_time:
		return 1.0
	var step: float = tuning.blink_fast if life <= tuning.blink_fast_window else tuning.blink_slow
	return 1.0 if int(life / step) % 2 == 0 else tuning.blink_alpha


func _draw() -> void:
	if tuning == null:
		return
	var at := -PIVOT
	var size := Vector2(8, 13)
	var fall: int = int(age / tuning.spawn_step)
	if fall < FALL_Y.size():
		at.y += FALL_Y[fall]
		if fall == 2:
			size += Vector2(2, -2)
			at += Vector2(-1, 2)
	if shake_left > 0.0:
		at.x += 1.0 if int(shake_left / (tuning.reject_shake / 2.0)) % 2 == 0 else -1.0
	if collecting >= 0.0:
		at.y -= 2.0 if collecting < tuning.collect_time / 2.0 else 6.0
		if collecting >= tuning.collect_time / 2.0:
			draw_rect(Rect2(at + Vector2(1, 4), Vector2(6, 9)), Palette.CHALK)  # silhueta lisa
			return
	draw_texture_rect(BASE, Rect2(at, size), false)
	var smoke: int = int(age / tuning.idle_step) % 2
	draw_texture_rect(SMOKE[smoke], Rect2(at, size), false)
