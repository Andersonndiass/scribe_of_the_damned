extends GutTest
## T022 Movimento em 8 direções a 90 px/s, colidindo com a margem da página (FR-001, FR-006).

const ARENA_SCENE := preload("res://src/arena/arena.tscn")
const PLAYER_SCENE := preload("res://src/player/player.tscn")

var _player: Player


func before_each() -> void:
	var arena: Node2D = ARENA_SCENE.instantiate()
	add_child_autofree(arena)
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector2(320, 180)
	add_child_autofree(_player)
	_player.auto_attack.enabled = false


func after_each() -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		Input.action_release(action)


func test_moves_right_at_speed() -> void:
	Input.action_press(&"move_right")
	await wait_physics_frames(30)
	var dt: float = 1.0 / Engine.physics_ticks_per_second
	var expected: float = 90.0 * dt * 30.0
	assert_almost_eq(_player.position.x - 320.0, expected, 90.0 * dt * 2.0)
	assert_almost_eq(_player.position.y, 180.0, 0.01)


func test_diagonal_is_not_faster() -> void:
	Input.action_press(&"move_right")
	Input.action_press(&"move_down")
	await wait_physics_frames(30)
	var dist: float = _player.position.distance_to(Vector2(320, 180))
	var dt: float = 1.0 / Engine.physics_ticks_per_second
	assert_lt(dist, 90.0 * dt * 32.0, "diagonal normalizada")


func test_stops_at_page_margin() -> void:
	_player.position = Vector2(40, 180)
	Input.action_press(&"move_left")
	await wait_physics_frames(60)
	assert_gt(_player.position.x, Arena.MARGIN, "não atravessa a margem de 24px")


func test_enters_run_and_back_to_idle() -> void:
	Input.action_press(&"move_up")
	await wait_physics_frames(3)
	assert_eq(_player.machine.current.name, &"Run")
	Input.action_release(&"move_up")
	await wait_physics_frames(3)
	assert_eq(_player.machine.current.name, &"Idle")
