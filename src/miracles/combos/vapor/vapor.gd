extends Miracle
## VAPOR (AQUA + IGNIS) — nuvem fixa que fere em ticks; com o escriba dentro, quem está fora
## da nuvem o perde de vista (002 FR-203). Usa: radius, damage, tick_interval, duration.
## Visual (design-agent): dither 25% INK_SOFT + borda CHALK tracejada; abaixo das letras.

## Quanto tempo o escriba continua oculto depois de sair da nuvem.
const HIDE_LINGER := 0.1
const DASH := 2

var _left: float = 0.0
var _tick: float = 0.0
var _player: Player


func _on_start() -> void:
	_left = word.duration
	_tick = 0.0
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if word.kill_zone:
		# D-084: comum na nuvem morre (o escriba continua escondido nela).
		var z := open_zone(KillZone.Shape.CIRCLE, word.duration)
		z.origin = origin
		z.radius = word.radius
	queue_redraw()


func _physics_process(delta: float) -> void:
	_left -= delta
	_tick -= delta
	var em := EnemyQuery.provider as EnemyManager
	if em != null:
		if _tick <= 0.0:
			_tick += word.tick_interval
			em.damage_in_radius(origin, word.radius, dmg(word.damage))
		var inside: bool = em.player != null and em.player_body().distance_to(origin) <= word.radius
		if inside:
			em.hide_player(origin, word.radius, HIDE_LINGER)
		if _player != null:
			_player.set_hidden_look(inside)
	if _left <= 0.0:
		if _player != null:
			_player.set_hidden_look(false)
		finish()


func _draw() -> void:
	if word == null:
		return
	var r: float = word.radius
	var ri: int = ceili(r)
	for y: int in range(-ri, ri + 1, 2):
		for x: int in range(-ri, ri + 1, 2):
			if Vector2(x, y).length() <= r:
				draw_rect(Rect2(x, y, 1, 1), Palette.INK_SOFT)
	var segs: int = maxi(8, int(TAU * r / (DASH * 2)))
	for k: int in segs:
		var a0: float = TAU * float(k) / segs
		var a1: float = a0 + TAU / segs / 2.0
		draw_line(Vector2.RIGHT.rotated(a0) * r, Vector2.RIGHT.rotated(a1) * r, Palette.CHALK, 1.0)
