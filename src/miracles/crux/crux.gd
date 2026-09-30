extends Miracle
## CRUX — cruz fixa no chão: dano periódico em + e bloqueio de projéteis inimigos (FR-021).
## Usa: damage, tick_interval, length (braço), width (largura do braço), block_radius, duration,
## blocks_projectiles. (T512b: nada mais de constante de gameplay no código.)
## Visual placeholder: madeira PARCHMENT_OLD com contorno INK e fio GOLD; pisca no último 0.5s.

const BLINK_WINDOW := 0.5

var _left: float = 0.0
var _tick: float = 0.0


func _on_start() -> void:
	_left = word.duration
	_tick = 0.0
	if word.blocks_projectiles:
		ProjectileBlockers.register(self)
	queue_redraw()


func _process(delta: float) -> void:
	_left -= delta
	_tick -= delta
	if _tick <= 0.0:
		_tick += word.tick_interval
		var em := EnemyQuery.provider as EnemyManager
		if em != null:
			em.damage_cross(origin, word.length, word.width, dmg(word.damage))
	if _left <= BLINK_WINDOW:
		visible = int(_left / 0.1) % 2 == 0
	if _left <= 0.0:
		ProjectileBlockers.unregister(self)
		visible = true
		finish()


func blocks_point(pos: Vector2) -> bool:
	var rel: Vector2 = pos - origin
	if rel.length() <= word.block_radius:
		return true
	var half: float = word.width / 2.0
	return (absf(rel.y) <= half and absf(rel.x) <= word.length) \
		or (absf(rel.x) <= half and absf(rel.y) <= word.length)


func _draw() -> void:
	if word == null:
		return
	var a: float = word.length
	var w: float = word.width
	var h: float = w / 2.0
	var arms: Array[Rect2] = [Rect2(-a, -h, a * 2.0, w), Rect2(-h, -a, w, a * 2.0)]
	for r: Rect2 in arms:
		draw_rect(r.grow(1.0), Palette.INK)
	for r: Rect2 in arms:
		draw_rect(r, Palette.PARCHMENT_OLD)
	draw_line(Vector2(-a, 0), Vector2(a, 0), Palette.GOLD, 1.0)
	draw_line(Vector2(0, -a), Vector2(0, a), Palette.GOLD, 1.0)


## Se a cena for destruída no meio da duração, não deixa bloqueador órfão.
func _exit_tree() -> void:
	super()
	ProjectileBlockers.unregister(self)
