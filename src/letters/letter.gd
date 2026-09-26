class_name Letter
extends Node2D
## Uma letra no chão (ficha 21). Só visual + estado; toda a lógica (vida, ímã, coleta) fica no
## LetterField, num único loop (Princípio V). Pooled em &"letter".

const POOL_KEY := &"letter"
const ATLAS := preload("res://assets/placeholders/ltr_atlas.tres")
const ATLAS_ORDER := "ACDEFGILMNOPQRSTUVXB"
const CELL := 10
## Letra-alvo: anel GOLD 12×12 pulsando a 700ms em ping-pong (ficha 21).
const TARGET_PULSE := 0.7
## Expirando: pisca alpha 1/0.3 a cada 100ms; nos últimos 0.5s, a cada 50ms (ficha 21).
const BLINK_SLOW := 0.1
const BLINK_FAST := 0.05
const BLINK_FAST_WINDOW := 0.5
const BLINK_ALPHA := 0.3

var letter: String = ""
var rare: bool = false
var target: bool = false
var life: float = 0.0
var lock_left: float = 0.0
var reject_cooldown: float = 0.0
var magnetized: bool = false
## Letra solta pelo purge: o ímã a ignora; só é recolhida andando por cima (D-031).
var loose: bool = false
var magnet_speed: float = 0.0
## > 0: uma Traça mira esta letra (marca BLOOD; 005 FR-504). Renovada pela Traça a cada passo.
var moth_mark: float = 0.0

var _sprite: Sprite2D
var _pulse: float = 0.0


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = ATLAS
	_sprite.region_enabled = true
	add_child(_sprite)


func start(p_letter: String, p_rare: bool, p_target: bool, pos: Vector2, lifetime: float, lock_time: float = 0.0, p_loose: bool = false) -> void:
	letter = p_letter
	rare = p_rare
	target = p_target
	global_position = pos
	life = lifetime
	lock_left = lock_time
	reject_cooldown = 0.0
	magnetized = false
	magnet_speed = 0.0
	loose = p_loose
	moth_mark = 0.0
	_pulse = 0.0
	var index: int = maxi(0, ATLAS_ORDER.find(letter))
	_sprite.region_rect = Rect2(index * CELL, (1 if rare else 0) * CELL, CELL, CELL)
	modulate.a = 1.0
	queue_redraw()


## Chamado pelo LetterField a cada frame.
func update_view(delta: float, blink_time: float) -> void:
	if life <= blink_time:
		var period: float = BLINK_FAST if life <= BLINK_FAST_WINDOW else BLINK_SLOW
		modulate.a = 1.0 if int(life / period) % 2 == 0 else BLINK_ALPHA
	else:
		modulate.a = 1.0
	if target:
		_pulse += delta
		queue_redraw()
	if moth_mark > 0.0:
		moth_mark -= delta
		queue_redraw()


func _draw() -> void:
	if moth_mark > 0.0:
		draw_rect(Rect2(-1, -8, 3, 1), Palette.BLOOD)
		draw_rect(Rect2(0, -9, 1, 1), Palette.BLOOD)
	if not target:
		return
	var phase: int = int(_pulse / TARGET_PULSE) % 2
	draw_rect(Rect2(-6, -6, 12, 12), Palette.GOLD if phase == 0 else Palette.GOLD_LIGHT, false, 1.0)
