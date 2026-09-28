extends Miracle
## REQUIEM (MORTIS + PAX) — onda de MORTIS em que cada inimigo morto solta letra com certeza,
## até guaranteed_drop_cap (002 FR-203). Usa: kill_hp_threshold, damage, kill_batch_per_frame,
## guaranteed_drop_cap. Visual (design-agent): anel do MORTIS + anel interno GOLD em r−3.

const SWEEP_TIME := 0.6
const SCREEN_REACH := 740.0

var _cursor: int = -1
var _drops_left: int = 0
var _t: float = 0.0


func _on_start() -> void:
	_t = 0.0
	_drops_left = word.guaranteed_drop_cap
	var em := EnemyQuery.provider as EnemyManager
	_cursor = em.count - 1 if em != null else -1
	queue_redraw()


func _physics_process(delta: float) -> void:
	_t += delta
	var em := EnemyQuery.provider as EnemyManager
	if em != null and _cursor >= 0:
		var r: Vector2i = em.requiem_step(_cursor, word.kill_batch_per_frame, word.kill_hp_threshold,
			dmg(word.damage), _drops_left)
		_cursor = r.x
		_drops_left = r.y
	queue_redraw()
	if _t >= SWEEP_TIME and _cursor < 0:
		finish()


func _draw() -> void:
	var r: float = SCREEN_REACH * clampf(_t / SWEEP_TIME, 0.0, 1.0)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Palette.INK, 4.0, false)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Palette.CHALK, 1.0, false)
	if r > 3.0:
		draw_arc(Vector2.ZERO, r - 3.0, 0.0, TAU, 48, Palette.GOLD, 1.0, false)
