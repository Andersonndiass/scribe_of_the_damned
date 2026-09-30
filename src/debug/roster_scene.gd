extends Node
## DEBUG (005 checkpoint A): vitrine dos 5 inimigos do Cap. 1 na cena principal real.
## Desktop: godot --path . res://src/debug/roster_scene.tscn · Web: index.html?roster

const MAIN_SCENE := preload("res://src/main/main.tscn")
const ROSTER: Array[String] = [
	"res://data/enemies/imp.tres", "res://data/enemies/moth.tres", "res://data/enemies/gargoyle.tres",
	"res://data/enemies/hollow_monk.tres", "res://data/enemies/ink_blot.tres",
]

var _main: Node2D


func _ready() -> void:
	_main = MAIN_SCENE.instantiate()
	_main.set_meta(&"stress", true)
	add_child(_main)
	(_main.get_node("WaveDirector") as WaveDirector).stop()
	var player: Player = _main.get_node("World/Player")
	player.global_position = Vector2(320, 190)
	player.arsenal.enabled = false
	player.vitals.iframes_left = 1.0e6
	var m: EnemyManager = _main.get_node("World/EnemyManager")
	m.dissolve_all()
	for k: int in ROSTER.size():
		var d: EnemyData = load(ROSTER[k])
		for n: int in 2:
			# 2ª fileira: campeões (a Traça não é campeã, D-040).
			var champ: bool = n == 1 and d.id != &"moth"
			m.spawn(d, Vector2(90 + k * 115, 70 + n * 210), champ)
