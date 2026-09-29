extends Miracle
## DOMINUS — tela toda em lotes (002 FR-212): atordoa por `stun` s e fere todos.
## Usa: stun, damage, kill_batch_per_frame. power só no dano (D-056).
## Visual (design-agent): anel de 0.6 s como o da MORTIS (INK 4 px) com arco duplo GOLD 2 px por
## fora. Os atordoados ganham a coroa de 3 pontos GOLD (EnemyManager.draw_telegraphs).

const SWEEP_TIME := 0.6
const SCREEN_REACH := 740.0

var _cursor: int = -1
var _t: float = 0.0


func _on_start() -> void:
	_t = 0.0
	var em := EnemyQuery.provider as EnemyManager
	_cursor = em.count - 1 if em != null else -1
	if em != null:
		em.hit_boss_sweep(dmg(word.damage))
		em.stun_boss(word.stun)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_t += delta
	var em := EnemyQuery.provider as EnemyManager
	if em != null and _cursor >= 0:
		_cursor = em.stun_damage_step(_cursor, word.kill_batch_per_frame, word.stun, dmg(word.damage))
	queue_redraw()
	if _t >= SWEEP_TIME and _cursor < 0:
		finish()


func _draw() -> void:
	var r: float = SCREEN_REACH * clampf(_t / SWEEP_TIME, 0.0, 1.0)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Palette.INK, 4.0, false)
	draw_arc(Vector2.ZERO, r + 4.0, 0.0, TAU, 48, Palette.GOLD, 2.0, false)
	draw_arc(Vector2.ZERO, r + 8.0, 0.0, TAU, 48, Palette.GOLD, 2.0, false)
