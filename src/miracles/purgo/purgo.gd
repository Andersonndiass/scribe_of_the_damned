extends Miracle
## PURGO — limpa a tela em lotes (002 FR-208, SC-202): mata os inimigos comuns e dá `damage`
## (literal, só a GLORIA multiplica) em campeões e chefes. Usa: damage, kill_batch_per_frame.
## Visual (design-agent): varredura de 0.6 s como a MORTIS, com as cores invertidas: anel CHALK
## de 4 px com borda INK de 1 px por fora, tracejado em 12 segmentos.

const SWEEP_TIME := 0.6
const SCREEN_REACH := 740.0
const SEGMENTS := 12

var _cursor: int = -1
var _t: float = 0.0


func _on_start() -> void:
	_t = 0.0
	var em := EnemyQuery.provider as EnemyManager
	_cursor = em.count - 1 if em != null else -1
	if em != null:
		begin_hit()
		em.hit_boss_sweep(maxi(1, roundi(word.damage * damage_mul)))  # 10 literais, como nos campeões
	queue_redraw()


func _physics_process(delta: float) -> void:
	_t += delta
	var em := EnemyQuery.provider as EnemyManager
	if em != null and _cursor >= 0:
		# "Dá 10 de dano" (FR-208): o power da palavra não entra; a GLORIA sim.
		var elite: int = maxi(1, roundi(word.damage * damage_mul))
		begin_hit()
		_cursor = em.purgo_step(_cursor, word.kill_batch_per_frame, elite)
	queue_redraw()
	if _t >= SWEEP_TIME and _cursor < 0:
		finish()


func _draw() -> void:
	var r: float = SCREEN_REACH * clampf(_t / SWEEP_TIME, 0.0, 1.0)
	var step: float = TAU / SEGMENTS
	for k: int in SEGMENTS:
		var a0: float = step * k
		var a1: float = a0 + step * 0.6
		draw_arc(Vector2.ZERO, r + 2.5, a0, a1, 8, Palette.INK, 1.0, false)
		draw_arc(Vector2.ZERO, r, a0, a1, 8, Palette.CHALK, 4.0, false)
