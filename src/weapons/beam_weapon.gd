class_name BeamWeapon
extends Node2D
## Raio da Bíblia (017 T1714). Enquanto a Bíblia é a arma ativa, o raio fica ligado (D-087 item 5)
## e segue a mira (mouse ou direção do movimento, presa a 32 direções). O dano é uma WeaponZone
## LINE que o EnemyManager aplica; aqui só a forma e o desenho.
## Visual (design-agent): livro 10 px à frente, raio de 5 px (miolo CHALK de 3, borda INK de 1)
## desenhado com pincel de pixel inteiro por Bresenham, ponta de 2 quadros. Tempo
## (animation-agent): entra em 2×50 ms, pulsa largura 5/3 a cada 200 ms, sai em 2×50 ms.

const BOOK := preload("res://assets/placeholders/prj_bible_book.png")
const TIPS: Array[Texture2D] = [
	preload("res://assets/placeholders/vfx_bible_tip_0.png"),
	preload("res://assets/placeholders/vfx_bible_tip_1.png"),
]
## Livro à frente do escriba (px).
const BOOK_AHEAD := 10.0
const WIDTH := 5
const WIDTH_THIN := 3
const PULSE := 0.2
const STEP_TIME := 0.05
const STEPS_IN := 2
const STEPS_OUT := 2

var zone := WeaponZone.new()
var on: bool = false
## Onde o raio começa e termina (global), para o desenho.
var from: Vector2 = Vector2.ZERO
var to: Vector2 = Vector2.ZERO

var _t: float = 0.0
## 0..STEPS_IN (entrando) enquanto ligado; STEPS_OUT..0 (saindo) depois de desligar.
var _grow: float = 0.0


func _ready() -> void:
	top_level = true
	z_index = 2


## Liga (ou mantém) o raio de `p_from` na direção `dir` com os números do nível.
func hold(p_from: Vector2, dir: Vector2, s: WeaponLevelData, w: WeaponData, interval: float) -> void:
	if not on:
		on = true
		zone.open(ZoneShape.Shape.LINE)
		WeaponZones.register(zone)
		zone.weapon_id = w.id
		EventBus.weapon_beam_toggled.emit(w.id, true)
	var length: float = s.range
	var to_cursor: float = Aim.distance(p_from)
	if w.beam_min_length > 0.0 and to_cursor >= 0.0:
		length = clampf(to_cursor, w.beam_min_length, s.range)  # D-098: até a ponta do mouse
	zone.origin = p_from
	zone.dir = dir
	zone.length = length
	zone.width = s.width
	zone.damage = s.damage
	zone.slow_factor = s.slow_factor
	zone.slow_time = s.slow_time
	zone.interval = interval
	zone.max_targets = s.pierce
	zone.precision_mul = w.precision_mul
	zone.tag = w.boss_tag
	from = p_from
	to = p_from + dir * length


## Desliga na hora (troca de arma, morte): o dano acaba já; o desenho sai em 2 quadros.
func release() -> void:
	if not on:
		return
	on = false
	zone.close()
	WeaponZones.unregister(zone)
	EventBus.weapon_beam_toggled.emit(zone.weapon_id, false)


func _exit_tree() -> void:
	release()


func _process(delta: float) -> void:
	_t += delta
	var target: float = float(STEPS_IN) if on else 0.0
	_grow = move_toward(_grow, target, delta / STEP_TIME)
	visible = _grow > 0.0
	if visible:
		queue_redraw()


func _draw() -> void:
	var width: int = WIDTH if int(_t / PULSE) % 2 == 0 else WIDTH_THIN
	if _grow < float(STEPS_IN):
		width = WIDTH_THIN if _grow >= 1.0 else 1
	var dir: Vector2 = (to - from).normalized()
	var start: Vector2 = from + dir * BOOK_AHEAD
	var pts: PackedVector2Array = bresenham(Vector2i(start.round()), Vector2i(to.round()))
	var half_out: int = width / 2
	var half_in: int = maxi(half_out - 1, 0)
	if width > 1:
		for p: Vector2 in pts:
			draw_rect(Rect2(p - Vector2(half_out, half_out), Vector2(width, width)), Palette.INK)
	var core: int = maxi(width - 2, 1)
	for p: Vector2 in pts:
		draw_rect(Rect2(p - Vector2(half_in, half_in), Vector2(core, core)), Palette.CHALK)
	var tip: Texture2D = TIPS[int(_t / PULSE) % 2]
	draw_texture(tip, (to - tip.get_size() / 2.0).round())
	draw_texture(BOOK, (from + dir * BOOK_AHEAD - BOOK.get_size() / 2.0).round())


## Pixels inteiros de a até b (Bresenham), em ordem.
static func bresenham(a: Vector2i, b: Vector2i) -> PackedVector2Array:
	var out := PackedVector2Array()
	var dx: int = absi(b.x - a.x)
	var dy: int = -absi(b.y - a.y)
	var sx: int = 1 if a.x < b.x else -1
	var sy: int = 1 if a.y < b.y else -1
	var err: int = dx + dy
	var p: Vector2i = a
	while true:
		out.append(Vector2(p))
		if p == b:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			p.x += sx
		if e2 <= dx:
			err += dx
			p.y += sy
	return out
