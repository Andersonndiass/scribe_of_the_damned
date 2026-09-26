extends Miracle
## LUX — raio reto na direção do movimento; dano em tudo na linha (FR-021).
## Usa: damage, radius (largura), length, duration. Visual placeholder: núcleo CHALK, borda GOLD
## (art bible §6.2), afinando em 3 passos até sumir.

const STEPS := 3

var _left: float = 0.0


func _on_start() -> void:
	rotation = direction.angle()
	_left = word.duration
	EnemyQuery.damage_line(origin, direction, word.length, word.radius, roundi(word.damage * power))
	queue_redraw()


func _process(delta: float) -> void:
	_left -= delta
	queue_redraw()
	if _left <= 0.0:
		finish()


func _draw() -> void:
	if word == null:
		return
	var k: float = clampf(_left / maxf(word.duration, 0.001), 0.0, 1.0)
	var step: int = ceili(k * STEPS)
	var width: float = word.radius * float(step) / STEPS
	if width <= 0.0:
		return
	draw_rect(Rect2(0, -width / 2.0, word.length, width), Palette.GOLD)
	var core: float = maxf(1.0, width - 4.0)
	draw_rect(Rect2(0, -core / 2.0, word.length, core), Palette.CHALK)
