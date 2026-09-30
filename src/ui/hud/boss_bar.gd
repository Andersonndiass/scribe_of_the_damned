class_name HudBossBar
extends Node2D
## Barra de vida do chefe (006 FR-613; design-agent; art bible §8.2): 400×10 em X120–519 Y44–53,
## fora da área central. Moldura INK, fundo PARCHMENT_OLD, vida INK esvaziando da direita; o dano
## recente aparece em CHALK atrás e desce depois. Marcas das fases (66%/33%) viram BLOOD por 1 s
## quando a fase é cruzada. Nome em PixelFont centrado em Y35.

## T1800: no topo, onde fica o tempo (que some na luta); termina em y35, acima do menu da letra.
const BAR := Rect2(120, 18, 400, 10)
const NAME_Y := 8.0
const MARK_TOP := 16.0
const MARK_H := 14.0
const TRAIL_DELAY := 0.4
const TRAIL_SPEED := 0.5
const MARK_ALERT := 1.0

var boss: BossData
var fraction: float = 1.0
var trail: float = 1.0

var _trail_wait: float = 0.0
var _alert_phase: int = -1
var _alert_left: float = 0.0


func _ready() -> void:
	visible = false
	EventBus.boss_spawned.connect(func(b: BossData) -> void:
		boss = b
		fraction = 1.0
		trail = 1.0
		visible = true
		queue_redraw())
	EventBus.boss_damaged.connect(func(hp: int, max_hp: int) -> void:
		fraction = float(hp) / float(maxi(1, max_hp))
		_trail_wait = TRAIL_DELAY
		queue_redraw())
	EventBus.boss_phase_changed.connect(func(i: int) -> void:
		_alert_phase = i
		_alert_left = MARK_ALERT)
	EventBus.boss_defeated.connect(func(_b: BossData) -> void: visible = false)


func hud_rect() -> Rect2:
	return Rect2(119, 6, 402, 30)


func _process(delta: float) -> void:
	if not visible:
		return
	_alert_left = maxf(0.0, _alert_left - delta)
	if _trail_wait > 0.0:
		_trail_wait -= delta
	elif trail > fraction:
		trail = maxf(fraction, trail - TRAIL_SPEED * delta)
	queue_redraw()


func _draw() -> void:
	if boss == null:
		return
	PixelFont.draw_centered(self, tr(boss.display_name), BAR.get_center().x, NAME_Y, Palette.INK)
	draw_rect(BAR.grow(1), Palette.INK)
	draw_rect(BAR, Palette.PARCHMENT_OLD)
	draw_rect(Rect2(BAR.position, Vector2(roundf(BAR.size.x * trail), BAR.size.y)), Palette.CHALK)
	draw_rect(Rect2(BAR.position, Vector2(roundf(BAR.size.x * fraction), BAR.size.y)), Palette.INK)
	for i: int in range(1, boss.phases.size()):
		var x: float = roundf(BAR.position.x + BAR.size.x * boss.phases[i].threshold)
		var color: Color = Palette.BLOOD if (_alert_left > 0.0 and _alert_phase == i) else Palette.INK
		# Marca de 2 px (INK + CHALK) para não sumir sobre a vida; cabeça 4×4 INK com miolo CHALK embaixo (em cima encostava no nome).
		var core: Color = Palette.BLOOD if color == Palette.BLOOD else Palette.CHALK
		draw_rect(Rect2(x, MARK_TOP, 1, MARK_H), color)
		draw_rect(Rect2(x + 1, MARK_TOP, 1, MARK_H), Palette.CHALK)
		draw_rect(Rect2(x - 1, MARK_TOP + MARK_H, 4, 4), Palette.INK)
		draw_rect(Rect2(x, MARK_TOP + MARK_H + 1, 2, 2), core)
