extends Miracle
## SPIRITUS — por `duration` s o escriba é intangível a corpos, 1.5× mais rápido e fere quem toca
## (002 FR-212, D-046). Projéteis e heresia continuam doendo (Player.take_hit).
## Usa: duration, speed_mul, damage, hit_cooldown, radius (alcance do toque).
## Visual (design-agent): escriba em xadrez CHALK (Flash.set_dither_tint); rastro de 3 fantasmas
## em dither CHALK, um a cada 50 ms, cada um por 150 ms; no último 1 s o xadrez pisca a 200 ms.

const GHOST_EVERY := 0.05
const GHOST_LIFE := 0.15
const GHOSTS := 3
const GHOST_SIZE := Vector2i(10, 20)
const BLINK_WINDOW := 1.0
const BLINK := 0.2

var _player: Player
var _ghost_timer: float = 0.0
var _ghost_pos := PackedVector2Array()
var _ghost_age := PackedFloat32Array()
var _next_ghost: int = 0


func _on_start() -> void:
	_ghost_timer = 0.0
	_ghost_pos.resize(GHOSTS)
	_ghost_age.resize(GHOSTS)
	_ghost_age.fill(GHOST_LIFE)
	global_position = Vector2.ZERO
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player != null:
		_player.buffs.apply_spiritus(word.duration, word.speed_mul)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _player == null or not _player.buffs.is_intangible():
		if _player != null:
			_player.set_spirit_look(false)
		finish()
		return
	var left: float = _player.buffs.spiritus_left
	_player.set_spirit_look(left > BLINK_WINDOW or int(left / BLINK) % 2 == 0)
	var em := EnemyQuery.provider as EnemyManager
	if em != null:
		em.damage_touch(em.player_body(), word.radius, dmg(word.damage), word.hit_cooldown)
	# Fantasmas só com o escriba em movimento (parado, empilhariam em cima dele; animation-agent).
	if _player.velocity.is_zero_approx():
		_ghost_timer = 0.0
		for k: int in GHOSTS:
			_ghost_age[k] += delta
		queue_redraw()
		return
	_ghost_timer -= delta
	for k: int in GHOSTS:
		_ghost_age[k] += delta
	if _ghost_timer <= 0.0:
		_ghost_timer += GHOST_EVERY
		_ghost_pos[_next_ghost] = _player.global_position.round()
		_ghost_age[_next_ghost] = 0.0
		_next_ghost = (_next_ghost + 1) % GHOSTS
	queue_redraw()


func _draw() -> void:
	for k: int in GHOSTS:
		if _ghost_age[k] >= GHOST_LIFE:
			continue
		var top_left: Vector2 = _ghost_pos[k] - Vector2(GHOST_SIZE.x / 2, GHOST_SIZE.y)
		for y: int in GHOST_SIZE.y:
			for x: int in range(y % 2, GHOST_SIZE.x, 2):
				if (x + y) % 4 == 0:
					draw_rect(Rect2(top_left + Vector2(x, y), Vector2.ONE), Palette.CHALK)
