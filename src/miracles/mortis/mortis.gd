extends Miracle
## MORTIS — onda na tela toda (FR-021): mata inimigos com HP ≤ limiar e fere os outros.
## Usa: kill_hp_threshold, damage. Aplica em lotes de 50 por frame (plan §7).
## Visual placeholder: anel INK grosso com fio CHALK varrendo a página em 0.6s.

const BATCH := 50
const SCREEN_REACH := 740.0

var _cursor: int = -1
var _t: float = 0.0


func _on_start() -> void:
	_t = 0.0
	var em := EnemyQuery.provider as EnemyManager
	_cursor = em.count - 1 if em != null else -1
	if em != null:
		em.hit_boss_sweep(dmg(word.damage))
	if word.kill_zone:
		# D-084: o anel que varre a tela mata o comum que ele alcança (inclusive quem nasce nele).
		var z := open_zone(KillZone.Shape.SCREEN, word.duration)
		z.origin = origin
		z.radius = 1.0
	queue_redraw()


func _physics_process(delta: float) -> void:
	_t += delta
	if zone.is_live():
		zone.radius = maxf(1.0, SCREEN_REACH * clampf(_t / word.duration, 0.0, 1.0))
	var em := EnemyQuery.provider as EnemyManager
	if em != null and _cursor >= 0:
		_cursor = em.mortis_step(_cursor, BATCH, word.kill_hp_threshold, dmg(word.damage))
	queue_redraw()
	if _t >= word.duration and _cursor < 0:
		finish()


func _draw() -> void:
	var r: float = SCREEN_REACH * clampf(_t / word.duration, 0.0, 1.0)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Palette.INK, 4.0, false)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Palette.CHALK, 1.0, false)
