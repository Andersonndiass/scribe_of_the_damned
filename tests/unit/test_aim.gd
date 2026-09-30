extends GutTest
## 017 T1713: mira comum (D-067) — o cursor com a opção ligada; senão, a direção do escriba; a
## Bíblia prende em 32 direções.

var _was_mouse: bool
var _was_point: Vector2


func before_each() -> void:
	_was_mouse = GameState.aim_with_mouse
	_was_point = GameState.aim_point


func after_each() -> void:
	GameState.aim_with_mouse = _was_mouse
	GameState.aim_point = _was_point


func test_mouse_when_enabled_else_facing() -> void:
	GameState.aim_with_mouse = true
	GameState.aim_point = Vector2(100, 0)
	assert_eq(Aim.direction(Vector2.ZERO, Vector2.LEFT), Vector2.RIGHT)
	GameState.aim_with_mouse = false
	assert_eq(Aim.direction(Vector2.ZERO, Vector2.LEFT), Vector2.LEFT)
	GameState.aim_with_mouse = true
	GameState.aim_point = Vector2.INF
	assert_eq(Aim.direction(Vector2.ZERO, Vector2.UP), Vector2.UP, "sem mouse na sessão")


func test_snapped_to_32_directions() -> void:
	var d: Vector2 = Aim.snapped(Vector2.RIGHT.rotated(0.05), 32)
	assert_almost_eq(d.angle(), 0.0, 0.0001)
	d = Aim.snapped(Vector2.RIGHT.rotated(0.15), 32)
	assert_almost_eq(d.angle(), TAU / 32.0, 0.0001)
