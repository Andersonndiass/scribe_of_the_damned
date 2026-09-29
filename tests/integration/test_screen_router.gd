extends GutTest
## T703 ScreenRouter (007 FR-712): a raiz hospeda a partida marcada como jogo de verdade; o
## reinício pedido pela partida recria o jogo; a loja do jogo de verdade não fecha sozinha.

const APP := preload("res://src/app/app.tscn")

var _app: ScreenRouter


func before_each() -> void:
	_app = APP.instantiate()
	add_child_autofree(_app)


func after_each() -> void:
	get_tree().paused = false


func test_opens_the_game_marked_as_real() -> void:
	assert_eq(_app.current_name, &"game")
	assert_true(_app.current.has_meta(&"app"))
	assert_true(_app.current.call(&"is_real_game"))
	assert_false(_app.current.get(&"shop_auto_close"), "no jogo de verdade a loja tem tela")


func test_restart_request_recreates_the_game() -> void:
	var first: Node = _app.current
	EventBus.game_restart_requested.emit()
	await wait_physics_frames(2)
	assert_ne(_app.current, first, "partida nova")
	assert_false(is_instance_valid(first) and first.is_inside_tree(), "a antiga saiu")
