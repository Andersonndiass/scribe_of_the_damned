extends Miracle
## SALVATOR — acende `heal_candles` velas e apaga os projéteis inimigos da tela, sem
## invulnerabilidade (002 FR-212, D-046). A GLORIA multiplica a cura, como na VITA.
## Visual (design-agent): anel CHALK 1 px abrindo até o fim da tela em 0.4 s; cada projétil
## apagado vira uma cruz CHALK de 3 px por 150 ms.

const RING_TIME := 0.4
const SCREEN_REACH := 740.0
const CROSS_TIME := 0.15

var _t: float = 0.0
var _crosses := PackedVector2Array()


func _on_start() -> void:
	_t = 0.0
	global_position = origin
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player != null:
		player.heal(roundi(word.heal_candles * damage_mul))
	_crosses = PackedVector2Array()
	var em := EnemyQuery.provider as EnemyManager
	var shots: EnemyProjectileManager = em.get_projectiles() if em != null else null
	if word.clear_projectiles and shots != null:
		_crosses = shots.snapshot_positions()
		shots.clear()
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= RING_TIME:
		finish()


func _draw() -> void:
	draw_arc(Vector2.ZERO, SCREEN_REACH * clampf(_t / RING_TIME, 0.0, 1.0), 0.0, TAU, 48, Palette.CHALK, 1.0, false)
	if _t < CROSS_TIME:
		for p: Vector2 in _crosses:
			var c: Vector2 = (p - global_position).round()
			draw_rect(Rect2(c + Vector2(-1, 0), Vector2(3, 1)), Palette.CHALK)
			draw_rect(Rect2(c + Vector2(0, -1), Vector2(1, 3)), Palette.CHALK)
