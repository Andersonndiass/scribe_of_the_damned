extends Miracle
## MISERERE — absolvição (002 FR-212): `damage` na tela toda em lotes, apaga as poças de heresia
## e perdoa a próxima heresia (sem stun e sem perder as letras). Usa: damage,
## kill_batch_per_frame, forgive_heresy. (Letras corrompidas: Cap. 5, feature 015.)
## Visual (design-agent): varredura de 0.6 s com anel CHALK 3 px e anel interno GOLD 1 px.
## O selo do perdão guardado fica no atril (HudAtril).

const SCREEN_REACH := 740.0

var _cursor: int = -1
var _t: float = 0.0


func _on_start() -> void:
	_t = 0.0
	var em := EnemyQuery.provider as EnemyManager
	_cursor = em.count - 1 if em != null else -1
	if em != null:
		em.hit_boss_sweep(dmg(word.damage))
	EventBus.heresy_absolved.emit()
	if word.forgive_heresy:
		var player := get_tree().get_first_node_in_group(&"player") as Player
		if player != null:
			player.buffs.grant_forgiveness()
			EventBus.heresy_forgiveness_granted.emit()
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
		# Limiar 0: ninguém morre "de graça"; todos levam o dano.
		_cursor = em.mortis_step(_cursor, word.kill_batch_per_frame, 0, dmg(word.damage))
	queue_redraw()
	if _t >= word.duration and _cursor < 0:
		finish()


func _draw() -> void:
	var r: float = SCREEN_REACH * clampf(_t / word.duration, 0.0, 1.0)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Palette.CHALK, 3.0, false)
	if r > 3.0:
		draw_arc(Vector2.ZERO, r - 3.0, 0.0, TAU, 48, Palette.GOLD, 1.0, false)
