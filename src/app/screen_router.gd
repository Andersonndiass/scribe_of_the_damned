class_name ScreenRouter
extends Node
## Raiz do jogo (007 FR-712, T703): troca as telas (Splash, Menu, Personagem, Capítulo, Jogo…) e
## hospeda a partida (`main.tscn`), marcada com a meta "app" — é assim que o Main sabe que é o
## jogo de verdade (loja com tela, R reinicia). Os atalhos de debug do web e da linha de comando
## (`?stress`, `?roster`) trocam a cena direto; `?boss`, `?shop`, `?unlock=all`, `?atril=N` pulam os
## menus e vão para a partida.

const SCREENS: Dictionary = {
	&"game": "res://src/main/main.tscn",
}
const DEBUG_SCENES: Dictionary = {
	"stress": "res://src/debug/stress_scene.tscn",
	"roster": "res://src/debug/roster_scene.tscn",
}
## Argumentos que pulam os menus direto para a partida.
const SKIP_TO_GAME: PackedStringArray = ["boss", "shop", "unlock=all", "atril="]
## Tela de entrada normal (vira o Splash na Fase 2 da 007).
const FIRST_SCREEN := &"game"

var current: Node = null
var current_name: StringName = &""


func _ready() -> void:
	EventBus.game_restart_requested.connect(func() -> void: goto(&"game"))
	var args: String = debug_args()
	for key: String in DEBUG_SCENES:
		if args.contains(key):
			get_tree().change_scene_to_file.call_deferred(DEBUG_SCENES[key])
			return
	for key: String in SKIP_TO_GAME:
		if args.contains(key):
			goto(&"game")
			return
	goto(FIRST_SCREEN)


## Troca para a tela `screen` (a anterior sai da árvore).
func goto(screen: StringName) -> void:
	if current != null:
		remove_child(current)
		current.queue_free()
	get_tree().paused = false
	var scene: PackedScene = load(SCREENS[screen])
	current = scene.instantiate()
	if screen == &"game":
		current.set_meta(&"app", true)
	current_name = screen
	add_child(current)
	EventBus.screen_changed.emit(screen)


## Argumentos de debug: linha de comando (depois de --) e, no web, a query da URL.
static func debug_args() -> String:
	var asked: String = " ".join(OS.get_cmdline_user_args())
	if OS.has_feature("web"):
		var search: Variant = JavaScriptBridge.eval("window.location.search", true)
		if search is String:
			asked += " " + (search as String)
	return asked
