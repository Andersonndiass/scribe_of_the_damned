extends Node
## DEBUG (T080): cena de stress = cena principal real + StressDriver + FpsProbe.
## Desktop: godot --path . res://src/debug/stress_scene.tscn [-- quit]
## Web: index.html?stress (SC-001) · ?stress=wave9 (SC-503) · ?stress=purgo|dominus|miserere e o
## controle ?stress=ctl (002 SC-202: frames acima de 33 ms depois da varredura).

const MAIN_SCENE := preload("res://src/main/main.tscn")
const StressDriver := preload("res://src/debug/stress_driver.gd")

var _main: Node2D
var _driver: Node
var _probe: FpsProbe


func _ready() -> void:
	_main = MAIN_SCENE.instantiate()
	_main.set_meta(&"stress", true)
	add_child(_main)
	_driver = StressDriver.new()
	add_child(_driver)
	var asked: String = _asked()
	var mode: StringName = &"sc001"
	if asked.contains("wave9"):
		mode = &"wave9"
	elif asked.contains("stress=ctl"):
		mode = &"sweep"  # controle: mesmo ciclo e janela, sem conjurar
	else:
		for w: String in ["purgo", "dominus", "miserere"]:
			if asked.contains("stress=" + w):
				mode = &"sweep"
				_driver.set(&"sweep_word", StringName(w))
	_driver.call(&"setup", _main, mode)
	_probe = FpsProbe.new()
	_probe.counts_provider = _counts
	add_child(_probe)
	if OS.get_cmdline_user_args().has("quit"):
		_probe.finished.connect(func(_r: Dictionary) -> void: get_tree().quit())


## Pedido do modo na linha de comando ou na URL (?stress=wave9).
func _asked() -> String:
	var asked: String = " ".join(OS.get_cmdline_user_args())
	if OS.has_feature("web"):
		var search: Variant = JavaScriptBridge.eval("window.location.search", true)
		if search is String:
			asked += " " + (search as String)
	return asked


func _counts() -> Dictionary:
	var em: EnemyManager = _main.get_node("World/EnemyManager")
	var field: LetterField = _main.get_node("World/LetterField")
	return {
		"inimigos": em.count,
		"letras": field.active_count(),
		"projeteis": _driver.call(&"active_projectiles"),
		"tiros_inimigos": _driver.call(&"enemy_projectiles"),
		"pocas": _driver.call(&"puddles"),
		"modo": _driver.get(&"mode"),
		"instantiate": PoolManager.instantiate_count,
	}
