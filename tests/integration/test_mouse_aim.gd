extends GutTest
## Emenda "controles com mouse" (D-067): as palavras direcionais miram no cursor (opção ligada por
## padrão); sem mouse (ou com a opção desligada), na direção do escriba. O ataque automático não
## muda (continua mirando o inimigo mais próximo).

const MAIN_SCENE := preload("res://src/main/main.tscn")

var _main: Node2D
var _field: LetterField
var _caster: Caster
var _player: Player
var _dirs: Array[Vector2] = []


func before_each() -> void:
	_dirs.clear()
	GameState.aim_with_mouse = true
	GameState.aim_point = Vector2.INF
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	(_main.get_node("World/EnemyManager") as EnemyManager).dissolve_all()
	_field = _main.get_node("World/LetterField")
	_caster = _main.get_node("Caster")
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_player.facing = Vector2.RIGHT
	EventBus.word_cast.connect(_on_cast)


func after_each() -> void:
	EventBus.word_cast.disconnect(_on_cast)
	GameState.aim_with_mouse = true
	GameState.aim_point = Vector2.INF


func _on_cast(_w: WordData, _p: float, _o: Vector2, d: Vector2) -> void:
	_dirs.append(d)


func _cast_lux() -> void:
	for ch: String in "LUX":
		_field.collect(ch, false)
	assert_true(_caster.cast())


func test_is_on_by_default() -> void:
	assert_true(GameState.aim_with_mouse)


func test_lux_aims_at_the_cursor() -> void:
	var origin: Vector2 = _player.global_position + Caster.PEN_OFFSET
	GameState.aim_point = origin + Vector2(0, -50)
	_cast_lux()
	assert_almost_eq(_dirs[0].angle(), Vector2.UP.angle(), 0.01, "para o cursor, não para a direita")


func test_without_mouse_uses_facing() -> void:
	_cast_lux()
	assert_almost_eq(_dirs[0].angle(), 0.0, 0.01, "sem mouse: direção do escriba")


func test_option_off_uses_facing_even_with_mouse() -> void:
	GameState.aim_with_mouse = false
	GameState.aim_point = _player.global_position + Vector2(0, -50)
	_cast_lux()
	assert_almost_eq(_dirs[0].angle(), 0.0, 0.01)
