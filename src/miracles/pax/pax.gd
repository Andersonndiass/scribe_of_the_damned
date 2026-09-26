extends Miracle
## PAX — onda circular que empurra e atordoa (FR-021). Usa: radius, knockback, stun.
## Visual placeholder: anel CHALK com borda GOLD abrindo em 0.3s.

const EXPAND_TIME := 0.3

var _t: float = 0.0


func _on_start() -> void:
	_t = 0.0
	var em := EnemyQuery.provider as EnemyManager
	if em != null:
		em.stun_in_radius(origin, word.radius * power, word.stun, word.knockback)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= EXPAND_TIME:
		finish()


func _draw() -> void:
	if word == null:
		return
	var r: float = word.radius * power * clampf(_t / EXPAND_TIME, 0.1, 1.0)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Palette.GOLD, 3.0, false)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Palette.CHALK, 1.0, false)
