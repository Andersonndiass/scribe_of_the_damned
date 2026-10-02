extends SceneTree
## Diagnóstico (D-098): abre a partida como o jogo de verdade, força um menu de letra e um
## level-up e mede se os inimigos param. Uso: godot --headless --path . -s tools/pause_check.gd

var _main: Node
var _t: float = 0.0
var _stage: int = 0
var _pos_before := PackedVector2Array()


func _initialize() -> void:
	_main = load("res://src/main/main.tscn").instantiate()
	_main.set_meta(&"app", true)
	root.add_child(_main)


func _enemy_positions() -> PackedVector2Array:
	var m: Node = _main.get_node("World/EnemyManager")
	var p: PackedVector2Array = m.get("positions")
	return p.slice(0, int(m.get("count")))


func _process(delta: float) -> bool:
	_t += delta
	var gs: Node = root.get_node("GameState")
	match _stage:
		0:
			if _t > 6.0:
				var menu: Node = _main.get_node("World/LetterField").get("menu")
				print("menu.offer=", menu.call("offer"))
				_stage = 1
				_t = 0.0
		1:
			if _t > 0.3:
				_pos_before = _enemy_positions()
				print("menu aberto=", _main.get_node("World/LetterField").get("menu").call("is_open"),
					" paused=", paused, " vivos=", _pos_before.size())
				_stage = 2
				_t = 0.0
		2:
			if _t > 0.8:
				print("inimigos mexeram com o menu? ", _pos_before != _enemy_positions(), " paused=", paused)
				_main.get_node("World/LetterField").get("menu").call("cancel")
				var bus: Node = root.get_node("EventBus")
				bus.emit_signal("word_cast", load("res://data/words/salvator.tres"), 1.0, Vector2.ZERO, Vector2.RIGHT)
				_stage = 3
				_t = 0.0
		3:
			if _t > 0.5 and _t - delta <= 0.5:
				print("feixe: fase=", _main.get_node("GraceFlow").get("phase"), " paused=", paused, " time_scale=", Engine.time_scale)
			if _t > 2.5:
				_pos_before = _enemy_positions()
				print("level-up: fase=", _main.get_node("GraceFlow").get("phase"), " paused=", paused)
				_stage = 4
				_t = 0.0
		4:
			if _t > 0.8:
				print("inimigos mexeram nos selos? ", _pos_before != _enemy_positions(), " paused=", paused)
				return true
	return false
