extends GutTest
## Emenda "controles com mouse" (D-067): clicar numa letra a marca; com marca, o ímã (mesmo raio)
## puxa só ela; sem marca, tudo como antes. Letras pisadas continuam sendo coletadas.

const MAIN_SCENE := preload("res://src/main/main.tscn")

var _main: Node2D
var _field: LetterField
var _player: Player


func before_each() -> void:
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	(_main.get_node("World/EnemyManager") as EnemyManager).dissolve_all()
	_field = _main.get_node("World/LetterField")
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_player.vitals.iframes_left = 1.0e6


func _body() -> Vector2:
	return _player.global_position + LetterField.PLAYER_BODY_OFFSET


## Três letras dentro do ímã, fora do alcance de coleta.
func _three_near() -> Array[Letter]:
	var out: Array[Letter] = []
	var b: Vector2 = _body()
	for i: int in 3:
		var pos: Vector2 = b + Vector2(18, 0).rotated(TAU * i / 3.0)
		out.append(_field.spawn_letter(["L", "A", "C"][i], false, false, pos))
	return out


func test_click_marks_the_nearest_letter_and_again_unmarks() -> void:
	var ls := _three_near()
	assert_eq(_field.mark_at(ls[1].global_position + Vector2(2, 1)), ls[1], "marca a letra clicada")
	assert_eq(_field.marked, ls[1])
	assert_true(ls[1].marked)
	assert_null(_field.mark_at(ls[1].global_position), "clicar de novo desmarca")
	assert_false(ls[1].marked)


func test_click_on_another_letter_moves_the_mark() -> void:
	var ls := _three_near()
	_field.mark_at(ls[0].global_position)
	_field.mark_at(ls[2].global_position)
	assert_eq(_field.marked, ls[2])
	assert_false(ls[0].marked)


func test_click_on_empty_ground_unmarks() -> void:
	var ls := _three_near()
	_field.mark_at(ls[0].global_position)
	assert_null(_field.mark_at(Vector2(600, 330)))
	assert_null(_field.marked)


func test_with_a_mark_the_magnet_brings_only_that_letter() -> void:
	var ls := _three_near()
	_field.mark_at(ls[1].global_position)  # o "A"
	await wait_physics_frames(60)
	assert_eq(_field.atril.text(), "A", "veio só o A")
	assert_null(_field.marked, "a marca some quando a letra é coletada")


func test_without_a_mark_the_magnet_works_as_before() -> void:
	_three_near()
	await wait_physics_frames(60)
	assert_eq(_field.atril.size(), 3, "sem marca, o ímã puxa as três")


func test_mark_does_not_widen_the_magnet() -> void:
	var far: Letter = _field.spawn_letter("A", false, false, _body() + Vector2(150, 0))
	_field.mark_at(far.global_position)
	await wait_physics_frames(60)
	assert_eq(_field.atril.size(), 0, "fora do raio do ímã, a marca não puxa")


func test_mark_clears_when_the_letter_leaves() -> void:
	var l: Letter = _field.spawn_letter("A", false, false, Vector2(500, 300))
	_field.mark_at(l.global_position)
	_field.eat_letter_near(l.global_position, 4.0)
	assert_null(_field.marked, "comida pela Traça: a marca some")
