extends Miracle
## ANGELUS — 3 penas de luz orbitam o escriba (002 FR-212) e ferem quem tocam; o toque é
## conferido todo tick, com cada inimigo ferido no máximo 1× por hit_cooldown (animation-agent).
## Usa: orbit_count (penas), radius (órbita), width (alcance da pena), damage, hit_cooldown, duration, rotation_speed.
## Visual (design-agent): losango 5×2 com haste CHALK, ponta GOLD 1 px e contorno INK por fora;
## 120° entre si; ao ferir, a pena pisca GOLD_LIGHT por 60 ms.

const BODY := Vector2(0, -10)
const HIT_FLASH := 0.06

var _left: float = 0.0
var _angle: float = 0.0
var _flash := PackedFloat32Array()
var _player: Node2D


func _on_start() -> void:
	_left = word.duration
	_flash.resize(word.orbit_count)
	_flash.fill(0.0)
	_angle = direction.angle()
	_player = get_tree().get_first_node_in_group(&"player") as Node2D
	_follow()
	queue_redraw()


func _physics_process(delta: float) -> void:
	_left -= delta
	_angle += TAU * word.rotation_speed * delta
	_follow()
	for k: int in word.orbit_count:
		_flash[k] -= delta
	var em := EnemyQuery.provider as EnemyManager
	if em != null:
		for k: int in word.orbit_count:
			if em.damage_touch(feather_position(k), word.width, dmg(word.damage), word.hit_cooldown) > 0:
				_flash[k] = HIT_FLASH
	queue_redraw()
	if _left <= 0.0:
		finish()


## Centro da pena `k` no mundo.
func feather_position(k: int) -> Vector2:
	return global_position + BODY + Vector2.RIGHT.rotated(_angle + TAU * k / word.orbit_count) * word.radius


func _follow() -> void:
	if _player != null:
		global_position = _player.global_position.round()


func _draw() -> void:
	if word == null:
		return
	for k: int in word.orbit_count:
		var dir: Vector2 = Vector2.RIGHT.rotated(_angle + TAU * k / word.orbit_count)
		var c: Vector2 = (BODY + dir * word.radius).round()
		var along: Vector2 = dir.orthogonal()  # a pena aponta no sentido da órbita
		var shaft: Color = Palette.GOLD_LIGHT if _flash[k] > 0.0 else Palette.CHALK
		draw_line((c - along * 2.0).round(), (c + along * 2.0).round(), shaft, 1.0, false)
		draw_line((c - along * 2.0 + dir).round(), (c + along * 1.0 + dir).round(), shaft, 1.0, false)
		draw_rect(Rect2((c + along * 3.0).round(), Vector2.ONE), Palette.GOLD)
		draw_line((c - along * 2.0 + dir * 2.0).round(), (c + along * 2.0 + dir * 2.0).round(), Palette.INK, 1.0, false)
